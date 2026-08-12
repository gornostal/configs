#!/usr/bin/env bash
# Remove everything install.sh put on the system.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    exec sudo -E "$0" "$@"
fi

rm -f /etc/udev/rules.d/99-usbc-monitor-hotplug.rules
rm -f /etc/systemd/system/usbc-monitor-hotplug.service
rm -f /usr/local/bin/usbc-monitor-hotplug
rm -f /run/usbc-monitor-hotplug.lock

systemctl daemon-reload
udevadm control --reload-rules

echo "removed."
