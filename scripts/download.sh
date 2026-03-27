#!/bin/bash

set -e

VOD_ID=$(cat vod.txt)

echo "Downloading VOD: $VOD_ID"

# Download TwitchDownloaderCLI
wget https://github.com/lay295/TwitchDownloader/releases/download/1.56.4/TwitchDownloaderCLI-1.56.4-Linux-x64.zip

unzip TwitchDownloaderCLI-1.56.4-Linux-x64.zip -d bins/
chmod +x bins/TwitchDownloaderCLI

# Install FFmpeg if not present
./bins/TwitchDownloaderCLI ffmpeg --download
chmod +x ffmpeg

# Download video
./TwitchDownloaderCLI videodownload --id $VOD_ID -o video.mp4

echo "Download complete"