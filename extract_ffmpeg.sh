#!/bin/bash
#
# Extract jellyfin-ffmpeg7 for cross-compilation
# Creates pkg-config files for HandBrake build system
#

set -e

DEB_FILE="jellyfin-ffmpeg7_7.1.3-3-jammy_arm64.deb"
EXTRACT_DIR="deps/jellyfin-ffmpeg7"
PKG_CONFIG_DIR="${EXTRACT_DIR}/usr/lib/aarch64-linux-gnu/pkgconfig"

log_info() {
    echo "[INFO] $1"
}

# Check if deb file exists
if [ ! -f "$DEB_FILE" ]; then
    echo "Error: $DEB_FILE not found!"
    echo "Please download jellyfin-ffmpeg7_7.1.3-3-jammy_arm64.deb"
    exit 1
fi

log_info "Extracting $DEB_FILE..."

# Extract deb package
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"
dpkg-deb -x "$DEB_FILE" "$EXTRACT_DIR"

log_info "Extracted to $EXTRACT_DIR"

# Check extracted files
log_info "Checking extracted contents..."
ls -la "${EXTRACT_DIR}/usr/lib/aarch64-linux-gnu/"

# Create pkg-config files if needed
mkdir -p "$PKG_CONFIG_DIR"

# libavcodec.pc
cat > "${PKG_CONFIG_DIR}/libavcodec.pc" << 'EOF'
prefix=/usr/aarch64-linux-gnu
exec_prefix=${prefix}
libdir=${exec_prefix}/lib/aarch64-linux-gnu
includedir=${prefix}/include/aarch64-linux-gnu

Name: libavcodec
Description: FFmpeg codec library
Version: 60.31.102
Requires: libavutil >= 57.24.0
Requires.private: 
Conflicts:
Libs: -L${libdir} -lavcodec
Libs.private: -lm -lpthread -lz
Cflags: -I${includedir}
EOF

# libavformat.pc
cat > "${PKG_CONFIG_DIR}/libavformat.pc" << 'EOF'
prefix=/usr/aarch64-linux-gnu
exec_prefix=${prefix}
libdir=${exec_prefix}/lib/aarch64-linux-gnu
includedir=${prefix}/include/aarch64-linux-gnu

Name: libavformat
Description: FFmpeg container format library
Version: 60.16.100
Requires: libavcodec >= 57.24.0 libavutil >= 57.24.0
Requires.private: 
Conflicts:
Libs: -L${libdir} -lavformat
Libs.private: -lm -lpthread
Cflags: -I${includedir}
EOF

# libavutil.pc
cat > "${PKG_CONFIG_DIR}/libavutil.pc" << 'EOF'
prefix=/usr/aarch64-linux-gnu
exec_prefix=${prefix}
libdir=${exec_prefix}/lib/aarch64-linux-gnu
includedir=${prefix}/include/aarch64-linux-gnu

Name: libavutil
Description: FFmpeg utility library
Version: 57.24.100
Requires: 
Requires.private: 
Conflicts:
Libs: -L${libdir} -lavutil
Libs.private: -lm -lpthread
Cflags: -I${includedir}
EOF

# libswscale.pc
cat > "${PKG_CONFIG_DIR}/libswscale.pc" << 'EOF'
prefix=/usr/aarch64-linux-gnu
exec_prefix=${prefix}
libdir=${exec_prefix}/lib/aarch64-linux-gnu
includedir=${prefix}/include/aarch64-linux-gnu

Name: libswscale
Description: FFmpeg image scaling and conversion library
Version: 7.4.100
Requires: libavutil >= 57.24.0
Requires.private: 
Conflicts:
Libs: -L${libdir} -lswscale
Libs.private: -lm
Cflags: -I${includedir}
EOF

# libswresample.pc
cat > "${PKG_CONFIG_DIR}/libswresample.pc" << 'EOF'
prefix=/usr/aarch64-linux-gnu
exec_prefix=${prefix}
libdir=${exec_prefix}/lib/aarch64-linux-gnu
includedir=${prefix}/include/aarch64-linux-gnu

Name: libswresample
Description: FFmpeg audio resampling library
Version: 4.12.100
Requires: libavutil >= 57.24.0
Requires.private: 
Conflicts:
Libs: -L${libdir} -lswresample
Libs.private: -lm -lpthread
Cflags: -I${includedir}
EOF

# libavfilter.pc
cat > "${PKG_CONFIG_DIR}/libavfilter.pc" << 'EOF'
prefix=/usr/aarch64-linux-gnu
exec_prefix=${prefix}
libdir=${exec_prefix}/lib/aarch64-linux-gnu
includedir=${prefix}/include/aarch64-linux-gnu

Name: libavfilter
Description: FFmpeg media filtering library
Version: 9.24.100
Requires: libavcodec >= 57.24.0 libavformat >= 57.24.0 libavutil >= 57.24.0 libswscale >= 7.4.0
Requires.private: 
Conflicts:
Libs: -L${libdir} -lavfilter
Libs.private: -lm -lpthread
Cflags: -I${includedir}
EOF

log_info "Created pkg-config files in $PKG_CONFIG_DIR"
log_info ""
log_info "Extraction complete!"
log_info ""
log_info "To build HandBrake with this FFmpeg:"
log_info "1. Install cross-compilation toolchain:"
log_info "   sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu pkg-config-aarch64-linux-gnu"
log_info ""
log_info "2. Set up environment:"
log_info "   export PKG_CONFIG_PATH=\$(pwd)/${PKG_CONFIG_DIR}:\${PKG_CONFIG_PATH}"
log_info "   export CROSS_PREFIX=aarch64-linux-gnu-"
log_info ""
log_info "3. Configure HandBrake:"
log_info "   ./configure --cross=aarch64-linux-gnu --build=x86_64-linux-gnu --enable-gtk"
log_info ""
log_info "4. Build:"
log_info "   make -j\$(nproc)"
