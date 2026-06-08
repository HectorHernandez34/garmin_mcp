# Health MCP Server — Garmin + Strava + Oura

Connect your health and fitness data to Claude AI. Ask questions about training, sleep, recovery, and performance in plain language — from any device including your phone.

Built on [Taxuspt/garmin_mcp](https://github.com/Taxuspt/garmin_mcp) with remote HTTP transport, Strava integration, and Oura Ring support added.

---

## What You Can Ask Claude

- *"Analyze my HRV trend over the last 2 weeks — am I overtraining?"*
- *"What was my sleep score last night vs. my 7-day average?"*
- *"Show me my VO2 max progression over the last 3 months"*
- *"Compare my Strava running volume this week vs. last week"*
- *"What's my Oura readiness score today and what's dragging it down?"*
- *"Break down my last run — training effect, cadence, vertical oscillation"*
- *"Should I do a hard workout today based on my recovery metrics?"*

---

## Services Integrated (143+ tools)

### Garmin Connect (110+ tools)
| Category | Tools |
|---|---|
| Sleep | Score, stages (deep/REM/light), respiration, SpO2, naps |
| HRV | Nightly RMSSD, 7-day rolling average, HRV status |
| Recovery | Body Battery, training readiness, recovery time |
| Training Load | CTL/ATL/TSB, acute/chronic ratio, training status |
| Activities | Details, splits, HR zones, weather, gear |
| Running Dynamics | Cadence, ground contact time, vertical oscillation |
| Fitness | VO2 max trend, fitness age, race predictions, PRs |
| Health | Resting HR, stress, steps, intensity minutes, SpO2 |
| Body | Weight, body fat %, muscle mass, BMI |
| Nutrition | Food logs, meals, hydration |
| Workouts | Create, schedule, and manage workouts |

### Strava (12 tools)
| Tool | Description |
|---|---|
| `get_strava_athlete` | Profile and account info |
| `get_strava_activities` | Recent activity list with metrics |
| `get_strava_activity` | Full detail of a specific activity |
| `get_strava_activity_streams` | HR, pace, power, cadence time-series |
| `get_strava_activity_laps` | Lap-by-lap breakdown |
| `get_strava_activity_zones` | HR and power zone distributions |
| `get_strava_stats` | Lifetime and recent training totals |
| `get_strava_zones` | Configured HR and power zones |
| `get_strava_starred_segments` | Your starred segments |
| `get_strava_activity_kudos` | Who kudos'd an activity |
| `get_strava_activity_comments` | Comments on an activity |
| `get_strava_latest_activity_comments` | Most recent activity + its comments |

### Oura Ring (11 tools)
| Tool | Description |
|---|---|
| `get_oura_personal_info` | Account info |
| `get_oura_sleep` | Nightly sleep sessions with stages |
| `get_oura_daily_sleep` | Daily sleep score + contributors |
| `get_oura_readiness` | Daily readiness score + contributors |
| `get_oura_activity` | Daily activity and calories |
| `get_oura_hrv` | Daily HRV average |
| `get_oura_stress` | Daytime stress and recovery |
| `get_oura_spo2` | Blood oxygen levels |
| `get_oura_resilience` | Resilience score and contributors |
| `get_oura_workouts` | Detected workout sessions |
| `get_oura_sessions` | Meditation and focus sessions |

### Apple Health
No native API exists. Workaround: enable **Settings → Privacy → Health → Strava → All Categories** on iPhone. Strava receives your Apple Health workouts and Claude reads them through the Strava tools above.

---

## Option A — Use a Hosted Server

If someone already has this deployed for you, add the MCP URL to Claude.ai:

1. Open **claude.ai** in a desktop browser
2. Click your avatar → **Settings → Customize → Connectors**
3. Click **"+"** → **"Add custom connector"**
4. Enter the server URL (e.g. `https://your-server.fly.dev/mcp`) and a name
5. Click **Add**

Once configured on desktop, it syncs automatically to the **Claude iOS/Android app**.

---

## Option B — Deploy Your Own

### Prerequisites

- Python 3.11+
- [Fly.io account](https://fly.io) (free tier is enough)
- [flyctl CLI](https://fly.io/docs/hands-on/install-flyctl/)
- Garmin Connect account
- Strava account (optional)
- Oura Ring with API access (optional)

### 1. Fork and Clone

```bash
git clone https://github.com/YOUR_USERNAME/garmin_mcp.git
cd garmin_mcp
```

### 2. Authenticate with Garmin Locally

```bash
python3 -m venv .venv
.venv/bin/pip install -e .
GARMIN_EMAIL=your@email.com GARMIN_PASSWORD=yourpassword .venv/bin/garmin-mcp-auth
```

Tokens saved to `~/.garminconnect`.

### 3. Get Strava Credentials (optional)

1. Create an app at [strava.com/settings/api](https://www.strava.com/settings/api)
2. Run the OAuth flow to get a refresh token with `activity:read_all,profile:read_all,read_all` scopes
3. Note your **Client ID**, **Client Secret**, and **Refresh Token**

### 4. Get Oura Token (optional)

1. Go to [cloud.ouraring.com/personal-access-tokens](https://cloud.ouraring.com/personal-access-tokens)
2. Create a Personal Access Token

### 5. Deploy to Fly.io

```bash
fly auth login

# Create app and volume
fly apps create your-garmin-mcp --org personal
fly volumes create garmin_tokens --size 1 --region iad --app your-garmin-mcp

# Set Garmin credentials
fly secrets set \
  GARMIN_EMAIL=your@email.com \
  GARMIN_PASSWORD=yourpassword \
  --app your-garmin-mcp

# Upload pre-authenticated tokens (avoids MFA on first boot)
TOKEN_B64=$(cat ~/.garminconnect_base64)
fly secrets set GARMINTOKENS_BASE64_CONTENT="$TOKEN_B64" --app your-garmin-mcp

# Set Strava credentials (optional)
fly secrets set \
  STRAVA_CLIENT_ID=your_client_id \
  STRAVA_CLIENT_SECRET=your_client_secret \
  STRAVA_ACCESS_TOKEN=your_access_token \
  STRAVA_REFRESH_TOKEN=your_refresh_token \
  --app your-garmin-mcp

# Set Oura token (optional)
fly secrets set OURA_ACCESS_TOKEN=your_oura_token --app your-garmin-mcp

# Update fly.toml — set your app name on line 1, then deploy
fly deploy --app your-garmin-mcp
```

Your server will be live at `https://your-garmin-mcp.fly.dev/mcp`.

> **Important — avoid charges:** The `fly.toml` in this repo is already configured with `auto_stop_machines = "stop"` and `min_machines_running = 0`. This means the server sleeps when not in use and wakes up automatically when Claude connects (~5 second cold start). Do **not** change these to `false`/`1` or the machine will run 24/7 and generate charges.

---

## Local Development

Run with stdio transport:

```bash
GARMIN_EMAIL=your@email.com GARMIN_PASSWORD=yourpassword .venv/bin/garmin-mcp
```

For Claude Desktop, add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "health": {
      "command": "uvx",
      "args": ["--python", "3.12", "--from", "git+https://github.com/YOUR_USERNAME/garmin_mcp", "garmin-mcp"],
      "env": {
        "GARMIN_EMAIL": "your@email.com",
        "GARMIN_PASSWORD": "yourpassword",
        "STRAVA_CLIENT_ID": "...",
        "STRAVA_CLIENT_SECRET": "...",
        "STRAVA_REFRESH_TOKEN": "...",
        "OURA_ACCESS_TOKEN": "..."
      }
    }
  }
}
```

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GARMIN_EMAIL` | Yes | Garmin Connect email |
| `GARMIN_PASSWORD` | Yes | Garmin Connect password |
| `GARMINTOKENS_BASE64_CONTENT` | Recommended | Pre-authenticated tokens as base64 |
| `STRAVA_CLIENT_ID` | Optional | Strava API client ID |
| `STRAVA_CLIENT_SECRET` | Optional | Strava API client secret |
| `STRAVA_ACCESS_TOKEN` | Optional | Strava OAuth access token |
| `STRAVA_REFRESH_TOKEN` | Optional | Strava OAuth refresh token |
| `OURA_ACCESS_TOKEN` | Optional | Oura Ring personal access token |
| `MCP_TRANSPORT` | No | `streamable-http` for cloud, `stdio` for local |
| `PORT` | No | HTTP port (default: `8000`) |
| `GARMIN_ENABLED_TOOLS` | No | Comma-separated allowlist of tools |
| `GARMIN_DISABLED_TOOLS` | No | Comma-separated denylist of tools |

Strava and Oura tools are silently skipped (not registered) if their credentials are not set.

---

## Token Refresh

**Garmin** tokens are valid ~6 months. When expired, re-run auth locally:

```bash
GARMIN_EMAIL=your@email.com GARMIN_PASSWORD=yourpassword .venv/bin/garmin-mcp-auth
TOKEN_B64=$(cat ~/.garminconnect_base64)
fly secrets set GARMINTOKENS_BASE64_CONTENT="$TOKEN_B64" --app your-garmin-mcp
```

**Strava** tokens refresh automatically — the server handles it on every request.

**Oura** personal access tokens do not expire.

---

## Cost

Fly.io free tier: 3 shared VMs (256MB RAM) + 160GB outbound data. More than enough for personal use.

Expected monthly cost: **$0** — set a [spending limit](https://fly.io/dashboard/billing) for peace of mind.

---

## Troubleshooting

**Server not responding on first deploy** — run the local auth step first to pre-populate Garmin tokens.

**Strava 401 errors** — your access token has the wrong scopes. Re-run OAuth with `activity:read_all,profile:read_all,read_all` scopes.

**Strava/Oura tools not showing** — credentials not set. Add the env vars and redeploy.

**Garmin token expired** — re-run `garmin-mcp-auth` and update `GARMINTOKENS_BASE64_CONTENT`.

**Claude shows old tool list** — remove and re-add the connector in Settings → Customize → Connectors.

---

## License

MIT — based on [Taxuspt/garmin_mcp](https://github.com/Taxuspt/garmin_mcp)
