# Garmin Connect MCP Server

Connect your Garmin account to Claude AI — ask questions about your training, sleep, HRV, recovery, and fitness in plain language from any device including your phone.

Forked from [Taxuspt/garmin_mcp](https://github.com/Taxuspt/garmin_mcp) with added remote HTTP transport for cloud deployment and claude.ai mobile access.

---

## What You Can Ask Claude

- *"What was my sleep score last night and how does it compare to my 7-day average?"*
- *"Analyze my HRV trend over the last 2 weeks — am I overtraining?"*
- *"Should I do a hard workout today based on my recovery metrics?"*
- *"What's my training load this week vs. last week?"*
- *"Show me my VO2 max progression over the last 3 months"*
- *"Break down my last run — training effect, cadence, vertical oscillation"*
- *"Create a Z2 walking workout for 45 minutes and schedule it for tomorrow"*

---

## Tool Coverage (110+ tools)

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
| Courses | List, upload GPX, delete |
| Activity Analysis | FIT file parsing, Power Duration Curve (requires power meter) |

---

## Option A — Use the Hosted Server (Fastest)

If someone already has this deployed for you, just add the MCP URL to Claude.ai:

1. Open **claude.ai** in a desktop browser
2. Click your avatar → **Settings → Customize → Connectors**
3. Click **"+"** → **"Add custom connector"**
4. Enter the server URL and a name (e.g. `Garmin`)
5. Click **Add**

Once configured on desktop, it syncs automatically to the **Claude iOS/Android app**.

To use it in a conversation: click **"+"** at the bottom of the chat → **Connectors** → toggle Garmin on.

---

## Option B — Deploy Your Own (Full Control)

### Prerequisites

- Python 3.11+
- [Fly.io account](https://fly.io) (free tier is enough)
- [flyctl CLI](https://fly.io/docs/hands-on/install-flyctl/)
- Garmin Connect account

### 1. Fork and Clone

Fork this repo on GitHub, then:

```bash
git clone https://github.com/YOUR_USERNAME/garmin_mcp.git
cd garmin_mcp
```

### 2. Authenticate with Garmin Locally

This saves OAuth tokens to your machine and avoids MFA issues on first cloud boot:

```bash
python3 -m venv .venv
.venv/bin/pip install -e .
GARMIN_EMAIL=your@email.com GARMIN_PASSWORD=yourpassword .venv/bin/garmin-mcp-auth
```

Enter your MFA code if prompted. Tokens saved to `~/.garminconnect`.

### 3. Deploy to Fly.io

```bash
# Log in to Fly.io
fly auth login

# Create the app (choose your own name)
fly apps create your-garmin-mcp --org personal

# Create persistent volume for token storage
fly volumes create garmin_tokens --size 1 --region iad --app your-garmin-mcp

# Set Garmin credentials as encrypted secrets
fly secrets set \
  GARMIN_EMAIL=your@email.com \
  GARMIN_PASSWORD=yourpassword \
  --app your-garmin-mcp

# Upload pre-authenticated tokens (avoids MFA on first boot)
TOKEN_B64=$(cat ~/.garminconnect_base64)
fly secrets set GARMINTOKENS_BASE64_CONTENT="$TOKEN_B64" --app your-garmin-mcp

# Update the app name in fly.toml, then deploy
fly deploy --app your-garmin-mcp
```

Your server will be live at `https://your-garmin-mcp.fly.dev/mcp`.

### 4. Connect to Claude.ai

Follow the steps in **Option A** using your own URL.

---

## Local Development (Claude Code / Claude Desktop)

Run with stdio transport for local MCP clients:

```bash
GARMIN_EMAIL=your@email.com GARMIN_PASSWORD=yourpassword .venv/bin/garmin-mcp
```

For Claude Desktop, add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "garmin": {
      "command": "uvx",
      "args": ["--python", "3.12", "--from", "git+https://github.com/YOUR_USERNAME/garmin_mcp", "garmin-mcp"],
      "env": {
        "GARMIN_EMAIL": "your@email.com",
        "GARMIN_PASSWORD": "yourpassword"
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
| `GARMINTOKENS_BASE64_CONTENT` | Recommended | Pre-authenticated tokens as base64 string |
| `GARMINTOKENS` | No | Token directory path (default: `~/.garminconnect`) |
| `MCP_TRANSPORT` | No | `streamable-http` for cloud, `stdio` for local (default: `stdio`) |
| `PORT` | No | HTTP port (default: `8000`) |
| `GARMIN_IS_CN` | No | Set `true` for Garmin Connect China |
| `GARMIN_ENABLED_TOOLS` | No | Comma-separated allowlist of tools to register |
| `GARMIN_DISABLED_TOOLS` | No | Comma-separated denylist of tools to skip |

---

## Token Refresh

Tokens are valid for ~6 months and refresh automatically on each request. When they expire, re-run auth locally and update the secret:

```bash
GARMIN_EMAIL=your@email.com GARMIN_PASSWORD=yourpassword .venv/bin/garmin-mcp-auth
TOKEN_B64=$(cat ~/.garminconnect_base64)
fly secrets set GARMINTOKENS_BASE64_CONTENT="$TOKEN_B64" --app your-garmin-mcp
```

---

## Cost

Fly.io free tier includes 3 shared VMs (256MB RAM) and 160GB outbound data — more than enough for personal use.

Expected monthly cost: **$0**

Set a spending limit in [Fly.io billing](https://fly.io/dashboard/billing) to protect against unexpected charges.

---

## Troubleshooting

**Server not responding on first deploy**
Run the local auth step (Step 2 above) to pre-populate tokens before deploying.

**MFA required on every restart**
Set `GARMINTOKENS_BASE64_CONTENT` as a Fly.io secret (see Step 3).

**Token expired after ~6 months**
Re-run `garmin-mcp-auth` locally and update the secret (see Token Refresh above).

**Tool not available**
Check `GARMIN_ENABLED_TOOLS` / `GARMIN_DISABLED_TOOLS` env vars aren't filtering it out.

---

## License

MIT — based on [Taxuspt/garmin_mcp](https://github.com/Taxuspt/garmin_mcp)
