# HandBrake RK3588 (ARM64) Build Guide

## 概述

本文档介绍如何将 HandBrake 移植到 RK3588 Debian 系统，启用 GTK 图形界面（用于 novnc）。

**注意**: GTK 版本需要使用 contrib 中自带的 FFmpeg 进行构建，不能使用 jellyfin-ffmpeg7。

## 环境要求

### 主机系统 (x86_64 Linux)
- GCC/G++ 交叉编译工具链
- pkg-config
- Python 3.x
- 构建工具 (make, meson, nasm 等)

### 安装交叉编译工具链
```bash
sudo apt update
sudo apt install \
gcc-aarch64-linux-gnu \
g++-aarch64-linux-gnu \
pkg-config \
build-essential \
nasm \
meson \
ninja-build \
python3 \
python3-pip
```

### 安装 GTK 交叉编译依赖
```bash
sudo apt install \
libgtk-4-dev-arm64-cross \
libadwaita-1-dev-arm64-cross \
libglib2.0-dev-arm64-cross \
libgstreamer1.0-dev-arm64-cross \
libgstreamer-plugins-base1.0-dev-arm64-cross \
libwebkit2gtk-4.1-dev-arm64-cross \
libnotify-dev-arm64-cross \
libmpv-dev-arm64-cross \
libdvdnav-dev-arm64-cross \
libdvdread-dev-arm64-cross \
libbluray-dev-arm64-cross \
libass-dev-arm64-cross \
libfreetype6-dev-arm64-cross \
libfribidi-dev-arm64-cross \
libharfbuzz-dev-arm64-cross \
libcairo2-dev-arm64-cross \
libpango1.0-dev-arm64-cross \
libatk1.0-dev-arm64-cross \
libatk-bridge2.0-dev-arm64-cross \
libxkbcommon-dev-arm64-cross \
libx11-dev-arm64-cross \
libxext-dev-arm64-cross \
libxrandr-dev-arm64-cross \
libxdamage-dev-arm64-cross \
libxcomposite-dev-arm64-cross \
libgbm-dev-arm64-cross \
libasound2-dev-arm64-cross \
libturbojpeg0-dev-arm64-cross \
libogg-dev-arm64-cross \
libvorbis-dev-arm64-cross \
libtheora-dev-arm64-cross \
libsvtav1-dev-arm64-cross \
libxml2-dev-arm64-cross \
libdrm-dev-arm64-cross
```

### 目标系统 (RK3588)
- Debian (推荐 Debian 12 Bookworm ARM64)
- novnc (Docker 中运行)

## 构建步骤

### 步骤 1: 安装依赖

安装所有必要的构建工具和交叉编译库:
```bash
sudo apt update
sudo apt install \
gcc-aarch64-linux-gnu g++-aarch64-linux-gnu pkg-config \
build-essential nasm meson ninja-build python3 \
libgtk-4-dev-arm64-cross libadwaita-1-dev-arm64-cross \
libglib2.0-dev-arm64-cross libgstreamer1.0-dev-arm64-cross \
libgstreamer-plugins-base1.0-dev-arm64-cross \
libwebkit2gtk-4.1-dev-arm64-cross libnotify-dev-arm64-cross \
libmpv-dev-arm64-cross libdvdnav-dev-arm64-cross \
libdvdread-dev-arm64-cross libbluray-dev-arm64-cross \
libass-dev-arm64-cross libfreetype6-dev-arm64-cross \
libfribidi-dev-arm64-cross libharfbuzz-dev-arm64-cross \
libcairo2-dev-arm64-cross libpango1.0-dev-arm64-cross
```

### 步骤 2: 配置 HandBrake (启用 GTK)

创建构建目录并配置:
```bash
mkdir -p build/rk3588
cd build/rk3588
../../configure \
--cross=aarch64-linux-gnu \
--build=x86_64-linux-gnu \
--prefix=/usr/local \
--enable-gtk \
--disable-gtk-update-checks \
--enable-x265
```

### 步骤 3: 编译

```bash
make -j$(nproc)
```

### 步骤 4: 部署到 RK3588 Docker

编译完成后，将以下文件传输到 RK3588:
- `build/rk3588/build/HandBrake` (主程序)
- `deps/jellyfin-ffmpeg7/usr/lib/aarch64-linux-gnu/*` (FFmpeg 库)

## Web UI Docker 部署

我们提供两种方案，推荐使用 Web UI 而不是 GTK+novnc（更节省资源）。

### 方案 1: Flask Web UI (推荐)

HandBrake Web UI 是一个轻量级的 Web 界面，调用 HandBrakeCLI 进行转码。

#### 1.1 安装 Python 依赖

```bash
pip install -r webui/requirements.txt
```

#### 1.2 创建 Dockerfile

```dockerfile
FROM debian:bookworm-slim

RUN apt update && apt install -y \
python3 \
python3-pip \
curl \
&& rm -rf /var/lib/apt/lists/*

COPY handbrake /usr/local/bin/
COPY ffmpeg/lib /usr/lib/aarch64-linux-gnu/
COPY webui /opt/handbrake-web/

RUN chmod +x /usr/local/bin/HandBrakeCLI

ENV LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
ENV PATH=/opt/handbrake-web:$PATH

WORKDIR /opt/handbrake-web

EXPOSE 5000

CMD ["python3", "app.py"]
```

#### 1.3 访问

启动后访问 `http://<ip>:5000`

### 方案 2: novnc (已不推荐)

如果仍需 novnc 方案，请参考上一版本文档。

## 使用构建脚本

也可以使用自动构建脚本:
```bash
chmod +x build_rk3588.sh
./build_rk3588.sh
```

## 注意事项

1. HandBrake 默认会从源码构建 FFmpeg，本配置使用 jellyfin-ffmpeg7 替代
2. jellyfin-ffmpeg7 基于 FFmpeg 7.x，与 HandBrake 的 FFmpeg 8.0.1 接口兼容
3. 启用 GTK 需要更多依赖，包括 gstreamer、webkit2gtk 等
4. novnc 需要 x11vnc 和 Xvfb 来提供虚拟显示
5. **重要**: GTK 4 是必需的，GTK 3 不支持

## 故障排除

### 问题：configure 找不到 FFmpeg 库
解决：确认 PKG_CONFIG_PATH 设置正确

### 问题：GTK 依赖缺失
解决：安装完整的 GTK 交叉编译依赖包，确保包含 `libgtk-4-dev-arm64-cross` 和 `libadwaita-1-dev-arm64-cross`

### 问题：链接错误
解决：检查 jellyfin-ffmpeg7 是否完整提取

### 问题：交叉编译失败
解决：确认 aarch64-linux-gnu 工具链正确安装

### 问题：novnc 无法显示
解决：检查 Xvfb 和 x11vnc 是否正确启动

## 文件说明

- `make/cross/aarch64-linux-gnu.meson` - Meson 交叉编译配置
- `extract_ffmpeg.sh` - FFmpeg 包提取脚本
- `build_rk3588.sh` - 自动构建脚本
- `deps/jellyfin-ffmpeg7/` - FFmpeg 库提取目录
