# Video Container Policy Design

**Status:** Approved design; written specification awaiting final user review

**Release:** Downlink 26.0 (build 2600)

**Scope:** MP4, MOV, and MKV video behavior plus public-release verification

## Goal

Downlink offers three video containers with two predictable purposes:

- **MP4 and MOV** use the same compatibility-focused codec policy. The user chooses the preferred container and filename extension.
- **MKV** preserves the highest-quality source video available at the selected resolution for editing in DaVinci Resolve.

No format may silently reduce a selected 1440p or 2160p download to 1080p merely to obtain H.264 video.

## User-Facing Behavior

The Video format menu retains **MP4**, **MOV**, and **MKV**.

The existing Check flow and Quality menu remain unchanged. Check shows every usable source resolution. The highest available resolution remains the default, and changing Quality after Check does not require another Check.

Users choose resolution and container, not codec. Downlink selects the codec workflow automatically.

## MP4 and MOV: Shared Compatibility Policy

For the selected resolution, MP4 and MOV choose the same highest-bitrate usable source video and the same highest-bitrate available audio source. They then produce one of these codec combinations:

1. **H.264/HEVC + AAC** when the selected source video is already compatible. Video is copied without re-encoding.
2. **HEVC + AAC** when the selected source video is VP9 or AV1. Video is transcoded at the same dimensions and frame rate using bundled FFmpeg. VideoToolbox is configured to prioritize quality, enable spatial adaptive quantization when available, allow Apple's software encoder path, and use a target bitrate equal to the greater of 1.5 times the reported source video bitrate or the resolution floor: 20 Mbps at 2160p and above, 12 Mbps at 1440p, 8 Mbps at 1080p, and 5 Mbps below 1080p. If VideoToolbox cannot encode the selected source, the app reports the conversion failure rather than silently changing quality.

AAC source audio is copied when the target container accepts it safely. Opus or another incompatible stereo audio codec is converted to AAC-LC at 320 kbps while preserving its sample rate and channel layout. HEVC uses the `hvc1` tag in both containers for Apple compatibility.

The output retains the selected dimensions, aspect ratio, frame rate, color description, metadata, and requested subtitles. MP4 supports optional embedded artwork. Genuine QuickTime MOV does not reliably retain the attached-picture artwork written by yt-dlp/FFmpeg, so the artwork checkbox is visibly disabled for MOV rather than claiming success. MP4 and MOV may differ slightly in file size because of container overhead, but their source selection, encoded video quality, audio quality, and visible result must otherwise be equivalent.

Direct tests with the bundled FFmpeg confirm that genuine MOV files can contain both supported output combinations: H.264/AAC and HEVC/AAC.

## MKV: Source-Quality DaVinci Policy

For the selected resolution, MKV chooses the highest-bitrate source video and copies its encoded video packets without re-encoding. VP9, AV1, H.264, or HEVC remains in its original codec, dimensions, frame rate, and encoded quality.

The highest-bitrate available source audio is decoded to FLAC unless it is already FLAC. This does not restore quality already removed by the source codec, but it introduces no additional lossy compression and avoids relying on Opus-in-MKV support in DaVinci Resolve.

MKV retains existing metadata, optional artwork, and requested subtitle behavior. Audio conversion and remuxing add little processing time compared with video transcoding.

MKV is intended for DaVinci Resolve and source-quality retention. QuickTime Player and Adobe Premiere Pro compatibility is not promised for MKV.

If the selected streams cannot be muxed into MKV, the app reports an unsupported-output error. It must not re-encode video, change format, or lower the selected quality without the user's knowledge.

Direct tests with the bundled FFmpeg confirm VP9 stream copy with FLAC audio in a genuine Matroska container.

## Download and Conversion Flow

For MP4 and MOV, compatible H.264/HEVC video is remuxed instead of re-encoded. When only audio conversion is required, video remains stream-copied.

