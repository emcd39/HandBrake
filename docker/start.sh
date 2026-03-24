#!/bin/sh
set -e

export HOME=/config
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
export LIBGL_ALWAYS_SOFTWARE=1
export GSK_RENDERER=cairo

# Keep behavior close to the known-good kasm run without damaging directory
# permissions under /dev. Only touch actual device nodes.
fix_device_node() {
    if [ -e "$1" ]; then
        if getent group video >/dev/null 2>&1; then
            chgrp video "$1" 2>/dev/null || true
        fi
        chmod 660 "$1" 2>/dev/null || true
    fi
}

fix_device_node /dev/mpp_service
fix_device_node /dev/rga

for dev in /dev/dma_heap/* /dev/dri/renderD* /dev/dri/card*; do
    if [ -e "$dev" ]; then
        fix_device_node "$dev"
    fi
done

exec /usr/local/bin/ghb
