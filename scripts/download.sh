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

# 📦 Install jq if missing
if ! command -v jq &> /dev/null; then
  echo "Installing jq..."
  sudo apt-get update -y
  sudo apt-get install -y jq
fi

# ⬇️ Download CLI
wget -q https://github.com/lay295/TwitchDownloader/releases/download/1.56.4/TwitchDownloaderCLI-1.56.4-Linux-x64.zip
unzip -o TwitchDownloaderCLI-1.56.4-Linux-x64.zip
chmod +x TwitchDownloaderCLI

# 📊 Get info (may be messy)
./TwitchDownloaderCLI info --id "$VOD_ID" --format raw > info.json

echo "===== RAW INFO PREVIEW ====="
head -n 5 info.json

# 🧠 Extract ONLY valid JSON (ignore m3u8 + extra)
CLEAN_JSON=$(sed -n '1,/^}/p' info.json | tr -d '\000')

# 🧪 Debug
echo "===== CLEAN JSON ====="
echo "$CLEAN_JSON"

# 🎯 Extract fields safely
TITLE=$(echo "$CLEAN_JSON" | jq -r '.data.video.title // "Twitch Stream"')
DATE=$(echo "$CLEAN_JSON" | jq -r '.data.video.createdAt // "unknown"' | cut -d'T' -f1)

# 🧼 Clean title
SAFE_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:] _-')
FINAL_TITLE="$SAFE_TITLE ($DATE)"

echo "$FINAL_TITLE" > title.txt
echo "📝 Title: $FINAL_TITLE"

# 🎬 FFmpeg
./TwitchDownloaderCLI ffmpeg --download
chmod +x ffmpeg

# 🎥 Download video
./TwitchDownloaderCLI videodownload \
  --id "$VOD_ID" \
  --quality 1080p60 \
  --threads 4 \
  --collision Overwrite \
  -o video.mp4

# ✅ Validate
if [ ! -f video.mp4 ]; then
  echo "❌ video.mp4 not found!"
  exit 1
fi

SIZE=$(stat -c%s "video.mp4")
if [ "$SIZE" -le 1000 ]; then
  echo "❌ video too small!"
  exit 1
fi

echo "✅ Download successful"
ls -lh video.mp4

echo "===== END DOWNLOAD ====="
