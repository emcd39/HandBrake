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
        fonts-wqy-microhei \
        fonts-wqy-zenhei \
        git \
        gstreamer1.0-libav \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        intltool \
        libadwaita-1-dev \
        libass-dev \
        libbluray-dev \
        libdrm-dev \
        libdvdnav-dev \
        libdvdread-dev \
        libglib2.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer1.0-dev \
        libgtk-4-dev \
        libgudev-1.0-dev \
        libjansson-dev \
        libmp3lame-dev \
        libnotify-dev \
        libnuma-dev \
        libogg-dev \
        libopus-dev \
        librsvg2-common \
        libspeex-dev \
        libsvtav1-dev \
        libtheora-dev \
        libturbojpeg-dev \
        libvorbis-dev \
        libvpx-dev \
        libwebkit2gtk-4.1-dev \
        libx264-dev \
        libx265-dev \
        libxml2-dev \
        locales \
        lsscsi \
        m4 \
        meson \
        ninja-build \
        pciutils \
        pkg-config \
        python3 \
        wget \
        x11-utils && \
    apt-get purge -y --auto-remove software-properties-common && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^# *zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen zh_CN.UTF-8

RUN APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png && \
    install_app_icon.sh "${APP_ICON_URL}"

COPY docker/start.sh /startapp.sh
COPY artifacts/handbrake-gtk-rkmpp-arm64/bundle/bin/ghb /usr/local/bin/ghb
COPY artifacts/handbrake-cli-rkmpp-arm64/bundle/bin/HandBrakeCLI /usr/local/bin/HandBrakeCLI
COPY artifacts/handbrake-gtk-rkmpp-arm64/bundle/lib/ /usr/local/lib/
COPY artifacts/handbrake-gtk-rkmpp-arm64/bundle/share/ /usr/local/share/

RUN chmod 0755 /startapp.sh /usr/local/bin/ghb /usr/local/bin/HandBrakeCLI && \
    set-cont-env APP_NAME "HandBrake" && \
    set-cont-env APP_VERSION "${HANDBRAKE_VERSION}" && \
    set-cont-env DOCKER_IMAGE_VERSION "${DOCKER_IMAGE_VERSION}" && \
    set-cont-env DISABLE_GLX 1 && \
    true

ENV HANDBRAKE_DEBUG=0 \
    HANDBRAKE_GUI=1 \
    LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH} \
    TEXTDOMAINDIR=/usr/local/share/locale

VOLUME ["/storage"]
VOLUME ["/output"]
VOLUME ["/watch"]

LABEL org.label-schema.name="handbrake-rk3588" \
      org.label-schema.description="Docker container for HandBrake GTK on RK3588, inspired by jlesage/docker-handbrake" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-handbrake" \
      org.label-schema.schema-version="1.0"
