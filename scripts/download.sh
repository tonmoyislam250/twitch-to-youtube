#!/bin/bash
set -e

echo "===== START DOWNLOAD ====="

VOD_ID=$(cat vod.txt)

if [ -z "$VOD_ID" ]; then
  echo "❌ VOD ID is empty!"
  exit 1
fi

echo "Downloading VOD: $VOD_ID"

# Download CLI
wget -q https://github.com/lay295/TwitchDownloader/releases/download/1.56.4/TwitchDownloaderCLI-1.56.4-Linux-x64.zip

unzip -o TwitchDownloaderCLI-1.56.4-Linux-x64.zip
chmod +x TwitchDownloaderCLI

# Download ffmpeg (portable)
./TwitchDownloaderCLI ffmpeg --download
chmod +x ffmpeg

# Download video
./TwitchDownloaderCLI videodownload --id $VOD_ID -o video.mp4

# Validate file
if [ ! -f video.mp4 ]; then
  echo "❌ video.mp4 not found!"
  exit 1
fi

SIZE=$(stat -c%s "video.mp4")

if [ "$SIZE" -le 1000 ]; then
  echo "❌ video.mp4 is too small (download failed)"
  exit 1
fi

echo "✅ Download successful"
ls -lh video.mp4
echo "===== END DOWNLOAD ====="
