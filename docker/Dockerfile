# HandBrake GTK with RK3588 hardware acceleration via jellyfin-ffmpeg
# Uses novnc for web-based GUI access

FROM debian:bookworm-slim

# Build arguments for artifacts
ARG HANDRAKE_VERSION=1.0.0
ARG GHB_ARTIFACT_URL=""
ARG CLI_ARTIFACT_URL=""

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV NOVNC_PORT=6080

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # GTK runtime
    libgtk-4-1 \
    libglib2.0-0 \
    libadwaita-1-0 \
    libnotify4 \
    libwebkit2gtk-4.1-0 \
    # X11 and display
    xvfb \
    x11vnc \
    # novnc dependencies
    novnc \
    websockify \
    # Media libraries
    libass9 \
    libmp3lame0 \
    libopus0 \
    libspeex1 \
    libvpx7 \
    libbluray2 \
    libdvdnav4 \
    libdvdread8 \
    libjansson4 \
    libx264-164 \
    libx265-199 \
    libtheora0 \
    libvorbis0a \
    libogg0 \
    libturbojpeg0 \
    libnuma1 \
    libxml2 \
    libdrm2 \
    # Process management
    supervisor \
    procps \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /opt/handbrake /var/log/supervisor /data /config

# Download HandBrake binaries from GitHub artifacts
# In CI, these will be passed as build args
RUN if [ -n "$GHB_ARTIFACT_URL" ]; then \
        wget -O /tmp/ghb.zip "$GHB_ARTIFACT_URL" && \
        unzip /tmp/ghb.zip -d /opt/handbrake && \
        chmod +x /opt/handbrake/gtk/src/ghb /opt/handbrake/HandBrakeCLI; \
    fi

# Set up device permissions for RK3588 hardware
RUN groupadd -f video && groupadd -f render && groupadd -f mpp && \
    useradd -m -G video,render,mpp handbrake && \
    echo 'KERNEL=="mpp_service", MODE="0660", GROUP="mpp"' > /etc/udev/rules.d/99-mpp.rules && \
    echo 'KERNEL=="rga", MODE="0660", GROUP="mpp"' >> /etc/udev/rules.d/99-mpp.rules && \
    echo 'KERNEL=="dma_heap", MODE="0660", GROUP="render"' > /etc/udev/rules.d/99-dma-heap.rules && \
    echo 'KERNEL=="dri/card*", MODE="0660", GROUP="video"' >> /etc/udev/rules.d/99-dri.rules

# Supervisor configuration
RUN mkdir -p /etc/supervisor/conf.d
COPY docker/supervisord.conf /etc/supervisor/supervisord.conf
COPY docker/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

# novnc configuration
RUN ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# Expose novnc port
EXPOSE 6080

# Volume for media files
VOLUME ["/data", "/config"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:6080/ || exit 1

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
