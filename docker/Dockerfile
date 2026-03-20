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
ARG ALPINE_VERSION=3.20
ARG BASEIMAGE_GUI_VERSION=4.11.3
ARG HANDBRAKE_VERSION=1.0.0
ARG RKMPP_URL=https://github.com/emcd39/mpp/archive/refs/heads/master.tar.gz
ARG RKRGA_URL=https://github.com/emcd39/rga/archive/refs/heads/jellyfin-rga.tar.gz

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS handbrake-builder

ARG HANDBRAKE_VERSION
ARG RKMPP_URL
ARG RKRGA_URL

WORKDIR /build

RUN apk add --no-cache \
        autoconf \
        automake \
        bash \
        build-base \
        bzip2 \
        cmake \
        curl \
        git \
        glib-dev \
        gstreamer-dev \
        gst-plugins-base-dev \
        gtk4.0-dev \
        intltool \
        jansson-dev \
        lame-dev \
        libadwaita-dev \
        libass-dev \
        libbluray-dev \
        libdrm-dev \
        libdvdnav-dev \
        libdvdread-dev \
        libgudev-dev \
        libnotify-dev \
        libogg-dev \
        libtheora-dev \
        libtool \
        libturbojpeg-dev \
        libvorbis-dev \
        libvpx-dev \
        libxml2-dev \
        linux-headers \
        meson \
        nasm \
        ninja \
        numactl-dev \
        opus-dev \
        pkgconf \
        python3 \
        speex-dev \
        svt-av1-dev \
        webkit2gtk-4.1-dev \
        wget \
        x264-dev \
        x265-dev \
        xz \
        yasm

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
        --disable-nvenc \
        --force && \
    make -C build -j"$(nproc)" && \
    make -C build install DESTDIR=/tmp/handbrake-install

FROM jlesage/baseimage-gui:alpine-${ALPINE_VERSION}-v${BASEIMAGE_GUI_VERSION}

ARG DOCKER_IMAGE_VERSION
ARG HANDBRAKE_VERSION

WORKDIR /tmp

RUN add-pkg \
        adwaita-icon-theme \
        bash \
        coreutils \
        expect \
        findutils \
        font-cantarell \
        glib \
        gstreamer \
        gst-libav \
        gst-plugins-base \
        gst-plugins-good \
        gtk4.0 \
        jansson \
        lame-libs \
        libadwaita \
        libass \
        libbluray \
        libdrm \
        libdvdcss \
        libdvdnav \
        libdvdread \
        libgudev \
        libnotify \
        libogg \
        libsamplerate \
        libstdc++ \
        libtheora \
        libturbojpeg \
        libvorbis \
        libvpx \
        libxml2 \
        librsvg \
        lsscsi \
        numactl \
        opus \
        pciutils \
        speex \
        svt-av1 \
        webkit2gtk-4.1 \
        x264-libs \
        x265-libs \
        xdpyinfo \
        xz

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
