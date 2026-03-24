# HandBrake RK3588 Fork

这是一个面向 RK3588 平台的 HandBrake 分支，目标是让 GTK GUI、CLI、CI 打包和 Docker 运行链路都能使用 Rockchip MPP / RGA 能力。

当前仓库重点不是“上游通用兼容性”，而是：

- 为 RK3588 暴露 `h264_rkmpp` / `h265_rkmpp` 等编码器
- 让 GitHub Actions 能持续产出可复用的 ARM64 bundle、`.deb` 和 Docker 镜像
- 提供一个在 Docker 中可落地使用的 GUI 运行方案

## 文档导航

- 构建、发布、Docker 使用说明：见 [BUILD_RK3588.md](/E:/projects/HandBrake/BUILD_RK3588.md)
- RKMPP 接入实现说明：见 [RKMPP_IMPLEMENTATION.md](/E:/projects/HandBrake/RKMPP_IMPLEMENTATION.md)

## 当前仓库结构

- `build-rk3588.yml`
  负责在 GitHub Actions 上构建 CLI / GTK ARM64 产物，并发布 `rk3588-*` prerelease 资产。
- `docker-build.yml`
  从 prerelease 下载 bundle，构建 RK3588 Docker 镜像。
- `docker/Dockerfile`
  基于 `jlesage/baseimage-gui` 的 GUI 运行镜像。
- `docker-compose.yml`
  提供当前验证可用的最小化 Docker 运行示例。

## 快速开始

如果你的目标是“直接用现成镜像”：

1. 参考 [BUILD_RK3588.md](/E:/projects/HandBrake/BUILD_RK3588.md) 里的 Docker 章节。
2. 使用仓库中的 [docker-compose.yml](/E:/projects/HandBrake/docker-compose.yml) 作为起点。
3. 确保宿主机暴露这些设备：
   - `/dev/dri`
   - `/dev/mpp_service`
   - `/dev/rga`
   - `/dev/dma_heap`

## 已知定位

- 这是一个 RK3588 定制分支，不保证非 Rockchip ARM64 或其他平台行为。
- Docker 运行时是否能正常启用 RKMPP，高度依赖宿主机设备节点和权限。
- GUI 语言切换除了 `UiLanguage` 配置外，还依赖镜像内的 locale 与 `ghb` 翻译文件。

## 维护建议

如果后续继续演进，建议遵守这个文档分工：

- `README.md` 只做项目入口页和导航
- `BUILD_RK3588.md` 只写“怎么构建、怎么发布、怎么运行”
- `RKMPP_IMPLEMENTATION.md` 只写“代码里怎么实现的”
