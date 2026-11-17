#!/bin/sh

set -e

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

echo "Installing early boot AFTERG3_EN syshook..."
install -d -m 0755 /usr/local/etc/rc.syshook.d/early
install -m 0755 "${REPO_DIR}/usr/local/etc/rc.syshook.d/early/10-afterg3" /usr/local/etc/rc.syshook.d/early/10-afterg3

echo "Installing devd AC power-loss guard..."
install -d -m 0755 /usr/local/etc/devd
install -d -m 0755 /usr/local/sbin
install -m 0644 "${REPO_DIR}/usr/local/etc/devd/ac-power-guard.conf" /usr/local/etc/devd/ac-power-guard.conf
install -m 0755 "${REPO_DIR}/usr/local/sbin/ac-power-guard.sh" /usr/local/sbin/ac-power-guard.sh

echo "Applying GEN_PMCON_3 register and reloading devd..."
/usr/local/etc/rc.syshook.d/early/10-afterg3
service devd restart

echo "Done. Check 'System -> Log Files -> General' for afterg3 and ac-power-guard entries."