#!/bin/sh
set -e

export HOME=/config
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
export LIBGL_ALWAYS_SOFTWARE=1
export GSK_RENDERER=cairo

# Keep behavior close to the known-good kasm run:
# ensure RK devices are writable by root/video users when available.
if getent group video >/dev/null 2>&1; then
    chgrp video /dev/mpp_service /dev/rga 2>/dev/null || true
    chgrp -R video /dev/dma_heap /dev/dri 2>/dev/null || true
fi
chmod 660 /dev/mpp_service /dev/rga 2>/dev/null || true
chmod -R 660 /dev/dma_heap /dev/dri 2>/dev/null || true

exec /usr/local/bin/ghb
