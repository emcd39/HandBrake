#include "handbrake/common.h"
#include "handbrake/handbrake.h"
#include "handbrake/hbffmpeg.h"
#include "handbrake/hwaccel.h"

static const int rkmpp_encoders[] =
{
    HB_VCODEC_FFMPEG_RKMPP_H264,
    HB_VCODEC_FFMPEG_RKMPP_H265,
    HB_VCODEC_FFMPEG_RKMPP_MJPEG,
    HB_VCODEC_INVALID,
};

static int rkmpp_can_filter(hb_list_t *filters)
{
    if (filters == NULL)
    {
        return 1;
    }

    for (int ii = 0; ii < hb_list_count(filters); ii++)
    {
        hb_filter_object_t *filter = hb_list_item(filters, ii);

        switch (filter->id)
        {
            case HB_FILTER_VFR:
            case HB_FILTER_AVFILTER:
            case HB_FILTER_CROP_SCALE:
            case HB_FILTER_PAD:
            case HB_FILTER_ROTATE:
            case HB_FILTER_COLORSPACE:
            case HB_FILTER_FORMAT:
                break;

            default:
                return 0;
        }
    }

    return 1;
}

static void *rkmpp_find_decoder(int codec_param)
{
    switch (codec_param)
    {
        case AV_CODEC_ID_H264:
            return (void *)avcodec_find_decoder_by_name("h264_rkmpp");

        case AV_CODEC_ID_HEVC:
            return (void *)avcodec_find_decoder_by_name("hevc_rkmpp");

        case AV_CODEC_ID_VP8:
            return (void *)avcodec_find_decoder_by_name("vp8_rkmpp");

        case AV_CODEC_ID_VP9:
            return (void *)avcodec_find_decoder_by_name("vp9_rkmpp");

        case AV_CODEC_ID_AV1:
            return (void *)avcodec_find_decoder_by_name("av1_rkmpp");

        case AV_CODEC_ID_MJPEG:
            return (void *)avcodec_find_decoder_by_name("mjpeg_rkmpp");

        case AV_CODEC_ID_MPEG2VIDEO:
            return (void *)avcodec_find_decoder_by_name("mpeg2_rkmpp");

        case AV_CODEC_ID_MPEG4:
            return (void *)avcodec_find_decoder_by_name("mpeg4_rkmpp");

        default:
            break;
    }

    return (void *)avcodec_find_decoder(codec_param);
}

hb_hwaccel_t hb_hwaccel_rkmpp =
{
    .id           = HB_DECODE_RKMPP,
    .name         = "Rockchip MPP",
    .encoders     = rkmpp_encoders,
    .type         = AV_HWDEVICE_TYPE_RKMPP,
    .hw_pix_fmt   = AV_PIX_FMT_DRM_PRIME,
    .can_filter   = rkmpp_can_filter,
    .find_decoder = rkmpp_find_decoder,
    .caps         = HB_HWACCEL_CAP_SCAN | HB_HWACCEL_CAP_ROTATE,
};
