import json
import os
import time

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
import google_auth_oauthlib.flow
import googleapiclient.discovery
import googleapiclient.http
from googleapiclient.errors import HttpError

SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]
CLIENT_SECRET_FILE = "client_secret.json"
TOKEN_FILE = "token.json"


def get_credentials():
    credentials = None

    # 🔐 Load from GitHub Secret
    token_json = os.getenv("YOUTUBE_TOKEN_JSON")
    if token_json:
        credentials = Credentials.from_authorized_user_info(
            json.loads(token_json), SCOPES
        )

    # 💾 Load from local file
    elif os.path.exists(TOKEN_FILE):
        credentials = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

    # 🔄 Refresh if expired
    if credentials and credentials.expired and credentials.refresh_token:
        try:
            credentials.refresh(Request())
        except Exception as e:
            raise RuntimeError(f"❌ Token refresh failed: {e}")

    # ✅ If valid → return
    if credentials and credentials.valid:
        return credentials

    # 🚫 Block login in GitHub Actions
    if os.getenv("GITHUB_ACTIONS") == "true":
        raise RuntimeError("❌ No valid OAuth token found in GitHub Secrets!")

    # 🔑 First-time login (LOCAL ONLY)
    flow = google_auth_oauthlib.flow.InstalledAppFlow.from_client_secrets_file(
        CLIENT_SECRET_FILE, SCOPES
    )

    credentials = flow.run_local_server(port=0)

    # 💾 Save token
    with open(TOKEN_FILE, "w", encoding="utf-8") as f:
        f.write(credentials.to_json())

    print("✅ Token saved to token.json")

    return credentials


def upload():
    print("===== START UPLOAD =====")

    # 🧪 Debug
    print("Files:", os.listdir("."))

    if not os.path.exists("video.mp4"):
        raise FileNotFoundError("❌ video.mp4 not found!")

    size = os.path.getsize("video.mp4")
    print("📦 File size:", size)

    if size < 1000:
        raise ValueError("❌ video.mp4 is too small!")

    # 📥 Dynamic title
    if os.path.exists("title.txt"):
        with open("title.txt", "r", encoding="utf-8") as f:
            title = f.read().strip()
    else:
        title = "Twitch VOD Upload"

    print("📝 Title:", title)

    credentials = get_credentials()

    youtube = googleapiclient.discovery.build(
        "youtube", "v3", credentials=credentials
    )

    # 🚀 Resumable upload (fixed chunk size for stability)
    media = googleapiclient.http.MediaFileUpload(
        "video.mp4",
        chunksize=10 * 1024 * 1024,  # 10MB chunks (better than -1)
        resumable=True
    )

    request = youtube.videos().insert(
        part="snippet,status",
        body={
            "snippet": {
                "title": title,
                "description": f"{title}\n\nAuto uploaded from Twitch",
                "tags": ["twitch", "vod"],
                "categoryId": "20"
            },
            "status": {
                "privacyStatus": "public",
                "selfDeclaredMadeForKids": False
            }
        },
        media_body=media
    )

    # 🔁 Upload with retry (important)
    response = None
    retry = 0

    while response is None:
        try:
            status, response = request.next_chunk()

            if status:
                print(f"📤 Upload progress: {int(status.progress() * 100)}%")

        except HttpError as e:
            retry += 1
            if retry > 5:
                raise RuntimeError(f"❌ Upload failed: {e}")

            print(f"⚠️ Retry upload... ({retry}/5)")
            time.sleep(5)

    print("✅ Upload complete!")
    print(response)


if __name__ == "__main__":
    upload()
