#!/bin/bash
#
# HandBrake RK3588 (ARM64) Build Script - GTK Version
# Target: RK3588 Debian system with novnc
# FFmpeg: Uses bundled FFmpeg from contrib (required for GTK)
#

set -e

# Configuration
ARCH="aarch64"
CROSS_PREFIX="aarch64-linux-gnu-"
BUILD_DIR="build/rk3588-gtk"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
DEB_PACKAGE="jellyfin-ffmpeg7_7.1.3-3-jammy_arm64.deb"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on ARM64 or using cross-compilation
check_environment() {
    log_info "Checking build environment..."
    
    # Check for cross-compilation toolchain
    if ! command -v ${CROSS_PREFIX}gcc &> /dev/null; then
        log_error "Cross-compilation toolchain not found. Install with:"
        log_error "  sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu"
        exit 1
    fi
    
    # Check for required tools
    for tool in pkg-config; do
        if ! command -v ${CROSS_PREFIX}$tool &> /dev/null && ! command -v $tool &> /dev/null; then
            log_warn "$tool not found, will try to install"
        fi
    done
    
    log_info "Environment check passed"
}

# Extract jellyfin-ffmpeg7 deb package
# NOTE: This function is NOT used by default for GTK builds.
# GTK builds require bundled FFmpeg from contrib (see BUILD_RK3588.md).
# This function exists for CLI-only builds that may use jellyfin-ffmpeg7.
extract_ffmpeg() {
    log_info "Extracting jellyfin-ffmpeg7 package..."
    
    local ffmpeg_dir="${SOURCE_DIR}/deps/jellyfin-ffmpeg7"
    
    if [ -d "$ffmpeg_dir" ]; then
        log_info "FFmpeg already extracted"
        return
    fi
    
    mkdir -p "$ffmpeg_dir"
    
    # Extract deb package
    if [ -f "${SOURCE_DIR}/${DEB_PACKAGE}" ]; then
        dpkg-deb -x "${SOURCE_DIR}/${DEB_PACKAGE}" "$ffmpeg_dir"
        log_info "FFmpeg extracted to $ffmpeg_dir"
    else
        log_error "FFmpeg package not found: ${DEB_PACKAGE}"
        exit 1
    fi
}

# Configure HandBrake for RK3588 cross-compilation with GTK
configure_handbrake() {
    log_info "Configuring HandBrake for ARM64 with GTK..."
    
    mkdir -p "${SOURCE_DIR}/${BUILD_DIR}"
    cd "${SOURCE_DIR}/${BUILD_DIR}"
    
    # Configure command for cross-compilation with GTK
    # Uses bundled FFmpeg from contrib
    
    ${SOURCE_DIR}/configure \
        --cross=aarch64-linux-gnu \
        --build=x86_64-linux-gnu \
        --prefix=/usr/local \
        --enable-gtk \
        --disable-gtk-update-checks \
        --enable-x265 \
        --disable-fdk-aac \
        2>&1 | tee configure.log
    
    if [ $? -eq 0 ]; then
        log_info "Configuration successful"
    else
        log_error "Configuration failed. Check configure.log"
        exit 1
    fi
}

# Alternative: Configure with system FFmpeg (jellyfin-ffmpeg7)
configure_with_system_ffmpeg() {
    log_info "Configuring HandBrake with jellyfin-ffmpeg7..."
    
    local ffmpeg_dir="${SOURCE_DIR}/deps/jellyfin-ffmpeg7"
    local ffmpeg_lib="${ffmpeg_dir}/usr/lib/aarch64-linux-gnu"
    local ffmpeg_include="${ffmpeg_dir}/usr/include/aarch64-linux-gnu"
    
    # Check if jellyfin-ffmpeg7 is extracted
    if [ ! -d "$ffmpeg_dir" ]; then
        extract_ffmpeg
    fi
    
    mkdir -p "${SOURCE_DIR}/${BUILD_DIR}"
    cd "${SOURCE_DIR}/${BUILD_DIR}"
    
    # Set environment for pkg-config to find jellyfin-ffmpeg7
    export PKG_CONFIG_PATH="${ffmpeg_lib}/pkgconfig:${PKG_CONFIG_PATH:-}"
    export LD_LIBRARY_PATH="${ffmpeg_lib}:${LD_LIBRARY_PATH:-}"
    
    # Configure with custom FFmpeg path - CLI only (Web UI used instead of GTK)
    ${SOURCE_DIR}/configure \
        --cross=aarch64-linux-gnu \
        --build=x86_64-linux-gnu \
        --prefix=/usr/local \
        --disable-gtk \
        --enable-x265 \
        --disable-fdk-aac \
        --extra-cflags="-I${ffmpeg_include}" \
        --extra-ldflags="-L${ffmpeg_lib}" \
        2>&1 | tee configure.log
    
    if [ $? -eq 0 ]; then
        log_info "Configuration successful"
    else
        log_error "Configuration failed. Check configure.log"
        exit 1
    fi
}

# Build HandBrake
build_handbrake() {
    log_info "Building HandBrake..."
    
    cd "${SOURCE_DIR}/${BUILD_DIR}"
    
    # Set number of parallel jobs
    JOBS=$(nproc 2>/dev/null || echo 4)
    
    make -j${JOBS} 2>&1 | tee build.log
    
    if [ $? -eq 0 ]; then
        log_info "Build successful"
    else
        log_error "Build failed. Check build.log"
        exit 1
    fi
}

# Main execution
main() {
    log_info "Starting HandBrake RK3588 build process with GTK..."
    log_info "Source directory: ${SOURCE_DIR}"
    log_info "Build directory: ${BUILD_DIR}"
    
    # Check environment
    check_environment
    
    # Configure with bundled FFmpeg (required for GTK)
    configure_handbrake
    
    # Build
    build_handbrake
    
    log_info "Build completed successfully!"
    log_info "Output: ${SOURCE_DIR}/${BUILD_DIR}/build/HandBrake"
}

# Run main function
main "$@"
