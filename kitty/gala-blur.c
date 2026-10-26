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
// Animations: Gala's blur effect reallocates its full-size offscreen textures on every
// frame in which the window's on-screen size changes, and the minimize and restore
// animations scale the window on every frame, which makes them drop frames. So the blur
// is removed when kitty asks to be minimized (kitty-toggle's minimize.py), and added
// back once the restore animation is over: RESUME_DELAY_MS after the first configure
// that activates the window again. Its listener is wrapped to see that configure.
// Minimizing from the Dock or a shortcut is invisible to kitty and still animates blurred.
//
// Build: setup.sh (gcc -shared -fPIC gala-blur.c -lwayland-client). Only kitty started
// by kitty-toggle or the desktop entry's "New Separate Window" loads it, and only at
// startup, so quit the main instance after rebuilding.
//
// Debug: start kitty with WAYLAND_DEBUG=1 and this library preloaded, grep for add_blur.
// Gala logs "Window tried to set blur region…" warnings if it rejects one.

#define _GNU_SOURCE
#include <dlfcn.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>
#include <wayland-client.h>

// Insets of the blurred area from the surface edges, and its corner radius, in logical
// pixels. They must match the visible window drawn by shaders/rounded-corners.slang
// (SHADOW and RADIUS there are physical pixels; the screens here are scale 2).
#define INSET 20
#define CLIP_RADIUS 10
// add_blur is repeated for this many buffer commits, in case Gala's window actor
// didn't exist yet the first time. Later resizes are followed by Gala itself.
#define BLUR_COMMITS 3
// Gala's restore animation lasts 200 ms (AnimationDuration.HIDE), plus a margin
#define RESUME_DELAY_MS 250
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
    {"remove_blur", "", no_types},
};
static const struct wl_interface panel_interface = {
    "io_elementary_pantheon_panel_v1", 1, 8, panel_requests, 0, NULL,
};
#define SHELL_GET_PANEL 0
#define PANEL_ADD_BLUR 6
#define PANEL_REMOVE_BLUR 7

// Opcodes of the standard requests that are watched
#define XDG_WM_BASE_GET_XDG_SURFACE 2
#define XDG_SURFACE_GET_TOPLEVEL 1
#define XDG_TOPLEVEL_SET_MINIMIZED 13
#define XDG_TOPLEVEL_STATE_ACTIVATED 4
#define WL_SURFACE_DESTROY 0
#define WL_SURFACE_ATTACH 1
#define WL_SURFACE_COMMIT 6

// xdg_toplevel's events, in protocol order
struct toplevel_listener {
    void (*configure)(void *data, void *toplevel, int32_t width, int32_t height, struct wl_array *states);
    void (*close)(void *data, void *toplevel);
    void (*configure_bounds)(void *data, void *toplevel, int32_t width, int32_t height);
    void (*wm_capabilities)(void *data, void *toplevel, struct wl_array *capabilities);
};

struct surface {
    uint32_t id;          // wl_surface id; 0 = free slot
    uint32_t xdg_id;      // its xdg_surface
    uint32_t toplevel_id; // its xdg_toplevel; 0 = not a toplevel (yet)
    int has_buffer;       // a buffer was attached since the last commit
    int blur_commits;     // add_blur requests sent so far
    int paused;           // blur removed for a minimize, not restored yet
    unsigned resume_gen;  // bumped to cancel a pending resume
    struct wl_proxy *surface;
    struct wl_proxy *panel;
    const struct toplevel_listener *listener; // kitty's, which events are forwarded to
    void *listener_data;
};

static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
static struct surface surfaces[MAX_SURFACES];
static struct wl_proxy *shell;
static struct wl_display *display;
static __thread int in_hook; // our own requests go straight through

// libwayland's struct wl_proxy starts with struct wl_object, whose first field is the
// interface. There is no public getter in libwayland 1.22.
static const struct wl_interface *
proxy_interface(struct wl_proxy *proxy) {
    return *(const struct wl_interface **)proxy;
}

enum { BY_SURFACE, BY_XDG, BY_TOPLEVEL };

