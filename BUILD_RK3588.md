# RK3588 构建与使用指南

本文档描述当前仓库实际采用的 RK3588 构建、发布和 Docker 使用方式。

## 1. 产物类型

`build-rk3588.yml` 会产出两类 ARM64 产物：

- CLI bundle
  - `HandBrakeCLI`
  - 运行时动态库
  - `.deb`
- GTK bundle
  - `ghb`
  - `HandBrakeCLI`
  - 运行时动态库
  - `share/locale` 翻译资源
  - `.deb`

成功后会发布一个 `rk3588-<sha7>` 的 GitHub prerelease，供 Docker workflow 复用。

## 2. GitHub Actions 工作流

### `build-rk3588.yml`

作用：

- 在 `ubuntu-24.04-arm` runner 上构建 CLI 和 GTK ARM64 版本
- 拉取并安装 RKMPP / RKRGA 依赖
- 打包 bundle 与 `.deb`
- 发布 `rk3588-*` prerelease

当前产物消费方式：

- Docker 不再依赖短期过期的 Actions artifact
- Docker workflow 直接从 prerelease 下载 `bundle.tar.gz`

### `docker-build.yml`

作用：

- 下载指定 `rk3588-*` release 的 CLI / GTK bundle
- 构建 `linux/arm64` Docker 镜像
- 按条件推送到 GHCR

默认行为：

- 被 `build-rk3588.yml` 成功触发时，会自动取对应 `rk3588-<sha7>` release
- 手动触发时，如果未指定 `source_tag`，会默认使用最新的 `rk3588-*` prerelease

## 3. 本地 Docker 使用

当前验证可用的最小 compose 思路如下：

- `privileged: true`
- 映射：
  - `/dev/dri`
  - `/dev/mpp_service`
  - `/dev/rga`
  - `/dev/dma_heap`
- 挂载：
  - `/config`
  - `/storage`
  - `/watch`
  - `/output`
  - `/lib/modules`

仓库内示例见 [docker-compose.yml](/E:/projects/HandBrake/docker-compose.yml)。

### 推荐环境变量

当前 compose 已包含：

- `TZ=Asia/Shanghai`
- `LANG=zh_CN.UTF-8`
- `LANGUAGE=zh_CN:zh`
- `LC_ALL=zh_CN.UTF-8`
- `USER_ID=0`
- `GROUP_ID=0`

### 启动

```bash
docker compose up -d
```

### 镜像标签

常见可用方式：

- `ghcr.io/emcd39/handbrake-rk3588:latest`
- `ghcr.io/emcd39/handbrake-rk3588:sha-<sha7>`

如果你使用镜像代理，也可以替换为对应代理前缀。

## 4. 本地运行检查

容器启动后，可以先检查 locale 和配置目录：

```bash
docker exec -it handbrake-rk3588 sh -lc 'locale -a | grep -i zh'
docker exec -it handbrake-rk3588 sh -lc 'ls /config/xdg/config/ghb'
```

GUI 偏好设置实际保存在：

```text
/config/xdg/config/ghb/preferences.json
```

## 5. CLI 自检

进入容器后可以用 CLI 验证编码器是否可见：

```bash
docker exec -it handbrake-rk3588 sh -lc 'HandBrakeCLI --help | grep rkmpp'
```

最小转码示例：

```bash
docker exec -it handbrake-rk3588 sh -lc 'HandBrakeCLI -i /storage/input.mp4 -o /storage/out.mp4 -e h264_rkmpp -b 2000'
```

## 6. 镜像构建说明

Docker 镜像不是直接从源码构建 `ghb`，而是：

1. `build-rk3588.yml` 先生成 GTK / CLI bundle
2. `docker-build.yml` 下载 bundle
3. [docker/Dockerfile](/E:/projects/HandBrake/docker/Dockerfile) 将 bundle 中的内容复制进运行镜像

当前 Dockerfile 额外做了这些运行时准备：

- 安装中文字体
- 生成 `zh_CN.UTF-8` locale
- 复制 `share/locale`
- 设置 `TEXTDOMAINDIR=/usr/local/share/locale`

## 7. 已知注意事项

- RK3588 Docker 运行是否成功，核心不在“镜像是否能启动”，而在宿主机设备节点是否完整。
- GUI 切换中文除了写入 `UiLanguage`，还依赖：
  - locale 已生成
  - `ghb.mo` 已包含在镜像内
- 某些 RKMPP 行为会受容器运行环境影响，尤其是不同 GUI 基座、设备权限和宿主机驱动状态。

## 8. 不再推荐的旧路线

以下内容已经不再是当前主路径：

- 旧的 `webui/` Flask 方案
- `extract_ffmpeg.sh`
- 基于 `jellyfin-ffmpeg7` 的旧文档路线
- 过时的交叉编译说明

如需更新文档，请以 workflow 和 Dockerfile 的现状为准，不要回写这些旧方案。
