# HandBrake RK3588 (ARM64) Build Guide

## 概述

本文档介绍如何将HandBrake移植到RK3588 Debian系统，启用GTK图形界面（用于novnc）。

**注意**: GTK版本需要使用contrib中自带的FFmpeg进行构建，不能使用jellyfin-ffmpeg7。

## 环境要求

### 主机系统 (x86_64 Linux)
- GCC/G++ 交叉编译工具链
- pkg-config
- Python 3.x
- 构建工具 (make, meson, nasm等)

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

### 安装GTK交叉编译依赖
```bash
sudo apt install \
    libgtk-3-dev-arm64-cross \
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
    libasound2-dev-arm64-cross
```

### 目标系统 (RK3588)
- Debian (推荐 Debian 12 Bookworm ARM64)
- novnc (Docker中运行)

## 构建步骤

### 步骤1: 安装依赖

安装所有必要的构建工具和交叉编译库:
```bash
sudo apt update
sudo apt install \
    gcc-aarch64-linux-gnu g++-aarch64-linux-gnu pkg-config \
    build-essential nasm meson ninja-build python3 \
    libgtk-3-dev-arm64-cross libgstreamer1.0-dev-arm64-cross \
    libgstreamer-plugins-base1.0-dev-arm64-cross \
    libwebkit2gtk-4.1-dev-arm64-cross libnotify-dev-arm64-cross \
    libmpv-dev-arm64-cross libdvdnav-dev-arm64-cross \
    libdvdread-dev-arm64-cross libbluray-dev-arm64-cross \
    libass-dev-arm64-cross libfreetype6-dev-arm64-cross \
    libfribidi-dev-arm64-cross libharfbuzz-dev-arm64-cross \
    libcairo2-dev-arm64-cross libpango1.0-dev-arm64-cross
```

### 步骤2: 配置HandBrake (启用GTK)

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

### 步骤4: 编译

```bash
make -j$(nproc)
```

### 步骤5: 部署到RK3588 Docker

编译完成后，将以下文件传输到RK3588:
- `build/rk3588/build/HandBrake` (主程序)
- `deps/jellyfin-ffmpeg7/usr/lib/aarch64-linux-gnu/*` (FFmpeg库)

## Web UI Docker部署

我们提供两种方案，推荐使用Web UI而不是GTK+novnc（更节省资源）。

### 方案1: Flask Web UI (推荐)

HandBrake Web UI是一个轻量级的Web界面，调用HandBrakeCLI进行转码。

#### 1.1 安装Python依赖

```bash
pip install -r webui/requirements.txt
```

#### 1.2 创建Dockerfile

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

### 方案2: novnc (已不推荐)

如果仍需novnc方案，请参考上一版本文档。

## 使用构建脚本

也可以使用自动构建脚本:
```bash
chmod +x build_rk3588.sh
./build_rk3588.sh
```

## 注意事项

1. HandBrake默认会从源码构建FFmpeg，本配置使用jellyfin-ffmpeg7替代
2. jellyfin-ffmpeg7基于FFmpeg 7.x，与HandBrake的FFmpeg 8.0.1接口兼容
3. 启用GTK需要更多依赖，包括gstreamer、webkit2gtk等
4. novnc需要x11vnc和Xvfb来提供虚拟显示

## 故障排除

### 问题: configure找不到FFmpeg库
解决: 确认PKG_CONFIG_PATH设置正确

### 问题: GTK依赖缺失
解决: 安装完整的GTK交叉编译依赖包

### 问题: 链接错误
解决: 检查jellyfin-ffmpeg7是否完整提取

### 问题: 交叉编译失败
解决: 确认aarch64-linux-gnu工具链正确安装

### 问题: novnc无法显示
解决: 检查Xvfb和x11vnc是否正确启动

## 文件说明

- `make/cross/aarch64-linux-gnu.meson` - Meson交叉编译配置
- `extract_ffmpeg.sh` - FFmpeg包提取脚本
- `build_rk3588.sh` - 自动构建脚本
- `deps/jellyfin-ffmpeg7/` - FFmpeg库提取目录
