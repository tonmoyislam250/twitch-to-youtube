import os
import google_auth_oauthlib.flow
import googleapiclient.discovery
import googleapiclient.http

SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]

def upload():
    flow = google_auth_oauthlib.flow.InstalledAppFlow.from_client_secrets_file(
        "client_secret.json", SCOPES
    )
    if hasattr(flow, "run_local_server"):
        credentials = flow.run_local_server(port=0, open_browser=False)
    else:
        credentials = flow.run_console()

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