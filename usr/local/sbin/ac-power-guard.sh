#!/bin/sh

DELAY=120
PIDFILE="/var/run/ac-power-guard.pid"
LOGGER="/usr/bin/logger -t ac-power-guard"

cancel_pending() {
    if [ -f "${PIDFILE}" ]; then
        OLD_PID=$(cat "${PIDFILE}")
        if kill -0 "${OLD_PID}" 2>/dev/null; then
            kill "${OLD_PID}" 2>/dev/null
            ${LOGGER} "Cancelled pending power-loss shutdown (PID ${OLD_PID})."
        fi
        rm -f "${PIDFILE}"
    fi
}

case "$1" in
    0x00)
        # AC disconnected: reset any existing timer and start a fresh countdown
        cancel_pending
        ${LOGGER} "AC power lost. Waiting ${DELAY}s before checking status for shutdown."
        (
            sleep "${DELAY}"
            AC_NOW=$(/sbin/sysctl -n hw.acpi.acline 2>/dev/null)
            if [ "${AC_NOW}" = "0" ]; then
                ${LOGGER} "AC power still absent after ${DELAY}s. Initiating clean shutdown."
                rm -f "${PIDFILE}"
                /sbin/shutdown -p now
            else
                ${LOGGER} "AC power restored during delay. Aborting shutdown."
                rm -f "${PIDFILE}"
            fi
        ) &
        echo $! > "${PIDFILE}"
        ;;
    0x01)
        # AC restored: cancel any pending countdown immediately
        ${LOGGER} "AC power restored."
        cancel_pending
        ;;
esac

exit 0
