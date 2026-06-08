"""Oura Ring integration module for the Health MCP server."""

import os
from datetime import date, timedelta
import requests

_access_token = None
_BASE = "https://api.ouraring.com/v2/usercollection"


def configure():
    global _access_token
    _access_token = os.getenv("OURA_ACCESS_TOKEN")


def _headers():
    return {"Authorization": f"Bearer {_access_token}"}


def _get(path: str, params: dict = None):
    resp = requests.get(f"{_BASE}{path}", headers=_headers(), params=params or {})
    resp.raise_for_status()
    return resp.json()


def _date_range(days: int = 7):
    end = date.today().isoformat()
    start = (date.today() - timedelta(days=days)).isoformat()
    return start, end


def register_tools(app):

    @app.tool()
    def get_oura_personal_info() -> dict:
        """Get the Oura user's personal profile info."""
        resp = requests.get("https://api.ouraring.com/v2/usercollection/personal_info", headers=_headers())
        resp.raise_for_status()
        return resp.json()

    @app.tool()
    def get_oura_sleep(days: int = 7) -> dict:
        """Get Oura sleep data for the last N days. Includes sleep stages, HRV, efficiency, score."""
        start, end = _date_range(days)
        return _get("/sleep", {"start_date": start, "end_date": end})

    @app.tool()
    def get_oura_daily_sleep(days: int = 7) -> dict:
        """Get Oura daily sleep score summaries for the last N days."""
        start, end = _date_range(days)
        return _get("/daily_sleep", {"start_date": start, "end_date": end})

    @app.tool()
    def get_oura_readiness(days: int = 7) -> dict:
        """Get Oura daily readiness scores for the last N days. Includes contributing factors."""
        start, end = _date_range(days)
        return _get("/daily_readiness", {"start_date": start, "end_date": end})

    @app.tool()
    def get_oura_activity(days: int = 7) -> dict:
        """Get Oura daily activity data for the last N days. Includes steps, calories, active time."""
        start, end = _date_range(days)
        return _get("/daily_activity", {"start_date": start, "end_date": end})

    @app.tool()
    def get_oura_hrv(days: int = 7) -> dict:
        """Get Oura nightly HRV (RMSSD) data for the last N days."""
        start, end = _date_range(days)
        return _get("/heartrate", {"start_datetime": f"{start}T00:00:00", "end_datetime": f"{end}T23:59:59"})

    @app.tool()
    def get_oura_stress(days: int = 7) -> dict:
        """Get Oura daily stress scores for the last N days."""
        start, end = _date_range(days)
        return _get("/daily_stress", {"start_date": start, "end_date": end})

    @app.tool()
    def get_oura_spo2(days: int = 7) -> dict:
        """Get Oura nightly SpO2 (blood oxygen) data for the last N days."""
        start, end = _date_range(days)
        return _get("/daily_spo2", {"start_date": start, "end_date": end})

    @app.tool()
    def get_oura_resilience(days: int = 7) -> dict:
        """Get Oura daily resilience scores for the last N days."""
        start, end = _date_range(days)
        return _get("/daily_resilience", {"start_date": start, "end_date": end})

    @app.tool()
    def get_oura_workouts(days: int = 30) -> dict:
        """Get Oura-detected workout sessions for the last N days."""
        start, end = _date_range(days)
        return _get("/workout", {"start_date": start, "end_date": end})

    @app.tool()
    def get_oura_sessions(days: int = 7) -> dict:
        """Get Oura meditation and breathing sessions for the last N days."""
        start, end = _date_range(days)
        return _get("/session", {"start_date": start, "end_date": end})

    return app
