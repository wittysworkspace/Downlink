#!/usr/bin/env bash
set -euo pipefail

missing=0

if command -v yt-dlp >/dev/null 2>&1; then
    echo "yt-dlp: $(command -v yt-dlp)"
else
    echo "yt-dlp: missing"
    missing=1
fi

if command -v ffmpeg >/dev/null 2>&1; then
    echo "ffmpeg: $(command -v ffmpeg)"
else
    echo "ffmpeg: missing"
    missing=1
fi

if [ "$missing" -ne 0 ]; then
    echo
    echo "Install with: brew install yt-dlp ffmpeg"
    exit 1
fi
