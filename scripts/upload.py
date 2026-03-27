import json
import os

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
import google_auth_oauthlib.flow
import googleapiclient.discovery
import googleapiclient.http

SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]
CLIENT_SECRET_FILE = "client_secret.json"
TOKEN_FILE = "token.json"


def get_credentials():
    credentials = None

    token_json = os.getenv("YOUTUBE_TOKEN_JSON")
    if token_json:
        credentials = Credentials.from_authorized_user_info(
            json.loads(token_json), SCOPES
        )
    elif os.path.exists(TOKEN_FILE):
        credentials = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

    if credentials and credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())

    if credentials and credentials.valid:
        return credentials

    if os.getenv("GITHUB_ACTIONS") == "true":
        raise RuntimeError(
            "No valid OAuth token found in GitHub Actions. Set secret YOUTUBE_TOKEN_JSON."
        )

    flow = google_auth_oauthlib.flow.InstalledAppFlow.from_client_secrets_file(
        CLIENT_SECRET_FILE, SCOPES
    )
    if hasattr(flow, "run_local_server"):
        credentials = flow.run_local_server(port=0, open_browser=False)
    else:
        credentials = flow.run_console()

    with open(TOKEN_FILE, "w", encoding="utf-8") as f:
        f.write(credentials.to_json())

    return credentials

def upload():
    credentials = get_credentials()

    youtube = googleapiclient.discovery.build("youtube", "v3", credentials=credentials)

    request = youtube.videos().insert(
        part="snippet,status",
        body={
            "snippet": {
                "title": "Twitch VOD Upload",
                "description": "Auto uploaded",
                "tags": ["twitch", "vod"],
                "categoryId": "20"
            },
            "status": {"privacyStatus": "public"}
        },
        media_body=googleapiclient.http.MediaFileUpload("video.mp4")
    )

    response = request.execute()
    print(response)

if __name__ == "__main__":
    upload()