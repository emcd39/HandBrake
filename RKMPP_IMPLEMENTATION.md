# RKMPP 接入实现说明

本文档只描述这个分支里 RKMPP 相关实现的代码入口、职责边界和当前限制，不承担构建步骤说明。构建与发布请看 [BUILD_RK3588.md](/E:/projects/HandBrake/BUILD_RK3588.md)。

## 1. 实现目标

这个分支的 RKMPP 接入目标是：

- 在 HandBrake 中暴露 Rockchip 编码器选项
- 让 GUI / CLI 都能选择 RKMPP 编码器
- 让 Docker / CI 产物能够带上 RKMPP 运行时库

## 2. 关键代码路径

### `libhb/common.c`

主要职责：

- 注册 RKMPP 相关编码器
- 能力检测
- 处理某些编码器可见性与兼容性判断

### `libhb/encavcodec.c`

主要职责：

- 编码器名称映射
- 与 FFmpeg/libavcodec 的编码初始化衔接
- RKMPP 编码器日志与失败路径

### `libhb/rkmpp.c`

主要职责：

- RKMPP 硬件能力封装
- 与 FFmpeg 的 Rockchip 路径对接
- 相关检测逻辑

### `libhb/work.c`

主要职责：

- 作业设置落地
- 编码任务生成时的 RKMPP 相关处理

### `libhb/muxavformat.c`

主要职责：

- 补齐 RKMPP 编码输出与 mux 侧的 codec 映射
- 避免出现 “Unknown video codec” 一类错误

### `gtk/src/hb-backend.c`

主要职责：

- GUI 编码器列表和选项映射
- `UiLanguage` 等 GUI 可见设置

## 3. GUI 语言与配置

`ghb` 的 GUI 语言并不是只靠 `LANG` 环境变量控制。

实际链路是：

1. 偏好设置中保存 `UiLanguage`
2. 启动时从 `preferences.json` 读取
3. 若值非空，则覆盖进程的 `LANGUAGE`
4. `ghb` 再通过 gettext 加载 `ghb.mo`

当前配置目录通常是：

```text
/config/xdg/config/ghb
```

关键文件：

- `preferences.json`
- `presets.json`

## 4. 翻译资源链路

为了让 Docker 中的 GUI 中文真正生效，必须同时满足：

1. 镜像里存在 `zh_CN.UTF-8` locale
2. 镜像里存在 `ghb` 的翻译文件
3. `TEXTDOMAINDIR` 指向正确的 locale 目录

当前实现里：

- `build-rk3588.yml`
  会把 GTK 构建产物中的 `ghb.mo` 打进 `bundle/share/locale`
- `docker/Dockerfile`
  会把 `bundle/share/` 复制到 `/usr/local/share/`
  并设置 `TEXTDOMAINDIR=/usr/local/share/locale`

## 5. Docker 运行时要求

RKMPP 在 Docker 里是否工作，除了二进制本身，还取决于运行环境：

- `/dev/dri`
- `/dev/mpp_service`
- `/dev/rga`
- `/dev/dma_heap`
- 宿主机内核模块和驱动状态

因此，很多问题并不是“HandBrake 代码逻辑错误”，而是：

- 设备节点不可见
- 权限不足
- GUI 基座差异
- 运行时库组合不同

## 6. 当前维护原则

这个分支后续继续维护时，建议遵循：

- 用户使用路径写进 `BUILD_RK3588.md`
- 代码接入和原理写进本文件
- 不在本文件里重复写 Docker 使用教程
- 不再保留已废弃的 `webui` 或旧 FFmpeg 路线说明

## 7. 当前限制

- 这是一个面向 RK3588 的定制分支，不追求上游全平台一致行为。
- RKMPP 的实际可用性仍受宿主机和容器运行环境影响。
- 某些问题只能通过日志、设备节点和容器环境一起定位，不能只看 HandBrake 日志单独下结论。
