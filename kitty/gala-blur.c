// Frosted-glass background for kitty on Gala (elementary OS).
//
// kitty's background_blur speaks ext-background-effect / KDE blur, which Gala doesn't
// offer. Gala's own blur request lives on its private pantheon shell protocol
// (io_elementary_pantheon_panel_v1.add_blur), which kitty doesn't know. This library
// is LD_PRELOADed into kitty and sends that request for every kitty OS window.
//
// get_panel only tags the surface so add_blur can be sent; without set_anchor and
// friends Gala keeps treating it as a normal window.
//
// How: wl_proxy_marshal_flags is wrapped, so every request kitty (and Mesa's EGL)
// sends passes through here. Toplevel surfaces are spotted via
// xdg_wm_base.get_xdg_surface + xdg_surface.get_toplevel; after the first commit
// with a buffer (Gala creates the window then) the blur is added. Surfaces are
// keyed by object id because EGL commits through wrapper proxies that share the id.
//
// Build: setup.sh (gcc -shared -fPIC gala-blur.c -lwayland-client).

#define _GNU_SOURCE
#include <dlfcn.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <wayland-client.h>

// Insets of the blurred area from the surface edges, and its corner radius, in logical
// pixels. They must match the visible window drawn by shaders/rounded-corners.slang
// (SHADOW and RADIUS there are physical pixels; the screens here are scale 2).
#define INSET 20
#define CLIP_RADIUS 10
// add_blur is repeated for this many buffer commits, in case Gala's window actor
// didn't exist yet the first time. Later resizes are followed by Gala itself.
#define BLUR_COMMITS 3
#define MAX_SURFACES 32
#define MAX_ARGS 20 // WL_CLOSURE_MAX_ARGS, private to libwayland

// --- io_elementary_pantheon_shell_v1, only the requests used here ----------------
// Request order must match Gala's protocol/pantheon-desktop-shell-v1.xml.

static const struct wl_interface panel_interface;
static const struct wl_interface *get_panel_types[] = {&panel_interface, &wl_surface_interface};
static const struct wl_message shell_requests[] = {
    {"get_panel", "no", get_panel_types},
};
static const struct wl_interface shell_interface = {
    "io_elementary_pantheon_shell_v1", 1, 1, shell_requests, 0, NULL,
};
static const struct wl_interface *no_types[] = {NULL, NULL, NULL, NULL, NULL};
static const struct wl_message panel_requests[] = {
    {"destroy", "", no_types},
    {"set_anchor", "u", no_types},
    {"focus", "", no_types},
    {"set_size", "ii", no_types},
    {"set_hide_mode", "u", no_types},
    {"request_visible_in_multitasking_view", "", no_types},
    {"add_blur", "uuuuu", no_types},
};
static const struct wl_interface panel_interface = {
    "io_elementary_pantheon_panel_v1", 1, 7, panel_requests, 0, NULL,
};
#define SHELL_GET_PANEL 0
#define PANEL_ADD_BLUR 6

// Opcodes of the standard requests that are watched
#define XDG_WM_BASE_GET_XDG_SURFACE 2
#define XDG_SURFACE_GET_TOPLEVEL 1
#define WL_SURFACE_DESTROY 0
#define WL_SURFACE_ATTACH 1
#define WL_SURFACE_COMMIT 6

struct surface {
    uint32_t id;          // wl_surface id; 0 = free slot
    uint32_t xdg_id;      // its xdg_surface
    int toplevel;
    int has_buffer;       // a buffer was attached since the last commit
    int blur_commits;     // add_blur requests sent so far
    struct wl_proxy *surface;
    struct wl_proxy *panel;
};

static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
static struct surface surfaces[MAX_SURFACES];
static struct wl_proxy *shell;
static __thread int in_hook; // our own requests go straight through

// libwayland's struct wl_proxy starts with struct wl_object, whose first field is the
// interface. There is no public getter in libwayland 1.22.
static const struct wl_interface *
proxy_interface(struct wl_proxy *proxy) {
    return *(const struct wl_interface **)proxy;
}

static struct surface *
find(uint32_t id, int by_xdg) {
    for (int i = 0; i < MAX_SURFACES; i++)
        if (surfaces[i].id && (by_xdg ? surfaces[i].xdg_id : surfaces[i].id) == id)
            return &surfaces[i];
    return NULL;
}

static void
registry_global(void *data, struct wl_registry *registry, uint32_t name, const char *interface, uint32_t version) {
    if (strcmp(interface, shell_interface.name) == 0)
        shell = wl_registry_bind(registry, name, &shell_interface, 1);
}

static void
registry_global_remove(void *data, struct wl_registry *registry, uint32_t name) {}

static const struct wl_registry_listener registry_listener = {registry_global, registry_global_remove};

