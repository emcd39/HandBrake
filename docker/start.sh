#!/bin/sh
set -e

export HOME=/config
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

exec /usr/local/bin/ghb
