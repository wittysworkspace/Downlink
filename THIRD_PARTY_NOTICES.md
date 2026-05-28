# Third-Party Notices

Downlink is distributed under the MIT License. Some release builds include third-party command-line tools so users can run the app without installing extra dependencies.

## yt-dlp

- Project: yt-dlp
- Website: https://github.com/yt-dlp/yt-dlp
- Version bundled in the current macOS release: 2026.03.17
- License: The Unlicense, with additional notices for bundled executable dependencies as described by the yt-dlp project
- Source code: https://github.com/yt-dlp/yt-dlp
- License file: https://github.com/yt-dlp/yt-dlp/blob/master/LICENSE

## FFmpeg

- Project: FFmpeg
- Website: https://ffmpeg.org
- Version bundled in the current macOS release: 8.1.1
- Binary build identifier: `8.1.1-https://www.martin-riedl.de`
- License: GPL-enabled FFmpeg binary
- Source code: https://ffmpeg.org/download.html
- Legal information: https://ffmpeg.org/legal.html

The bundled FFmpeg binary reports the following build configuration:

```text
--prefix=/Volumes/ffmpeg_arm64/out
--pkg-config-flags=--static
--extra-version='https://www.martin-riedl.de'
--enable-gray
--enable-libxml2
--enable-version3
--enable-gpl
--enable-openssl
--enable-libfreetype
--enable-fontconfig
--enable-libharfbuzz
--enable-libsnappy
--enable-libsrt
--enable-libvmaf
--enable-libass
--enable-libklvanc
--enable-libzimg
--enable-libzvbi
--enable-libaom
--enable-libdav1d
--enable-libopenh264
--enable-libopenjpeg
--enable-librav1e
--enable-libsvtav1
--enable-libvpx
--enable-libvvenc
--enable-libwebp
--enable-libx264
--enable-libx265
--enable-libmp3lame
--enable-libopus
--enable-libvorbis
--enable-libtheora
```

FFmpeg and yt-dlp are independent projects. Downlink is not affiliated with, endorsed by, or sponsored by those projects.