static struct surface *
find(uint32_t id, int by) {
    for (int i = 0; i < MAX_SURFACES; i++) {
        struct surface *s = &surfaces[i];
        if (s->id && (by == BY_XDG ? s->xdg_id : by == BY_TOPLEVEL ? s->toplevel_id : s->id) == id)
            return s;
    }
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
    struct wl_display *connected = real(name);
    if (!connected || shell)
        return connected;
    display = connected;

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

// Gala doesn't disconnect its size_changed handler here, so each add_blur after a
// remove_blur adds one more (cheap) handler; they go away when kitty quits.
static void
unblur(struct surface *s) {
    in_hook = 1;
    wl_proxy_marshal_flags(s->panel, PANEL_REMOVE_BLUR, NULL, 1, 0);
    in_hook = 0;
}

struct resume {
    struct surface *s;
    unsigned gen;
};

// Thread that adds the blur back after the restore animation, unless the window was
// minimized again (or destroyed) meanwhile. Requests are thread-safe in libwayland;
// the flush is needed because kitty may sit idle in poll() with nothing to send.
static void *
resume_later(void *arg) {
    struct resume r = *(struct resume *)arg;
    free(arg);
    nanosleep(&(struct timespec){0, RESUME_DELAY_MS * 1000000L}, NULL);
    pthread_mutex_lock(&lock);
    int resumed = r.s->id && r.s->paused && r.s->resume_gen == r.gen;
    if (resumed) {
        r.s->paused = 0;
        blur(r.s);
    }
    pthread_mutex_unlock(&lock);
    if (resumed)
        wl_display_flush(display);
    return NULL;
}

// Called with the lock held.
static void
schedule_resume(struct surface *s) {
    struct resume *r = malloc(sizeof *r);
    pthread_t thread;
    pthread_attr_t attr;
    if (r) {
        *r = (struct resume){s, ++s->resume_gen};
        pthread_attr_init(&attr);
        pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        int failed = pthread_create(&thread, &attr, resume_later, r);
        pthread_attr_destroy(&attr);
        if (!failed)
            return;
        free(r);
    }
    // No thread: blur right away, at the cost of a choppy animation.
    s->paused = 0;
    blur(s);
}

static void
toplevel_configure(void *data, void *toplevel, int32_t width, int32_t height, struct wl_array *states) {
    struct surface *s = data;
    pthread_mutex_lock(&lock);
    const struct toplevel_listener *listener = s->listener;
    void *listener_data = s->listener_data;
    if (s->paused) {
        uint32_t *state;
        wl_array_for_each(state, states) if (*state == XDG_TOPLEVEL_STATE_ACTIVATED) {
            schedule_resume(s);
            break;
        }
    }
    pthread_mutex_unlock(&lock);
    if (listener)
        listener->configure(listener_data, toplevel, width, height, states);
}

// The other events go straight through.
static void
toplevel_close(void *data, void *toplevel) {
    struct surface *s = data;
    if (s->listener)
        s->listener->close(s->listener_data, toplevel);
}

static void
toplevel_configure_bounds(void *data, void *toplevel, int32_t width, int32_t height) {
    struct surface *s = data;
    if (s->listener)
        s->listener->configure_bounds(s->listener_data, toplevel, width, height);
}

static void
toplevel_wm_capabilities(void *data, void *toplevel, struct wl_array *capabilities) {
    struct surface *s = data;
    if (s->listener)
        s->listener->wm_capabilities(s->listener_data, toplevel, capabilities);
}

static const struct toplevel_listener toplevel_wrapper = {
    toplevel_configure, toplevel_close, toplevel_configure_bounds, toplevel_wm_capabilities,
};

int
wl_proxy_add_listener(struct wl_proxy *proxy, void (**implementation)(void), void *data) {
    static int (*real)(struct wl_proxy *, void (**)(void), void *);
    if (!real)
        real = dlsym(RTLD_NEXT, "wl_proxy_add_listener");
    if (in_hook || !shell || strcmp(proxy_interface(proxy)->name, "xdg_toplevel") != 0)
        return real(proxy, implementation, data);

    pthread_mutex_lock(&lock);
    struct surface *s = find(wl_proxy_get_id(proxy), BY_TOPLEVEL);
    if (s) {
        s->listener = (const struct toplevel_listener *)implementation;
        s->listener_data = data;
    }
    pthread_mutex_unlock(&lock);
    return s ? real(proxy, (void (**)(void))&toplevel_wrapper, s) : real(proxy, implementation, data);
}

// Called with the lock held, before (sent = 0) and after (sent = 1) the request goes out.
static void
watch(struct wl_proxy *proxy, const char *iface, uint32_t opcode, union wl_argument *args, struct wl_proxy *ret, int sent) {
    uint32_t id = wl_proxy_get_id(proxy);
    struct surface *s;

    if (!sent && strcmp(iface, "wl_surface") == 0) {
        if (!(s = find(id, BY_SURFACE)))
            return;
        if (opcode == WL_SURFACE_ATTACH)
            s->has_buffer = args[0].o != NULL;
        else if (opcode == WL_SURFACE_DESTROY) {
            // The panel object dies with the surface on Gala's side; just forget it.
            if (s->panel)
                wl_proxy_destroy(s->panel);
            memset(s, 0, sizeof *s);
        }
    } else if (!sent && strcmp(iface, "xdg_toplevel") == 0 && opcode == XDG_TOPLEVEL_SET_MINIMIZED) {
        // Before the request, so the blur is gone when the animation starts
        if ((s = find(id, BY_TOPLEVEL)) && s->panel) {
            unblur(s);
            s->paused = 1;
            s->resume_gen++;
        }
    } else if (sent && strcmp(iface, "wl_surface") == 0 && opcode == WL_SURFACE_COMMIT) {
        if ((s = find(id, BY_SURFACE)) && s->toplevel_id && !s->paused && s->has_buffer &&
            s->blur_commits < BLUR_COMMITS) {
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
        if ((s = find(id, BY_XDG)) && ret)
            s->toplevel_id = wl_proxy_get_id(ret);
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
