# Downlink

Downlink is a native macOS app for saving videos or extracting audio from links supported by `yt-dlp`. It uses `ffmpeg` to merge video and audio tracks, remux files, and convert audio formats.

Use it only for media you created, own, licensed, or otherwise have permission to download. It does not bypass DRM, paywalls, or access controls.

## Download

The packaged app is distributed as `Downlink.dmg` from GitHub Releases.

The release build bundles standalone `yt-dlp` and `ffmpeg`, so users do not need Homebrew to run the app.

## Features

- Modern macOS SwiftUI interface
- Language switcher: English, Simplified Chinese, Traditional Chinese, Thai
- Paste multiple links, one per line
- Automatic link availability check with estimated file size
- Download video with audio by default
- Extract audio
- Video formats: MP4, MKV, WEBM, MOV
- Audio formats: MP3, M4A, WAV, FLAC, OPUS, AAC
- Quality presets: 4K, 1440p, 1080p, 720p, 480p
- Output filenames include the selected quality, such as `Title [1080p].mp4`
- Optional subtitles
- Optional metadata and artwork

## Requirements

- macOS 14 or newer
- `yt-dlp`
- `ffmpeg`

Install the tools with Homebrew:

```sh
brew install yt-dlp ffmpeg
```

Check the current Mac:

```sh
./scripts/check_tools.sh
```

## Run During Development

```sh
swift run
```

## Build the App

```sh
./scripts/generate_icon.swift
./scripts/build_app.sh
open build/Downlink.app
```

## Run on Another Mac

There are two practical ways:

1. Install dependencies on the other Mac:

```sh
brew install yt-dlp ffmpeg
```

Then copy `build/Downlink.app` to that Mac and open it.

2. Bundle standalone tools inside the app:

Place executable `yt-dlp` and `ffmpeg` binaries here:

```text
Vendor/bin/yt-dlp
Vendor/bin/ffmpeg
```

Then run:

```sh
./scripts/build_app.sh
```

The build script copies `Vendor/bin/*` into `Downlink.app/Contents/Resources/bin/`, and the app will use those bundled tools first.

Important: Homebrew's `/opt/homebrew/bin/ffmpeg` is usually linked to Homebrew libraries and is not fully portable by itself. For a self-contained app, use standalone/static builds of `yt-dlp` and `ffmpeg`, then test the `.app` on a clean Mac before distribution.

## About “All Links”

No app can honestly guarantee every video link forever. Site extractors change, and some streams are DRM-protected or private. Downlink is designed to be broad and maintainable by relying on `yt-dlp`, but keeping it working means keeping the tools updated:

```sh
brew upgrade yt-dlp ffmpeg
```

## License

Downlink is released under the MIT License. See [LICENSE](LICENSE).
