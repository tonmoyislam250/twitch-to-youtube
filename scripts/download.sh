#!/bin/bash
set -e

echo "===== START DOWNLOAD ====="

VOD_ID=$(cat vod.txt)

if [ -z "$VOD_ID" ]; then
  echo "❌ VOD ID empty"
  exit 1
fi

# Download CLI
wget -q https://github.com/lay295/TwitchDownloader/releases/download/1.56.4/TwitchDownloaderCLI-1.56.4-Linux-x64.zip
unzip -o TwitchDownloaderCLI-1.56.4-Linux-x64.zip
chmod +x TwitchDownloaderCLI

# Get VOD info (RAW JSON)
./TwitchDownloaderCLI info --id $VOD_ID --format raw > info.json

echo "===== VOD INFO ====="
cat info.json

# Extract title + date
TITLE=$(jq -r '.title' info.json)
DATE=$(jq -r '.createdAt' info.json | cut -d'T' -f1)

# Clean title (remove bad chars)
SAFE_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:] _-')

FINAL_TITLE="$SAFE_TITLE ($DATE)"

echo "$FINAL_TITLE" > title.txt

echo "Generated title: $FINAL_TITLE"

# Download ffmpeg
./TwitchDownloaderCLI ffmpeg --download
chmod +x ffmpeg

# Download video
./TwitchDownloaderCLI videodownload \
  --id $VOD_ID \
  --quality 1080p60 \
  --threads 4 \
  --collision Overwrite \
  -o video.mp4

# Validate
if [ ! -f video.mp4 ]; then
  echo "❌ video not found"
  exit 1
fi

SIZE=$(stat -c%s "video.mp4")
if [ "$SIZE" -le 1000 ]; then
  echo "❌ video too small"
  exit 1
fi

echo "✅ Download OK"
ls -lh video.mp4

echo "===== END DOWNLOAD ====="
