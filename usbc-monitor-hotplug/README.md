# usbc-monitor-hotplug

Automatic workaround for external USB-C monitors not being detected on hotplug
under Linux on Intel Arrow Lake-P / Meteor Lake display IP.

Replaces the older manual workaround ("plug the monitor in, wait 30–60s, then
run a script with sudo") with a udev-triggered service that polls until the
display shows up.

## Install

```sh
./install.sh      # asks for sudo
```

Verify after an unplug/replug:

```sh
journalctl -u usbc-monitor-hotplug -n 20
```

Uninstall with `./uninstall.sh`.

## The problem

Hotplugging a DP-alt-mode monitor leaves the DRM connector permanently
`disconnected`, so the compositor never learns there is a display. Detection at
*boot* works fine — it is hotplug-only.

**The HPD interrupt is not the problem.** Confirmed with `drm.debug=0xe`: the
long HPD pulse arrives 3–4s after plug and the TC port enters `dp-alt` correctly.
What fails is AUX — every transfer times out (`status 0x7c7c023f`, DPCD `-110`)
and keeps timing out for **~50 seconds**.

Meanwhile `intel_ddi_hotplug()` allows type-C connectors only 5 retries at
`HPD_RETRY_DELAY` (1000ms):

```c
/* drivers/gpu/drm/i915/display/intel_ddi.c */
if (state == INTEL_HOTPLUG_UNCHANGED &&
    connector->hotplug_retries < (is_tc ? 5 : 1) &&
    !dig_port->dp.is_mst)
        state = INTEL_HOTPLUG_RETRY;
```

That budget is spent ~14s after plug. No retry gets re-armed, there is no polled
fallback, and **i915 never touches the port again** — verified as 170s of total
silence in the logs. The remaining ~36s of AUX-unavailable time is never
revisited, so the connector stays `disconnected` indefinitely.

Writing `detect` to the sysfs `status` file probes out-of-band, past the
exhausted budget, and succeeds once AUX comes up.

Confirmed environment where this was needed:

| | |
|---|---|
| Machine | Lenovo IdeaPad Pro 5 14IAH10 (`83JK`), BIOS `QLCN29WW` |
| GPU | Arrow Lake-P `8086:7d51`, driven by `i915` (reports as `meteorlake`, display v14.00) |
| OS | elementary OS 8.1 (Ubuntu 24.04 base), Wayland / Pantheon, mutter 46.2 |
| Kernel | still reproducing on `7.0.0-28-generic` |

Writing `detect` to a connector's sysfs `status` file forces a re-probe, which
picks up the now-correct live status and emits a DRM hotplug uevent that mutter
reacts to.

## Why it polls instead of waiting a fixed delay

AUX stays dead for ~50s, so a single forced probe at plug time is far too early.
The loop polls every 2s and exits as soon as a new external connector reports
`connected`, firing as early as the hardware allows.

Only connectors that are currently *disconnected* get poked, so an
already-working display is never disturbed.

### The workaround is load-bearing, not cosmetic

Verified by A/B, 3 runs each, 180s window, `drm.debug=0xe`, udev rule disabled
(`capture-evidence.sh`):

| Forced `echo detect` | Result |
|---|---|
| no | never connected within 180s (x3) |
| every 2s | connected at 56s, 51s, 49s |

Without an out-of-band probe the display **never** appears. The earlier "9–63s"
figures came from the service's own logs and are unreliable — those runs raced
against udev retriggers. The clean number is ~50s.

### AUX heals on wall-clock alone

`wallclock-test.sh` settles what the A/B could not. Plug in, touch nothing for
90s, then write `detect` exactly once:

```
10:10:14  plugged in
10:10:26  i915 gives up at retry 5
          ... 78 seconds of complete silence, zero port activity ...
10:11:44  single detect write -> EDID read succeeds on the FIRST AUX
          transaction -> status updated disconnected -> connected
```

So elapsed time brings AUX back, not repeated probing. The 2s polling here is
therefore wasteful but harmless — a single probe at ~60s would do. Upstream,
the same conclusion means i915 needs to retry **once, later**, not poll.

## Two things deliberately left out

The original workaround did three things. Two of them appear to be no-ops on
this setup — a live replug test found the monitor with the UCSI reload
disabled, i.e. the detect loop alone was enough:

- **`xrandr --auto`** — the session is Wayland. `xrandr` only talks to XWayland
  and cannot drive real outputs. Output reconfiguration comes from mutter
  reacting to the DRM hotplug uevent, which the `detect` write already emits.

- **Reloading `ucsi_acpi` / `typec_ucsi`** — both Type-C partners report
  `number_of_alternate_modes = 0` and `typec_displayport` is not loaded, i.e.
  the DP mux is handled in firmware (TCSS), not by the kernel typec stack. This
  reload is also the risky part: it drops the USB-C power-delivery driver, and
  the udev rule fires for plain chargers too.

  It is still available as a last-resort fallback. To enable it, uncomment the
  `Environment=USBC_HOTPLUG_UCSI_FALLBACK=1` line in the service file and
  re-run `install.sh`. It then triggers 45s in, only if nothing was detected.

## Tunables

Set as `Environment=` lines in `usbc-monitor-hotplug.service`:

| Variable | Default | Meaning |
|---|---|---|
| `USBC_HOTPLUG_TIMEOUT` | `90` | Give up after this many seconds |
| `USBC_HOTPLUG_INTERVAL` | `2` | Seconds between probe attempts |
| `USBC_HOTPLUG_SETTLE` | `2` | Delay before the first probe |
| `USBC_HOTPLUG_UCSI_FALLBACK` | `0` | Enable the UCSI reload fallback |
| `USBC_HOTPLUG_UCSI_FALLBACK_AFTER` | `45` | When the fallback kicks in |

`USBC_HOTPLUG_DRM_DIR` and `USBC_HOTPLUG_LOCKFILE` exist so `test.sh` can run
the logic against a fake sysfs tree without root. Don't set them in the unit.

## Tests

```sh
./test.sh     # no root needed, ~25s
```

Covers: monitor appearing mid-poll, charger-only plug (clean timeout),
single-instance locking, and that an already-connected output is never poked.

## Upstream status

As of 2026-09 there is no known permanent fix. No pre-existing report covered
this case: searched `drm/i915/kernel` on freedesktop GitLab (the `drm/intel`
tracker is archived) across hotplug / type-c / DP-alt-mode / `hotplug_retries` /
`echo detect` terms. Nearest open issues, all distinct:

| Issue | Why it is not this |
|---|---|
| [#16601](https://gitlab.freedesktop.org/drm/i915/kernel/-/issues/16601) | TGL, *cold* plug at driver load, `intel_tc_port_sanitize_mode` teardown |
| [#16256](https://gitlab.freedesktop.org/drm/i915/kernel/-/issues/16256) | RPL-P, KWin-only (`enabled` stuck), not reproducible under mutter |
| [#16818](https://gitlab.freedesktop.org/drm/i915/kernel/-/issues/16818) | TGL, HDMI *unplug* missed, status stuck `connected` |

Roughly 15 open Arrow Lake issues exist; none concern Type-C hotplug, and none
concern the exhausted `hotplug_retries` budget. [#15924](https://gitlab.freedesktop.org/drm/i915/kernel/-/issues/15924)
is ADL-N TC-legacy link training *after* a successful detect, so also unrelated.

**Filed upstream as
[i915#16955](https://gitlab.freedesktop.org/drm/i915/kernel/-/work_items/16955)**
(2026-09-02), with the `drm.debug=0xe` A/B evidence, the three-procedure
timeline and the `intel_ddi.c` code citation. Local copy of the submitted text
and attachments: `~/i915-hotplug-report/`.

Watch that issue before removing this workaround.

- Switching to the `xe` driver is still not expected to help: `intel_ddi.c`
  carries the retry budget and is compiled into both `i915.ko` and `xe.ko`.
  Not separately verified.

- BIOS `QLCN29WW` is current; `fwupdmgr` reports no pending updates.
- The 2025 i915 HPD patch series on intel-gfx targets HPD-storm/polling
  behaviour on Simatic IPC boards, not Type-C.

Worth re-checking on future kernels — remove this workaround and see whether
hotplug just works.
