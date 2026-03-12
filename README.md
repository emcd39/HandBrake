# RK3588 定制版 HandBrake 技术文档（纯 AI 移植）

本仓库基于 HandBrake 上游代码，**由纯 AI 自动移植与改造**，面向 RK3588 平台，集成 RKMPP / RKRGA 硬件编码加速与 CI 自动化打包。

> 重要声明：本分支的全部移植与改动均由 AI 完成，未经过人工逐行审阅。若用于生产，请先在目标设备上充分验证。

## 目标与特性
- RK3588 硬件加速：集成 RKMPP（H.264/H.265/MJPEG）与 RKRGA。
- GUI/CLI 双通道：GTK 前端与 CLI 均可选择 RKMPP 编码器。
- 打包与分发：GitHub Actions 自动构建 arm64 包（CLI 与 GTK），生成可下载的 deb 与运行时 bundle。
- 质量/码率策略：GUI 对 RKMPP 强制走码率模式（避免 CQ 导致的 encoder failed）。

## 代码改动要点
- `libhb/common.c`：注册 RKMPP 编码器、能力检测，强制禁用 RKMPP 的 CQ/多遍路径。
- `libhb/work.c` / `libhb/muxavformat.c`：为 RKMPP 增补 codec_id 传递与 mux 映射，避免 “Unknown video codec”/mux 失败。
- `libhb/encavcodec.c`：RKMPP 编码器名称、HEVC 兼容别名与日志提示。
- `.github/workflows/build-rk3588.yml`：拉取 nyanmisaka 版本的 RKMPP/RKRGA，构建 arm64，附带 CLI 可见性与条件性运行 smoke 测试。

## 构建说明（CI 同步的参考流程）
环境：Ubuntu arm64（Actions 使用），需可访问 GitHub。

```bash
# 依赖（参考 workflow，按需裁剪）
sudo apt-get update
sudo apt-get install -y autoconf automake build-essential cmake pkg-config \
    libtool intltool nasm yasm meson ninja-build libglib2.0-dev \
    libgtk-3-dev libjansson-dev libgstreamer1.0-dev

# 1) 拉取并构建 RKMPP
git clone https://github.com/emcd39/mpp
cd mpp && mkdir -p build && cd build
cmake .. && make -j$(nproc) && sudo make install

# 2) 拉取并构建 RKRGA（jellyfin-rga 分支）
cd rga && meson setup build && ninja -C build && sudo ninja -C build install

# 3) 配置并构建 HandBrake（GTK 示例）
cd /path/to/HandBrake
./configure --disable-nvenc --enable-rkmpp --enable-fdk-aac --enable-gst
cd build && make -j$(nproc)
```

若仅需 CLI，可替换为 `./configure --disable-nvenc --enable-rkmpp --disable-gtk`。

## 运行与验证
- 环境变量：运行前设置 `LD_LIBRARY_PATH=/usr/local/lib` 以加载 mpp/rga。
- CLI 可见性：`handbrake-cli -h | grep rkmpp` 应出现 `h264_rkmpp/hevc_rkmpp/mjpeg_rkmpp`。
- 最小转码测试：
  ```bash
  handbrake-cli -i input.mp4 -o out.mp4 -e h264_rkmpp -b 2000
  ```
- GUI 测试：在 Video Encoder 下选择 RKMPP 编码器，确认不再出现 “encoder failed”。

## CI/发布
- Workflow：`.github/workflows/build-rk3588.yml`
- 产物：CLI 与 GTK 的 deb 包与运行时压缩包作为 Actions Artifact。
- Smoke：
  - CLI 帮助中检查 RKMPP 编码器可见性。
  - 若 Runner 具备硬件，执行一次条件性的 RKMPP 转码。

## 已知问题与注意事项
- RKMPP 对 CQ/多遍路径不兼容，已在代码中禁用；GUI/CLI 请使用码率或 CQP/CVBR。
- 依赖的 mpp/rga 仓库来自 nyanmisaka 派生版本，后续更新需同步验证。
- 本分支未对 upstream 进行回归测试，非 RK3588 设备请勿使用。

## 变更历史（针对本 Fork 的关键修复）
- 修复 GUI “encoder failed”：RKMPP 在 GUI 侧强制走码率路径。
- 修复 “Unknown video codec (0x20010035)”：完善 `work.c`/`muxavformat.c` 的 RKMPP codec 映射。
- CI 稳定性：禁用 NVENC、设置 `LD_LIBRARY_PATH`，并增加 smoke 检查。

## 致谢
- 上游 HandBrake 项目及其社区。
- nyanmisaka 的 RKMPP / RKRGA 维护工作。

---
本移植完全由 AI 生成与维护，如发现问题请先在设备上复现并反馈具体日志。
