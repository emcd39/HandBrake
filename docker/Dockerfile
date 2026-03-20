# syntax=docker/dockerfile:1.7
#
# HandBrake RK3588 Docker image.
# Rewritten to follow the jlesage/docker-handbrake approach:
# - multi-stage build
# - jlesage/baseimage-gui runtime
# - /startapp.sh startup contract
# - GUI over web/VNC on ports 5800/5900
#

ARG DOCKER_IMAGE_VERSION=dev
ARG UBUNTU_VERSION=24.04
ARG BASEIMAGE_GUI_VERSION=4.11.3
ARG HANDBRAKE_VERSION=1.0.0
ARG RKMPP_URL=https://github.com/emcd39/mpp/archive/refs/heads/master.tar.gz
ARG RKRGA_URL=https://github.com/emcd39/rga/archive/refs/heads/jellyfin-rga.tar.gz

FROM --platform=$BUILDPLATFORM ubuntu:${UBUNTU_VERSION} AS handbrake-builder

ARG HANDBRAKE_VERSION
ARG RKMPP_URL
ARG RKRGA_URL

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common && \
    add-apt-repository -y universe && \
    apt-get update && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        bzip2 \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        git \
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
        libtool-bin \
        libmp3lame-dev \
        libnotify-dev \
        libnuma-dev \
        libogg-dev \
        libopus-dev \
        libspeex-dev \
        libsvtav1-dev \
        libtheora-dev \
        libtool \
        libturbojpeg-dev \
        libvorbis-dev \
        libvpx-dev \
        libwebkit2gtk-4.1-dev \
        libx264-dev \
        libx265-dev \
        libxml2-dev \
        m4 \
        meson \
        nasm \
        ninja-build \
        pkg-config \
        python3 \
        python3-pip \
        wget \
        xz-utils \
        yasm \
        zlib1g-dev && \
    apt-get purge -y --auto-remove software-properties-common && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/rkmpp.tar.gz "${RKMPP_URL}" && \
    mkdir -p /build/rkmpp && \
    tar -xzf /tmp/rkmpp.tar.gz -C /build/rkmpp --strip-components=1 && \
    cmake -S /build/rkmpp -B /build/rkmpp/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_SHARED_LIBS=ON && \
    cmake --build /build/rkmpp/build -j"$(nproc)" && \
    cmake --install /build/rkmpp/build

RUN wget -O /tmp/rkrga.tar.gz "${RKRGA_URL}" && \
    mkdir -p /build/rkrga && \
    tar -xzf /tmp/rkrga.tar.gz -C /build/rkrga --strip-components=1 && \
    meson setup /build/rkrga/build /build/rkrga \
        --prefix=/usr/local \
        --libdir=lib \
        --buildtype=release \
        --default-library=shared \
        -Dcpp_args=-fpermissive \
        -Dlibdrm=false \
        -Dlibrga_demo=false && \
    ninja -C /build/rkrga/build && \
    ninja -C /build/rkrga/build install

COPY . /src/HandBrake

WORKDIR /src/HandBrake

RUN export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/pkgconfig:${PKG_CONFIG_PATH} && \
    ./configure \
        --prefix=/usr/local \
        --enable-gtk \
        --enable-rkmpp \
        --force && \
    make -C build -j"$(nproc)" && \
    make -C build install DESTDIR=/tmp/handbrake-install

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

RUN APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png && \
    install_app_icon.sh "${APP_ICON_URL}"

COPY docker/start.sh /startapp.sh
COPY --from=handbrake-builder /tmp/handbrake-install/ /
COPY --from=handbrake-builder /usr/local/lib/librockchip_mpp.so* /usr/local/lib/
COPY --from=handbrake-builder /usr/local/lib/libmpp.so* /usr/local/lib/
COPY --from=handbrake-builder /usr/local/lib/librga.so* /usr/local/lib/

RUN chmod 0755 /startapp.sh && \
    set-cont-env APP_NAME "HandBrake" && \
    set-cont-env APP_VERSION "${HANDBRAKE_VERSION}" && \
    set-cont-env DOCKER_IMAGE_VERSION "${DOCKER_IMAGE_VERSION}" && \
    set-cont-env DISABLE_GLX 1 && \
    true

ENV HANDBRAKE_DEBUG=0 \
    HANDBRAKE_GUI=1 \
    LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

VOLUME ["/storage"]
VOLUME ["/output"]
VOLUME ["/watch"]

LABEL org.label-schema.name="handbrake-rk3588" \
      org.label-schema.description="Docker container for HandBrake GTK on RK3588, inspired by jlesage/docker-handbrake" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-handbrake" \
      org.label-schema.schema-version="1.0"
