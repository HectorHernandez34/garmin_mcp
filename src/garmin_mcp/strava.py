"""Strava integration module for the Health MCP server."""

import os
import time
import requests

_client_id = None
_client_secret = None
_access_token = None
_refresh_token = None
_token_expiry = 0


def configure():
    global _client_id, _client_secret, _access_token, _refresh_token
    _client_id = os.getenv("STRAVA_CLIENT_ID")
    _client_secret = os.getenv("STRAVA_CLIENT_SECRET")
    _access_token = os.getenv("STRAVA_ACCESS_TOKEN")
    _refresh_token = os.getenv("STRAVA_REFRESH_TOKEN")


def _get_token() -> str:
    """Return a valid access token, refreshing if needed."""
    global _access_token, _refresh_token, _token_expiry

    if _token_expiry and time.time() < _token_expiry - 60:
        return _access_token

    resp = requests.post("https://www.strava.com/oauth/token", data={
        "client_id": _client_id,
        "client_secret": _client_secret,
        "refresh_token": _refresh_token,
        "grant_type": "refresh_token",
    })
    resp.raise_for_status()
    data = resp.json()
    _access_token = data["access_token"]
    _refresh_token = data["refresh_token"]
    _token_expiry = data["expires_at"]
    return _access_token


def _headers():
    return {"Authorization": f"Bearer {_get_token()}"}


def _get(path: str, params: dict = None):
    resp = requests.get(f"https://www.strava.com/api/v3{path}", headers=_headers(), params=params or {})
    resp.raise_for_status()
    return resp.json()


def register_tools(app):

    @app.tool()
    def get_strava_athlete() -> dict:
        """Get the authenticated athlete's Strava profile."""
        return _get("/athlete")

    @app.tool()
    def get_strava_activities(per_page: int = 30, page: int = 1) -> list:
        """Get recent Strava activities. Returns up to per_page activities (max 100)."""
        return _get("/athlete/activities", {"per_page": min(per_page, 100), "page": page})

    @app.tool()
    def get_strava_activity(activity_id: int) -> dict:
        """Get full details of a specific Strava activity by ID."""
        return _get(f"/activities/{activity_id}")

    @app.tool()
    def get_strava_activity_streams(activity_id: int) -> dict:
        """Get time-series streams (HR, pace, power, cadence, altitude) for an activity."""
        keys = "time,heartrate,velocity_smooth,cadence,watts,altitude,distance"
        return _get(f"/activities/{activity_id}/streams", {"keys": keys, "key_by_type": True})

    @app.tool()
    def get_strava_activity_laps(activity_id: int) -> list:
        """Get lap-by-lap breakdown for a Strava activity."""
        return _get(f"/activities/{activity_id}/laps")

    @app.tool()
    def get_strava_activity_zones(activity_id: int) -> list:
        """Get heart rate and power zone distributions for a Strava activity."""
        return _get(f"/activities/{activity_id}/zones")

    @app.tool()
    def get_strava_stats() -> dict:
        """Get lifetime and recent training statistics for the authenticated athlete."""
        athlete = _get("/athlete")
        return _get(f"/athletes/{athlete['id']}/stats")

    @app.tool()
    def get_strava_zones() -> dict:
        """Get the athlete's configured heart rate and power zones."""
        return _get("/athlete/zones")

    @app.tool()
    def get_strava_starred_segments() -> list:
        """Get the athlete's starred Strava segments."""
        return _get("/segments/starred")

    @app.tool()
    def get_strava_activity_kudos(activity_id: int) -> list:
        """Get list of athletes who kudos'd a specific activity."""
        return _get(f"/activities/{activity_id}/kudos")

    return app
