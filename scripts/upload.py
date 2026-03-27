import json
import os

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
import googleapiclient.discovery
import googleapiclient.http

SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]


def get_credentials():
    token_json = os.getenv("YOUTUBE_TOKEN_JSON")
    if not token_json:
        raise RuntimeError("❌ Missing YOUTUBE_TOKEN_JSON")

    credentials = Credentials.from_authorized_user_info(
        json.loads(token_json), SCOPES
    )

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())

    return credentials


def upload():
    print("===== START UPLOAD =====")

    if not os.path.exists("video.mp4"):
        raise FileNotFoundError("❌ video.mp4 missing")

    # 📥 Read dynamic title
    if os.path.exists("title.txt"):
        with open("title.txt", "r", encoding="utf-8") as f:
            title = f.read().strip()
    else:
        title = "Twitch VOD Upload"

    print("Using title:", title)

    credentials = get_credentials()

    youtube = googleapiclient.discovery.build(
        "youtube", "v3", credentials=credentials
    )

    media = googleapiclient.http.MediaFileUpload(
        "video.mp4",
        chunksize=-1,
        resumable=True
    )

    request = youtube.videos().insert(
        part="snippet,status",
        body={
            "snippet": {
                "title": title,
                "description": f"Auto uploaded VOD\n\n{title}",
                "tags": ["twitch", "vod"],
                "categoryId": "20"
            },
            "status": {"privacyStatus": "public"}
        },
        media_body=media
    )

    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            print(f"Upload: {int(status.progress()*100)}%")

    print("✅ Upload complete")
    print(response)


if __name__ == "__main__":
    upload()
