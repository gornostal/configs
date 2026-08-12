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

On this hardware the Type-C hotplug (HPD) interrupt does not reliably reach the
i915 driver when a DP-alt-mode monitor is plugged in. The DRM connector stays
cached as `disconnected` and the compositor never learns there is a display.

Detection at *boot* works fine — it is only hotplug that fails.

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

The firmware needs time to finish DP alt-mode entry. A single forced probe at
plug time is too early; the old "wait 30–60s" was a conservative guess. This
polls every 2s and exits as soon as a new external connector reports
`connected`, so it fires as early as the hardware allows.

Measured on this machine: **~16s** from plug to detection, so the old manual
wait was roughly 2–4x longer than necessary.

Only connectors that are currently *disconnected* get poked, so an
already-working display is never disturbed.

## Two things deliberately left out

The original workaround did three things. Two of them are no-ops on this setup
— confirmed by a live replug test, where the detect loop alone found the
monitor with the UCSI reload disabled:

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

As of 2026-08 there is no known permanent fix.

- Switching to the `xe` driver will **not** help: `drivers/gpu/drm/i915/display/`
  is compiled twice, once into `i915.ko` and once into `xe.ko` via compat
  headers, so the Type-C HPD code is identical in both. Don't bother with
  `xe.force_probe`.
- BIOS `QLCN29WW` is current; `fwupdmgr` reports no pending updates.
- The 2025 i915 HPD patch series on intel-gfx targets HPD-storm/polling
  behaviour on Simatic IPC boards, not Type-C.

Worth re-checking on future kernels — remove this workaround and see whether
hotplug just works.
