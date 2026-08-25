# Third-Party Notices

Downlink is distributed under the MIT License. Some release builds include third-party command-line tools so users can run the app without installing extra dependencies.

## yt-dlp

- Project: yt-dlp
- Website: https://github.com/yt-dlp/yt-dlp
- Version bundled in the current macOS release: 2026.08.19
- License: The Unlicense, with additional notices for bundled executable dependencies as described by the yt-dlp project
- Source code: https://github.com/yt-dlp/yt-dlp
- License file: https://github.com/yt-dlp/yt-dlp/blob/master/LICENSE

## gallery-dl

- Project: gallery-dl
- Website: https://github.com/mikf123/gallery-dl
- Version bundled in the current macOS release: 1.32.4
- License: GPL-2.0
- Source code: https://github.com/mikf123/gallery-dl
- License file: https://github.com/mikf123/gallery-dl/blob/master/LICENSE

## Bundled Python Support Packages

Some macOS release builds include Python package files under `Contents/Resources/python/` so the bundled `gallery-dl` wrapper can find its Python modules without a Homebrew package install.

- certifi 2026.06.17: MPL-2.0, https://github.com/certifi/python-certifi
- charset-normalizer 3.4.7: MIT, https://github.com/jawah/charset_normalizer
- chardet 7.4.3: 0BSD, https://github.com/chardet/chardet
- idna 3.18: BSD-3-Clause, https://github.com/kjd/idna
- requests 2.34.2: Apache-2.0, https://github.com/psf/requests
- urllib3 2.7.0: MIT, https://github.com/urllib3/urllib3

## FFmpeg

- Project: FFmpeg
- Website: https://ffmpeg.org
- Versions bundled in the current macOS release: FFmpeg 8.1.1 and FFprobe 8.1.2
- Binary build identifiers: `8.1.1-https://www.martin-riedl.de` and `8.1.2-https://www.martin-riedl.de`
- License: GPL-enabled FFmpeg binary
- Source code: https://ffmpeg.org/download.html
- Legal information: https://ffmpeg.org/legal.html

The bundled FFmpeg and FFprobe binaries report the following build configuration:

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

FFmpeg, yt-dlp, gallery-dl, and the bundled Python packages are independent projects. Downlink is not affiliated with, endorsed by, or sponsored by those projects.