struct wl_display *
wl_display_connect(const char *name) {
    static struct wl_display *(*real)(const char *);
    if (!real)
        real = dlsym(RTLD_NEXT, "wl_display_connect");
    struct wl_display *display = real(name);
    if (!display || shell)
        return display;

    // Look the shell up on a private queue, so none of kitty's events are dispatched here.
    in_hook = 1;
    struct wl_event_queue *queue = wl_display_create_queue(display);
    struct wl_display *wrapper = wl_proxy_create_wrapper(display);
    wl_proxy_set_queue((struct wl_proxy *)wrapper, queue);
    struct wl_registry *registry = wl_display_get_registry(wrapper);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    wl_display_roundtrip_queue(display, queue);
    wl_registry_destroy(registry);
    wl_proxy_wrapper_destroy(wrapper);
    // The shell and panel objects have no events, so the queue is never dispatched again.
    in_hook = 0;
    return display;
}

static void
blur(struct surface *s) {
    in_hook = 1;
    if (!s->panel)
        s->panel = wl_proxy_marshal_flags(shell, SHELL_GET_PANEL, &panel_interface, 1, 0, NULL, s->surface);
    wl_proxy_marshal_flags(s->panel, PANEL_ADD_BLUR, NULL, 1, 0, INSET, INSET, INSET, INSET, CLIP_RADIUS);
    in_hook = 0;
}

// Called with the lock held, before (sent = 0) and after (sent = 1) the request goes out.
static void
watch(struct wl_proxy *proxy, const char *iface, uint32_t opcode, union wl_argument *args, struct wl_proxy *ret, int sent) {
    uint32_t id = wl_proxy_get_id(proxy);
    struct surface *s;

    if (!sent && strcmp(iface, "wl_surface") == 0) {
        if (!(s = find(id, 0)))
            return;
        if (opcode == WL_SURFACE_ATTACH)
            s->has_buffer = args[0].o != NULL;
        else if (opcode == WL_SURFACE_DESTROY) {
            // The panel object dies with the surface on Gala's side; just forget it.
            if (s->panel)
                wl_proxy_destroy(s->panel);
            memset(s, 0, sizeof *s);
        }
    } else if (sent && strcmp(iface, "wl_surface") == 0 && opcode == WL_SURFACE_COMMIT) {
        if ((s = find(id, 0)) && s->toplevel && s->has_buffer && s->blur_commits < BLUR_COMMITS) {
            s->has_buffer = 0;
            s->blur_commits++;
            blur(s);
        }
    } else if (sent && strcmp(iface, "xdg_wm_base") == 0 && opcode == XDG_WM_BASE_GET_XDG_SURFACE && ret) {
        struct wl_proxy *surface = (struct wl_proxy *)args[1].o;
        for (int i = 0; i < MAX_SURFACES; i++)
            if (!surfaces[i].id) {
                surfaces[i] = (struct surface){
                    .id = wl_proxy_get_id(surface), .xdg_id = wl_proxy_get_id(ret), .surface = surface};
                break;
            }
    } else if (sent && strcmp(iface, "xdg_surface") == 0 && opcode == XDG_SURFACE_GET_TOPLEVEL) {
        if ((s = find(id, 1)))
            s->toplevel = 1;
    }
}

struct wl_proxy *
wl_proxy_marshal_flags(struct wl_proxy *proxy, uint32_t opcode, const struct wl_interface *interface,
                       uint32_t version, uint32_t flags, ...) {
    // Unpack the varargs by the request signature, the way libwayland does, and forward
    // them to the array variant.
    union wl_argument args[MAX_ARGS];
    const struct wl_interface *iface = proxy_interface(proxy);
    const char *sig = iface->methods[opcode].signature;
    int n = 0;
    va_list ap;
    va_start(ap, flags);
    for (const char *c = sig; *c && n < MAX_ARGS; c++) {
        switch (*c) {
        case 'i': args[n++].i = va_arg(ap, int32_t); break;
        case 'u': args[n++].u = va_arg(ap, uint32_t); break;
        case 'f': args[n++].f = va_arg(ap, wl_fixed_t); break;
        case 's': args[n++].s = va_arg(ap, const char *); break;
        case 'o':
        case 'n': args[n++].o = va_arg(ap, struct wl_object *); break;
        case 'a': args[n++].a = va_arg(ap, struct wl_array *); break;
        case 'h': args[n++].h = va_arg(ap, int32_t); break;
        }
    }
    va_end(ap);

    if (in_hook || !shell)
        return wl_proxy_marshal_array_flags(proxy, opcode, interface, version, flags, args);

    pthread_mutex_lock(&lock);
    watch(proxy, iface->name, opcode, args, NULL, 0);
    pthread_mutex_unlock(&lock);
    // A destructor request frees proxy, so nothing is watched after one.
    int destroys = flags & WL_MARSHAL_FLAG_DESTROY;
    struct wl_proxy *ret = wl_proxy_marshal_array_flags(proxy, opcode, interface, version, flags, args);
    if (!destroys) {
        pthread_mutex_lock(&lock);
        watch(proxy, iface->name, opcode, args, ret, 1);
        pthread_mutex_unlock(&lock);
    }
    return ret;
}

// Keep the library out of everything kitty starts (shells, tmux, editors…).
__attribute__((constructor)) static void
init(void) {
    unsetenv("LD_PRELOAD");
}
