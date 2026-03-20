# syntax=docker/dockerfile:1.7
#
# HandBrake RK3588 Docker image.
# Runtime image based on jlesage/baseimage-gui.
# Binaries are provided by the verified build-rk3588 workflow artifacts.
#

ARG DOCKER_IMAGE_VERSION=dev
ARG UBUNTU_VERSION=24.04
ARG BASEIMAGE_GUI_VERSION=4.11.3
ARG HANDBRAKE_VERSION=1.0.0

FROM jlesage/baseimage-gui:ubuntu-${UBUNTU_VERSION}-v${BASEIMAGE_GUI_VERSION}

ARG DOCKER_IMAGE_VERSION
ARG HANDBRAKE_VERSION

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp

RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common && \
    add-apt-repository -y universe && \
    apt-get update && apt-get install -y --no-install-recommends \
        adwaita-icon-theme \
        bzip2 \
        ca-certificates \
        curl \
        fonts-cantarell \
        libadwaita-1-0 \
        libass9 \
        libbluray2 \
        libdrm2 \
        libdvdnav4 \
        libdvdread8t64 \
        libegl1 \
        libgbm1 \
        libglib2.0-0t64 \
        libgstreamer-gl1.0-0 \
        libgstreamer-plugins-base1.0-0 \
        libgstreamer1.0-0 \
        libgtk-4-1 \
        libgudev-1.0-0 \
        libjansson4 \
        libmp3lame0 \
        libnotify4 \
        libnuma1 \
        libogg0 \
        libopus0 \
        librsvg2-2 \
        gstreamer1.0-libav \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        librsvg2-common \
        libspeex1 \
        libsvtav1enc1d1 \
        libtheora0 \
        libturbojpeg \
        libvorbis0a \
        libvorbisenc2 \
        libvpx9 \
        libwebkit2gtk-4.1-0 \
        libx264-164 \
        libx265-dev \
        libxml2 \
        lsscsi \
        pciutils \
        python3 \
        wget \
        x11-utils && \
    apt-get purge -y --auto-remove software-properties-common && \
    rm -rf /var/lib/apt/lists/*

RUN APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png && \
    install_app_icon.sh "${APP_ICON_URL}"

COPY docker/start.sh /startapp.sh
COPY artifacts/handbrake-gtk-rkmpp-arm64/bundle/bin/ghb /usr/local/bin/ghb
COPY artifacts/handbrake-gtk-rkmpp-arm64/bundle/bin/HandBrakeCLI /usr/local/bin/HandBrakeCLI
COPY artifacts/handbrake-gtk-rkmpp-arm64/bundle/lib/ /opt/handbrake/lib/

RUN chmod 0755 /startapp.sh /usr/local/bin/ghb /usr/local/bin/HandBrakeCLI && \
    find /opt/handbrake/lib -maxdepth 1 \( \
        -name 'libdrm.so*' -o \
        -name 'libgbm.so*' -o \
        -name 'libEGL.so*' -o \
        -name 'libGL.so*' -o \
        -name 'libGLESv2.so*' -o \
        -name 'libwayland-*.so*' -o \
        -name 'libxcb*.so*' -o \
        -name 'libX11.so*' -o \
        -name 'libXau.so*' -o \
        -name 'libXdmcp.so*' \
    \) -delete && \
    set-cont-env APP_NAME "HandBrake" && \
    set-cont-env APP_VERSION "${HANDBRAKE_VERSION}" && \
    set-cont-env DOCKER_IMAGE_VERSION "${DOCKER_IMAGE_VERSION}" && \
    true

ENV HANDBRAKE_DEBUG=0 \
    HANDBRAKE_GUI=1 \
    LD_LIBRARY_PATH=/opt/handbrake/lib:${LD_LIBRARY_PATH}

VOLUME ["/storage"]
VOLUME ["/output"]
VOLUME ["/watch"]

LABEL org.label-schema.name="handbrake-rk3588" \
      org.label-schema.description="Docker container for HandBrake GTK on RK3588, inspired by jlesage/docker-handbrake" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-handbrake" \
      org.label-schema.schema-version="1.0"
