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

# 📦 Install dependencies (for GitHub Actions safety)
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

# 📊 Get clean JSON info (IMPORTANT: no m3u8 here)
echo "📊 Fetching VOD info..."
./TwitchDownloaderCLI info --id "$VOD_ID" --format raw > info.json

echo "===== RAW INFO ====="
cat info.json

# 🧠 Extract metadata safely
TITLE=$(jq -r '.title // "Twitch Stream"' info.json)
DATE=$(jq -r '.createdAt // "unknown"' info.json | cut -d'T' -f1)

# 🧼 Clean title (remove unsafe characters)
SAFE_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:] _-')

FINAL_TITLE="$SAFE_TITLE ($DATE)"

echo "$FINAL_TITLE" > title.txt

echo "📝 Generated title: $FINAL_TITLE"

# 🎬 Download FFmpeg (portable)
echo "⬇️ Downloading FFmpeg..."
./TwitchDownloaderCLI ffmpeg --download
chmod +x ffmpeg

# 🎥 Download video (best quality)
echo "⬇️ Downloading video..."
./TwitchDownloaderCLI videodownload \
  --id "$VOD_ID" \
  --quality 1080p60 \
  --threads 4 \
  --collision Overwrite \
  -o video.mp4

# ✅ Validate file exists
if [ ! -f video.mp4 ]; then
  echo "❌ video.mp4 not found!"
  exit 1
fi

# ✅ Validate size
SIZE=$(stat -c%s "video.mp4")

if [ "$SIZE" -le 1000 ]; then
  echo "❌ video.mp4 is too small → download failed!"
  exit 1
fi

echo "✅ Download successful!"
ls -lh video.mp4

echo "===== END DOWNLOAD ====="
