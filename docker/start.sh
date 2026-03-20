#!/bin/sh
set -e

export HOME=/config
export LD_LIBRARY_PATH=/opt/handbrake/lib:${LD_LIBRARY_PATH}

exec /usr/local/bin/ghb
