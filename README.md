<p align="center">
  <img src="Assets/DownlinkIcon.png" width="96" alt="Downlink icon">
</p>

<h1 align="center">Downlink</h1>

<p align="center">
  Download videos, audio, and image posts from supported links with predictable filenames.
</p>

<p align="center">
  <a href="https://github.com/wittysworkspace/Downlink/releases/latest"><strong>Download Downlink</strong></a>
  ·
  <a href="https://github.com/wittysworkspace/Downlink/releases">Releases</a>
  ·
  <a href="LICENSE">MIT License</a>
</p>

Downlink is a lightweight macOS downloader built with SwiftUI. Paste a supported link, choose video, audio, or image mode, then save media with a clean filename. It uses `yt-dlp` for link support, `ffmpeg` and `ffprobe` for media post-processing, and `gallery-dl` support files for image extraction workflows.

## Download

Download the latest DMG from the release page:

[Download Downlink for macOS](https://github.com/wittysworkspace/Downlink/releases/latest)

The packaged release includes standalone `yt-dlp`, `ffmpeg`, and `ffprobe`, plus bundled `gallery-dl` Python support files for image mode.

## Features

- Native macOS interface designed for quick everyday use
- Paste one URL at a time, then click Check or press Return to inspect the available formats
- See an estimated file size before downloading when the source provides one
- Download video, extract audio, or save image posts
- Video formats: MP4, MOV, MKV
- Audio formats: MP3, M4A, WAV, FLAC, OPUS
- Image mode saves discovered source images in their original image format when available
- Video qualities are discovered from each checked source; the highest available resolution is selected by default, then video and audio are each chosen by their highest available bitrate at that resolution
- Clean output names such as `Original title [1080p].mp4`, `Original title.wav`, or `Post title [Image].jpg`
- Metadata is always embedded in Video and Audio downloads; Video artwork and subtitles are optional where the selected container supports them
- English, Simplified Chinese, Traditional Chinese, and Thai interface languages

### Video container behavior

- **MP4 and MOV** use H.264 or HEVC video with AAC audio for compatibility with QuickTime Player, Adobe Premiere Pro, and DaVinci Resolve. If the best source at the selected resolution is VP9 or AV1, Downlink converts it to HEVC without lowering the selected resolution. Existing HEVC is stream-copied and retagged to `hvc1` when needed. Genuine MOV does not reliably retain attached artwork, so its artwork option is disabled.
- **MKV** keeps the selected source video stream without re-encoding and converts its audio to lossless FLAC when needed. This preserves the source video for DaVinci Resolve, but QuickTime Player and Adobe Premiere Pro compatibility is not guaranteed.

## Requirements

- macOS 14 or newer
- Apple Silicon Mac for the current packaged build

The source code is public and released under the MIT License.

M4A commonly stores AAC-compressed audio while providing better support for metadata than a raw `.aac` file.

## Install

1. Download `Downlink.dmg` from [Releases](https://github.com/wittysworkspace/Downlink/releases/latest).
2. Open the DMG.
3. Drag `Downlink.app` into `Applications`.
4. Open Downlink.

If macOS blocks the app because it was downloaded from the internet, right-click `Downlink.app`, choose `Open`, then confirm. A fully notarized release requires an Apple Developer account.

## Development

Build and run from source:

```sh
swift run
```

Build the distributable app:

```sh
./scripts/generate_icon.swift
./scripts/build_app.sh
```

The distributable build requires executable `yt-dlp`, `ffmpeg`, and `ffprobe` files and copies them from `Vendor/bin/`. The `gallery-dl` wrapper and vendored Python packages support Instagram Image mode:

```text
Vendor/bin/yt-dlp
Vendor/bin/ffmpeg
Vendor/bin/ffprobe
Vendor/bin/gallery-dl
Vendor/python/
Vendor/plugins/downlink/yt_dlp_plugins/postprocessor/downlink_convert.py
```

into:

```text
Downlink.app/Contents/Resources/bin/
```

For a portable release, use standalone/static `yt-dlp`, `ffmpeg`, and `ffprobe` binaries, keep the bundled `gallery-dl` Python support files current, and test the packaged app on a clean Mac.

Run the offline media pipeline QA before a release:

```sh
./scripts/test_container_pipeline.sh
```

Set `DOWNLINK_RESOURCE_DIR` to an app's `Contents/Resources` directory to test the packaged tools and plugin instead of `Vendor/`.

## Legal

Only download media that you created, own, licensed, or otherwise have permission to save. Downlink does not bypass DRM, paywalls, private access, or platform restrictions. Site extractors can change over time, and some content may be unavailable because it is private, protected, region-limited, or DRM-restricted.

## License

Downlink is released under the [MIT License](LICENSE). See [Third-Party Notices](THIRD_PARTY_NOTICES.md) for bundled tool licenses.
