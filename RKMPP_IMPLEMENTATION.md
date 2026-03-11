# RKMPP 硬件编解码后端实现指南

## 概述
本文档说明如何在 HandBrake 中实现 Rockchip MPP (Media Process Platform) 硬件编解码支持。

## 实现步骤

### 1. 添加 librockchip-mpp 依赖

#### 1.1 contrib/rkmpp/module.defs 更新
```makefile
$(eval $(call import.MODULE.defs,RKMPP,rkmpp))
$(eval $(call import.CONTRIB.defs,RKMPP))

RKMPP.FETCH.url = https://github.com/rockchip-linux/mpp/archive/refs/tags/v1.5.0.tar.gz
RKMPP.FETCH.sha256 = <checksum>

RKMPP.BUILD.extra = PREFIX="$(RKMPP.CONFIGURE.prefix)"
RKMPP.INSTALL.extra = PREFIX="$(RKMPP.CONFIGURE.prefix)"
```

#### 1.2 添加系统依赖检测
在 `configure` 脚本中添加：
```python
# RKMPP detection
rkmpp_supported = host_tuple.match('aarch64-*-linux*')
h = 'Rockchip MPP hardware encoder/decoder (RK3588)' if rkmpp_supported else argparse.SUPPRESS
grp.add_argument('--enable-rkmpp', dest="enable_rkmpp", default=rkmpp_supported, 
                 action='store_true', help=(( 'enable %s' %h ) if h != argparse.SUPPRESS else h))
grp.add_argument('--disable-rkmpp', dest="enable_rkmpp", action='store_false', 
                 help=(( 'disable %s' %h ) if h != argparse.SUPPRESS else h))
doc.add('FEATURE.rkmpp', int(options.enable_rkmpp))
```

### 2. 实现 hb_hwaccel 接口

#### 2.1 头文件声明
在 `libhb/handbrake/common.h` 添加：
```c
extern hb_hwaccel_t hb_hwaccel_rkmpp;
```

在 `libhb/handbrake/hwaccel.h` 添加：
```c
void hb_register_rkmpp_hwaccel(void);
```

#### 2.2 实现文件
创建 `libhb/rkmpp.c` 文件，实现以下功能：
- RKMPP 解码器查找
- RKMPP 可用性检测
- 硬件流水线兼容性检查
- 硬件上下文管理

### 3. 集成 FFmpeg 的 rkmpp 解码器

#### 3.1 FFmpeg 配置
确保 FFmpeg 编译时启用 rkmpp：
```bash
--enable-rkmpp \
--enable-libdrm \
```

#### 3.2 解码器注册
在 `libhb/common.c` 注册 RKMPP：
```c
#include "handbrake/hwaccel.h"

void hb_register_hwaccels() {
    hb_register_hwaccel(&hb_hwaccel_videotoolbox);
    hb_register_hwaccel(&hb_hwaccel_nvdec);
    hb_register_hwaccel(&hb_hwaccel_mf);
    hb_register_hwaccel(&hb_hwaccel_qsv);
    
#if defined(SYS_LINUX)
    hb_register_rkmpp_hwaccel();
#endif
}
```

### 4. 构建系统更新

#### 4.1 GNUmakefile 更新
```makefile
ifeq ($(RKMPP), 1)
  FEATURE.rkmpp = 1
  CFLAGS += -DHAVE_RKMPP
  LIBS += -lrknn_rt
  LIBS += -lrockchip_mpp
endif
```

#### 4.2 Meson 配置
在 `gtk/meson.build` 添加：
```python
if get_option('rkmpp').enabled()
  ghb_deps += dependency('libdrm')
  add_project_arguments('-DHAVE_RKMPP', language: 'c')
endif
```

### 5. 测试和验证

#### 5.1 功能测试
```bash
# 测试解码
HandBrakeCLI -i input.mp4 -o output.mp4 --encoder x264 --hwaccel rkmpp

# 测试编码
HandBrakeCLI -i input.mp4 -o output.mp4 --encoder h264_rkmpp

# 查看支持的编解码器
HandBrakeCLI --list-encoders | grep rkmpp
```

#### 5.2 性能测试
```bash
# 对比软件编解码和硬件编解码
time HandBrakeCLI -i input_4k.mp4 -o sw_out.mp4 --encoder x264
time HandBrakeCLI -i input_4k.mp4 -o hw_out.mp4 --encoder h264_rkmpp
```

### 6. 已知问题和限制

1. **格式支持**: RKMPP 主要支持 H.264, HEVC, MPEG2, VP8, VP9
2. **分辨率限制**: 最大支持 4K@60fps
3. **旋转支持**: 硬件不支持旋转，需要软件处理
4. **滤镜兼容性**: 部分滤镜可能不支持硬件加速

### 7. 参考资源

- Rockchip MPP 官方文档：https://github.com/rockchip-linux/mpp
- FFmpeg RKMPP 实现：https://github.com/FFmpeg/FFmpeg/blob/master/libavcodec/rkmpp/
- RK3588 技术文档：https://wiki.radxa.com/Rock5/5/rk3588

## 故障排除

### 问题：找不到 rkmpp 解码器
**解决**: 确认 FFmpeg 编译时启用了 `--enable-rkmpp`

### 问题：MPP 初始化失败
**解决**: 
1. 检查内核驱动是否加载：`lsmod | grep rga`
2. 检查设备节点：`ls -l /dev/rga`
3. 确认用户权限：添加用户到 `video` 组

### 问题：编码质量差
**解决**: 调整编码参数：
```bash
--encoder h264_rkmpp --encoder-preset quality --quality high
```

## 下一步

1. 完善错误处理和日志记录
2. 添加更多编解码器支持
3. 优化性能
4. 添加硬件缩放和色彩空间转换