When MP4 or MOV requires VP9/AV1 conversion, the app shows a distinct converting state after download. On the current M4 Pro test machine, a 30-second 2880x2160 VP9 sample encoded to HEVC in approximately 9.8 seconds, or about 3.05 times real-time. Actual duration varies by source and hardware.

MKV never enters a video-conversion path. Its FLAC audio conversion may use the converting state while leaving video packets untouched.

Cancellation stops download and conversion, removes incomplete temporary output, and leaves previously completed files untouched. A failure must not silently return a lower-resolution file, change the selected container, or leave a partial file at the final filename.

## Format Boundaries

- MP4 and MOV prioritize broad playback and editing compatibility while preserving the selected resolution.
- MOV in this design is not Apple ProRes.
- MKV prioritizes fidelity to the selected source video for DaVinci Resolve.
- All three containers expose the same usable resolutions after Check.
- Audio-only and image modes are unchanged.
- Metadata and subtitle controls retain the behavior already approved for release 26.0. Artwork remains available for MP4 and MKV and is disabled for genuine MOV because E2E verification showed that its attached artwork is discarded.

## Selection and Command Model

The checked media catalog keeps codec and bitrate information for every source stream. Video selection returns the exact source selector and one processing policy:

- `copyCompatible(container)` for MP4 or MOV;
- `transcodeCompatible(container)` for MP4 or MOV;
- `copySourceVideoToMKV` for MKV, with lossless FLAC audio output.

Command construction consumes this policy rather than inferring compatibility again. Quality discovery, source selection, container selection, and post-processing remain independently testable.

Temporary download and conversion files use collision-safe names in the destination filesystem. Only a fully validated result is moved to the final user-visible filename.

## Error Handling

The app provides actionable localized errors for:

- no usable stream at the selected resolution;
- VideoToolbox hardware and allowed software encoding paths unavailable;
- insufficient disk space or unwritable destination;
- MP4, MOV, or MKV muxing rejected by FFmpeg;
- download, merge, metadata, artwork, subtitle, audio conversion, or video conversion failure;
- cancellation or timeout.

No failure may leave a zero-byte or partially converted file with the intended final filename.

## Verification

### Automated tests

- Catalog tests cover H.264, HEVC, VP9, and AV1 video with AAC and Opus audio.
- All three containers expose every usable source resolution.
- Incompatible high-resolution MP4/MOV sources request HEVC/AAC conversion instead of selecting a lower H.264 resolution.
- MP4 and MOV select identical source format IDs and processing policies for the same resolution.
- Compatible MP4/MOV video is not re-encoded unnecessarily.
- MKV selects the highest-bitrate video at the requested resolution, stream-copies video, and outputs FLAC audio.
- Command tests cover metadata, container-aware artwork behavior, subtitles, cancellation, timeouts, duplicate names, software encoding allowance, and failed-conversion cleanup.
- The complete existing test suite passes.

### End-to-end tests

- Download real H.264, VP9, and AV1 samples at multiple resolutions into MP4, MOV, and MKV.
- Use `ffprobe` to verify the actual container, codec, dimensions, frame rate, audio, metadata, supported artwork behavior, subtitles, and final filename.
- Confirm VP9/AV1 sources become HEVC/AAC in MP4 and MOV without a resolution or frame-rate drop.
- Confirm MKV video matches the selected source codec and is not re-encoded; confirm its audio is FLAC.
- Verify MP4 and MOV with Quick Look and QuickTime Player.
- Import representative outputs into installed Premiere Pro and DaVinci Resolve versions when available.
- Confirm cancellation and induced failures leave no partial final output.

### Public-Release Checks

- Build the Release configuration and validate the application signature.
- Install and open `/Applications/Downlink.app`.
- Confirm Spotlight finds only the installed application.
- Review the repository for secrets, machine-specific paths, ignored bundled binaries, licenses, third-party notices, README accuracy, and unintended files.
- Run a final code review and classify remaining findings by release severity.

Publishing, pushing, or changing the GitHub repository is outside this work unless the user explicitly authorizes it later.
