/* rkmpp.c
 * Rockchip MPP 硬件编解码支持
 * Copyright (c) 2003-2026 HandBrake Team
 */

#include "handbrake/hwaccel.h"
#include "handbrake/handbrake.h"

#if defined(SYS_LINUX) && defined(HAVE_RKMPP)
#include <rockchip/rk_mpi.h>
#include <rockchip/rk_mpi_dec.h>
#include <rockchip/rk_mpi_enc.h>
#endif

// RKMPP 支持的编码器列表
static const int rkmpp_encoders[] = {
    AV_CODEC_ID_H264,
    AV_CODEC_ID_HEVC,
    AV_CODEC_ID_MPEG2VIDEO,
    AV_CODEC_ID_VP8,
    AV_CODEC_ID_VP9,
    0
};

// RKMPP 解码器查找
static const AVCodec *rkmpp_find_decoder(int codec_param)
{
    const char *decoder_name = NULL;
    
    switch (codec_param) {
        case AV_CODEC_ID_H264:
            decoder_name = "h264_rkmpp";
            break;
        case AV_CODEC_ID_HEVC:
            decoder_name = "hevc_rkmpp";
            break;
        case AV_CODEC_ID_MPEG2VIDEO:
            decoder_name = "mpeg2_rkmpp";
            break;
        case AV_CODEC_ID_VP8:
            decoder_name = "vp8_rkmpp";
            break;
        case AV_CODEC_ID_VP9:
            decoder_name = "vp9_rkmpp";
            break;
        default:
            return NULL;
    }
    
    return avcodec_find_decoder_by_name(decoder_name);
}

// 检查 RKMPP 是否可用
static int rkmpp_is_available(int codec_id)
{
#if defined(SYS_LINUX) && defined(HAVE_RKMPP)
    MppCtx ctx;
    MppApi *mpi;
    MppCodecType codec_type;
    
    switch (codec_id) {
        case AV_CODEC_ID_H264:
            codec_type = MPP_VIDEO_CodingAVC;
            break;
        case AV_CODEC_ID_HEVC:
            codec_type = MPP_VIDEO_CodingHEVC;
            break;
        case AV_CODEC_ID_MPEG2VIDEO:
            codec_type = MPP_VIDEO_CodingMPEG2;
            break;
        case AV_CODEC_ID_VP8:
            codec_type = MPP_VIDEO_CodingVP8;
            break;
        case AV_CODEC_ID_VP9:
            codec_type = MPP_VIDEO_CodingVP9;
            break;
        default:
            return 0;
    }
    
    if (mpp_create(&ctx, &mpi, MPP_CTX_DEC, codec_type, MPP CodingModeDefault) != MPP_OK) {
        return 0;
    }
    
    if (mpp_init(ctx) != MPP_OK) {
        mpp_destroy(ctx);
        return 0;
    }
    
    mpp_destroy(ctx);
    return 1;
#else
    return 0;
#endif
}

// 检查 RKMPP 硬件加速是否可用
static int hb_rkmpp_is_available(hb_hwaccel_t *hwaccel, int codec_id)
{
    return rkmpp_is_available(codec_id);
}

// 检查是否可以使用完整的硬件流水线
static int hb_rkmpp_can_use_full_hw_pipeline(hb_hwaccel_t *hwaccel, hb_list_t *list_filter,
                                            int encoder, int rotation, int color_range)
{
    if (rotation != 0) {
        return 0;
    }
    
    if (list_filter && hb_list_count(list_filter) > 0) {
        return 0;
    }
    
    return 1;
}

// RKMPP 硬件加速实例
hb_hwaccel_t hb_hwaccel_rkmpp = {
    .id = HB_HWACCEL_RKMPP,
    .name = "RKMPP",
    .encoders = rkmpp_encoders,
    .type = AV_HWDEVICE_TYPE_DRM,
    .hw_pix_fmt = AV_PIX_FMT_DRM_PRIME,
    .can_filter = NULL,
    .find_decoder = rkmpp_find_decoder,
    .upload = NULL,
    .caps = HB_HWACCEL_CAP_DECODING | HB_HWACCEL_CAP_ENCODING,
};

// 注册 RKMPP 硬件加速
void hb_register_rkmpp_hwaccel()
{
    hb_register_hwaccel(&hb_hwaccel_rkmpp);
}

#else

hb_hwaccel_t hb_hwaccel_rkmpp = {
    .id = HB_HWACCEL_RKMPP,
    .name = "RKMPP",
    .encoders = NULL,
    .type = AV_HWDEVICE_TYPE_NONE,
    .hw_pix_fmt = AV_PIX_FMT_NONE,
    .can_filter = NULL,
    .find_decoder = NULL,
    .upload = NULL,
    .caps = 0,
};

void hb_register_rkmpp_hwaccel()
{
}

#endif
