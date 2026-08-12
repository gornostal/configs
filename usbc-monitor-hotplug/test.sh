#!/usr/bin/env bash
# Verify the detect loop against a fake sysfs tree (no root needed).
SCRIPT="$(cd "$(dirname "$0")" && pwd)/usbc-monitor-hotplug"
SP=$(mktemp -d)

mktree() {
    rm -rf "$SP/drm"; mkdir -p "$SP/drm"
    mkdir -p "$SP/drm/card1-eDP-1" "$SP/drm/card1-DP-1" "$SP/drm/card1-DP-2" "$SP/drm/card1-HDMI-A-1"
    echo connected    > "$SP/drm/card1-eDP-1/status"      # built-in, must be ignored
    echo disconnected > "$SP/drm/card1-DP-1/status"       # the monitor
    echo connected    > "$SP/drm/card1-DP-2/status"       # already working, must not be poked
    echo disconnected > "$SP/drm/card1-HDMI-A-1/status"
}

run() { env USBC_HOTPLUG_DRM_DIR="$SP/drm" USBC_HOTPLUG_LOCKFILE="$SP/test.lock" "$@" bash "$SCRIPT"; }

echo "=== TEST 1: monitor appears 6s after plug (the real scenario) ==="
mktree
( sleep 6; echo connected > "$SP/drm/card1-DP-1/status" ) &
run USBC_HOTPLUG_TIMEOUT=30 USBC_HOTPLUG_INTERVAL=2
echo "exit=$?"
wait
echo "  DP-2 (already-connected) content is now: $(cat "$SP/drm/card1-DP-2/status")"

echo
echo "=== TEST 2: nothing ever appears (charger plugged in) ==="
mktree
run USBC_HOTPLUG_TIMEOUT=8 USBC_HOTPLUG_INTERVAL=2
echo "exit=$?"

echo
echo "=== TEST 3: single-instance lock ==="
mktree
( run USBC_HOTPLUG_TIMEOUT=10 USBC_HOTPLUG_INTERVAL=2 >/dev/null ) &
sleep 1
run USBC_HOTPLUG_TIMEOUT=10 USBC_HOTPLUG_INTERVAL=2
echo "exit=$?"
wait
