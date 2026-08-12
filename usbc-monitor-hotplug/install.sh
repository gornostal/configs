#!/usr/bin/env bash
# Install the USB-C monitor hotplug workaround. Re-runnable.
set -euo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ $EUID -ne 0 ]]; then
    echo "re-running with sudo..."
    exec sudo -E "$0" "$@"
fi

install -m 0755 "$SRC/usbc-monitor-hotplug"          /usr/local/bin/usbc-monitor-hotplug
install -m 0644 "$SRC/usbc-monitor-hotplug.service"  /etc/systemd/system/usbc-monitor-hotplug.service
install -m 0644 "$SRC/99-usbc-monitor-hotplug.rules" /etc/udev/rules.d/99-usbc-monitor-hotplug.rules

systemctl daemon-reload
udevadm control --reload-rules
udevadm trigger --subsystem-match=typec

echo
echo "installed:"
echo "  /usr/local/bin/usbc-monitor-hotplug"
echo "  /etc/systemd/system/usbc-monitor-hotplug.service"
echo "  /etc/udev/rules.d/99-usbc-monitor-hotplug.rules"
echo
echo "test by unplugging and replugging the monitor, then:"
echo "  journalctl -u usbc-monitor-hotplug -n 20"
