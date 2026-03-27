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

# 📦 Install dependencies (GitHub Actions safe)
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

# 📊 Get CLEAN JSON (no banner, no logs)
echo "📊 Fetching VOD info..."
./TwitchDownloaderCLI info --id "$VOD_ID" --format raw --banner false > info.json

echo "===== JSON PREVIEW ====="
cat info.json | head -n 5

# 🧠 Extract metadata (SAFE)
TITLE=$(jq -r '.data.video.title // "Twitch Stream"' info.json)
DATE=$(jq -r '.data.video.createdAt // "unknown"' info.json | cut -d'T' -f1)
CHANNEL=$(jq -r '.data.video.owner.displayName // "Streamer"' info.json)

# 🧼 Clean title (YouTube safe)
SAFE_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:] _-')

FINAL_TITLE="$CHANNEL - $SAFE_TITLE ($DATE)"

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
