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

# ⬇️ Download CLI
wget -q https://github.com/lay295/TwitchDownloader/releases/download/1.56.4/TwitchDownloaderCLI-1.56.4-Linux-x64.zip
unzip -o TwitchDownloaderCLI-1.56.4-Linux-x64.zip
chmod +x TwitchDownloaderCLI

# 📊 Get info (may contain junk)
./TwitchDownloaderCLI info --id "$VOD_ID" --format raw > info.txt

echo "===== RAW INFO PREVIEW ====="
head -n 5 info.txt

# 🧠 Extract title + date using Python (robust)
read TITLE DATE <<< $(python3 << 'EOF'
import json, re

with open("info.txt", "r", encoding="utf-8") as f:
    text = f.read()

# find first JSON block
match = re.search(r'\{.*?\}\}', text, re.DOTALL)

if not match:
    print("Twitch_Stream unknown")
    exit()

try:
    data = json.loads(match.group())
    video = data.get("data", {}).get("video", {})
    title = video.get("title", "Twitch Stream")
    date = video.get("createdAt", "unknown").split("T")[0]
    print(title, date)
except:
    print("Twitch_Stream unknown")
EOF
)

# 🧼 Clean title
SAFE_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:] _-')
FINAL_TITLE="$SAFE_TITLE ($DATE)"

echo "$FINAL_TITLE" > title.txt
echo "📝 Title: $FINAL_TITLE"

# 🎬 Download FFmpeg
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
