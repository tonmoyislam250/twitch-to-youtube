#!/bin/bash
set -e

echo "===== START DOWNLOAD ====="

# 📥 Read VOD ID
VOD_ID=$(cat vod.txt | tr -d '[:space:]')

if [ -z "$VOD_ID" ]; then
  echo "❌ VOD ID is empty!"
  exit 1
fi

echo "📺 VOD ID: $VOD_ID"

# 📦 Ensure jq exists
if ! command -v jq &> /dev/null; then
  echo "Installing jq..."
  sudo apt-get update -y
  sudo apt-get install -y jq
fi

# ⬇️ Download TwitchDownloaderCLI
echo "⬇️ Downloading TwitchDownloaderCLI..."
wget -q https://github.com/lay295/TwitchDownloader/releases/download/1.56.4/TwitchDownloaderCLI-1.56.4-Linux-x64.zip

unzip -o TwitchDownloaderCLI-1.56.4-Linux-x64.zip
chmod +x TwitchDownloaderCLI

# 📊 Fetch clean JSON (no banner)
echo "📊 Fetching VOD info..."
./TwitchDownloaderCLI info --id "$VOD_ID" --format raw --banner false > info.json

echo "===== RAW INFO PREVIEW ====="
head -n 3 info.json

# 🧠 Extract only JSON line (skip any remaining logs)
CLEAN_JSON=$(grep -m 1 '^{\"data\"' info.json)

if [ -z "$CLEAN_JSON" ]; then
  echo "❌ Failed to extract valid JSON!"
  exit 1
fi

# 🎯 Extract metadata
TITLE=$(echo "$CLEAN_JSON" | jq -r '.data.video.title // "Twitch Stream"')
DATE=$(echo "$CLEAN_JSON" | jq -r '.data.video.createdAt // "unknown"' | cut -d'T' -f1)

# 🧼 Clean title
SAFE_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:] _-')
TRIMMED_TITLE=$(echo "$SAFE_TITLE" | cut -c1-60)

# 📅 Add date AFTER trimming
FINAL_TITLE="$TRIMMED_TITLE ($DATE)"

echo "$FINAL_TITLE" > title.txt
echo "📝 Generated title: $FINAL_TITLE"

# 🎬 Download FFmpeg
echo "⬇️ Downloading FFmpeg..."
./TwitchDownloaderCLI ffmpeg --download
chmod +x ffmpeg

# 🎥 Download video
echo "⬇️ Downloading video..."
./TwitchDownloaderCLI videodownload \
  --id "$VOD_ID" \
  --quality 1080p60 \
  --threads 4 \
  --collision Overwrite \
  -o video.mp4

# ✅ Validate file
if [ ! -f video.mp4 ]; then
  echo "❌ video.mp4 not found!"
  exit 1
fi

SIZE=$(stat -c%s "video.mp4")

if [ "$SIZE" -le 1000 ]; then
  echo "❌ video.mp4 too small → download failed!"
  exit 1
fi

echo "✅ Download successful!"
ls -lh video.mp4

echo "===== END DOWNLOAD ====="
