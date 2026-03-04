#!/bin/bash
set -e

export DISPLAY=:0
export HOME=/home/handbrake
export LD_LIBRARY_PATH=/usr/lib/jellyfin/lib:$LD_LIBRARY_PATH
export PATH=/usr/lib/jellyfin/bin:$PATH

wait_for_x() {
    for i in {1..30}; do
        if xdpyinfo -display :0 >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

if ! wait_for_x; then
    echo "Error: X server not available"
    exit 1
fi

exec /opt/handbrake/gtk/src/ghb
