#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCE_DIR="${DOWNLINK_RESOURCE_DIR:-$ROOT_DIR/Vendor}"
YTDLP="$RESOURCE_DIR/bin/yt-dlp"
FFMPEG="$RESOURCE_DIR/bin/ffmpeg"
FFPROBE="$RESOURCE_DIR/bin/ffprobe"
PLUGIN_DIR="$RESOURCE_DIR/plugins"
QA_DIR="$(mktemp -d "${TMPDIR:-/tmp}/downlink-container-qa.XXXXXX")"

cleanup() {
    rm -rf "$QA_DIR"
}
trap cleanup EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

require_executable() {
    [ -x "$1" ] || fail "Missing executable: $1"
}

probe_value() {
    "$FFPROBE" -v error -select_streams "$2" -show_entries "$3" \
        -of default=noprint_wrappers=1:nokey=1 "$1"
}

video_packet_hash() {
    "$FFMPEG" -v error -i "$1" -map 0:v:0 -c copy -f data - | shasum -a 256 | awk '{print $1}'
}

run_plugin() {
    local input_path="$1"
    local output_template="$2"
    local settings="$3"
    PYTHONDONTWRITEBYTECODE=1 "$YTDLP" \
        --enable-file-urls \
        --no-check-certificates \
        --plugin-dirs "$PLUGIN_DIR" \
        --ffmpeg-location "$RESOURCE_DIR/bin" \
        --use-postprocessor "DownlinkConvert:$settings" \
        --output "$output_template" \
        "file://$input_path"
}

require_executable "$YTDLP"
require_executable "$FFMPEG"
require_executable "$FFPROBE"
[ -f "$PLUGIN_DIR/downlink/yt_dlp_plugins/postprocessor/downlink_convert.py" ] \
    || fail "Missing DownlinkConvert plugin"

mkdir -p "$QA_DIR/mkv" "$QA_DIR/hevc" "$QA_DIR/audio-map" "$QA_DIR/failure"

"$FFMPEG" -v error \
    -f lavfi -i "testsrc2=size=320x180:rate=24:duration=1" \
    -f lavfi -i "sine=frequency=440:duration=1" \
    -map 0:v:0 -map 1:a:0 \
    -c:v libvpx-vp9 -b:v 500k -c:a libopus \
    "$QA_DIR/mkv/source.mkv"

run_plugin \
    "$QA_DIR/mkv/source.mkv" \
    "$QA_DIR/mkv/result.%(ext)s" \
    "container=mkv;video_action=copy;audio_action=flac"

[ "$(probe_value "$QA_DIR/mkv/result.mkv" v:0 stream=codec_name)" = "vp9" ] \
    || fail "MKV did not preserve VP9 video"
[ "$(probe_value "$QA_DIR/mkv/result.mkv" a:0 stream=codec_name)" = "flac" ] \
    || fail "MKV did not create FLAC audio"
[ "$(video_packet_hash "$QA_DIR/mkv/source.mkv")" = "$(video_packet_hash "$QA_DIR/mkv/result.mkv")" ] \
    || fail "MKV video packets changed"

"$FFMPEG" -v error \
    -f lavfi -i "testsrc2=size=320x180:rate=24:duration=1" \
    -c:v hevc_videotoolbox -allow_sw 1 -b:v 600k -tag:v hev1 -an \
    "$QA_DIR/hevc/source.mp4"

run_plugin \
    "$QA_DIR/hevc/source.mp4" \
    "$QA_DIR/hevc/result.%(ext)s" \
    "container=mp4;video_action=copy_hevc;audio_action=none"

[ "$(probe_value "$QA_DIR/hevc/result.mp4" v:0 stream=codec_tag_string)" = "hvc1" ] \
    || fail "MP4 HEVC tag was not changed to hvc1"
[ "$(video_packet_hash "$QA_DIR/hevc/source.mp4")" = "$(video_packet_hash "$QA_DIR/hevc/result.mp4")" ] \
    || fail "HEVC packets changed while retagging"

printf '1\n00:00:00,000 --> 00:00:00,900\nDownlink QA\n' \
    >"$QA_DIR/audio-map/captions.srt"

"$FFMPEG" -v error \
    -f lavfi -i "testsrc2=size=320x180:rate=24:duration=1" \
    -f lavfi -i "sine=frequency=440:duration=1" \
    -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=48000" \
    -f srt -i "$QA_DIR/audio-map/captions.srt" \
    -map 0:v:0 -map 1:a:0 -map 2:a:0 -map 3:s:0 -t 1 \
    -c:v libx264 -preset ultrafast -c:a aac -c:s srt \
    "$QA_DIR/audio-map/source.mkv"

run_plugin \
    "$QA_DIR/audio-map/source.mkv" \
    "$QA_DIR/audio-map/result.%(ext)s" \
    "container=mp4;video_action=copy;audio_action=aac;audio_bitrate=192;audio_stream_index=1"

[ "$(probe_value "$QA_DIR/audio-map/result.mp4" a stream=index | wc -l | tr -d ' ')" = "1" ] \
    || fail "MP4 contains an unexpected number of audio streams"
[ "$(probe_value "$QA_DIR/audio-map/result.mp4" a:0 stream=channels)" = "2" ] \
    || fail "The requested audio stream was not selected"
[ "$(probe_value "$QA_DIR/audio-map/result.mp4" s:0 stream=codec_name)" = "mov_text" ] \
    || fail "MP4 subtitles were not converted to mov_text"

cp "$QA_DIR/mkv/source.mkv" "$QA_DIR/failure/result.mkv"
failure_hash="$(shasum -a 256 "$QA_DIR/failure/result.mkv" | awk '{print $1}')"
if run_plugin \
    "$QA_DIR/failure/result.mkv" \
    "$QA_DIR/failure/result.%(ext)s" \
    "container=mkv;video_action=copy;audio_action=copy;audio_stream_index=9" \
    >"$QA_DIR/failure/output.log" 2>&1; then
    fail "Invalid audio stream unexpectedly succeeded"
fi

rg -q '\[DownlinkError:output\]' "$QA_DIR/failure/output.log" \
    || fail "Conversion failure did not include a stable error marker"
[ "$failure_hash" = "$(shasum -a 256 "$QA_DIR/failure/result.mkv" | awk '{print $1}')" ] \
    || fail "Failed conversion changed the original file"
[ ! -e "$QA_DIR/failure/result.downlink.temp.mkv" ] \
    || fail "Failed conversion left a temporary output"

printf 'Container pipeline QA passed: MKV preservation, HEVC retagging, audio/subtitle mapping, and failure safety.\n'
