#!/usr/bin/env bash
# Health MCP Setup — installs all dependencies and prepares for deployment
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}!${NC} $1"; }
step()    { echo -e "\n${GREEN}▶ $1${NC}"; }
die()     { echo -e "${RED}✗ $1${NC}"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║      Health MCP — Setup Script           ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. uv (manages Python + dependencies) ────────────────────────────────────
step "Installing uv (Python package manager)"
if command -v uv &>/dev/null; then
    info "uv already installed: $(uv --version)"
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    if ! command -v uv &>/dev/null; then
        die "uv installation failed. Install manually: https://docs.astral.sh/uv/getting-started/installation/"
    fi
    info "uv installed: $(uv --version)"
fi

# ── 2. Python 3.12 ───────────────────────────────────────────────────────────
step "Installing Python 3.12"
if uv python list 2>/dev/null | grep -q "3\.12"; then
    info "Python 3.12 already available"
else
    uv python install 3.12
    info "Python 3.12 installed"
fi

# ── 3. flyctl ────────────────────────────────────────────────────────────────
step "Installing flyctl (Fly.io CLI)"
if command -v fly &>/dev/null || command -v flyctl &>/dev/null; then
    FLY_VER=$(fly version 2>/dev/null || flyctl version 2>/dev/null | head -1)
    info "flyctl already installed: $FLY_VER"
else
    curl -L https://fly.io/install.sh | sh
    export PATH="$HOME/.fly/bin:$PATH"
    if ! command -v fly &>/dev/null && ! command -v flyctl &>/dev/null; then
        die "flyctl installation failed. Install manually: https://fly.io/docs/hands-on/install-flyctl/"
    fi
    info "flyctl installed"
    echo ""
    warn "Add flyctl to your PATH permanently by adding this to your ~/.bashrc or ~/.zshrc:"
    echo '  export PATH="$HOME/.fly/bin:$PATH"'
fi

# ── 4. Project dependencies ──────────────────────────────────────────────────
step "Installing project dependencies"
uv sync --python 3.12
info "Dependencies installed"

# ── 5. PATH reminder ─────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.fly/bin:$PATH"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║         Setup complete!                  ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo ""
echo "  1. Authenticate with Garmin (run once locally):"
echo "     GARMIN_EMAIL=your@email.com GARMIN_PASSWORD=yourpassword uv run garmin-mcp-auth"
echo ""
echo "  2. Create your Fly.io app:"
echo "     fly auth login"
echo "     fly apps create your-health-mcp --org personal"
echo "     fly volumes create garmin_tokens --size 1 --region iad --app your-health-mcp"
echo ""
echo "  3. Set your credentials as encrypted secrets:"
echo "     fly secrets set GARMIN_EMAIL=your@email.com GARMIN_PASSWORD=yourpassword --app your-health-mcp"
echo "     fly secrets set STRAVA_CLIENT_ID=x STRAVA_CLIENT_SECRET=x STRAVA_REFRESH_TOKEN=x --app your-health-mcp"
echo "     fly secrets set OURA_ACCESS_TOKEN=x --app your-health-mcp"
echo ""
echo "  4. Upload Garmin tokens and deploy:"
echo '     fly secrets set GARMINTOKENS_BASE64_CONTENT="$(cat ~/.garminconnect_base64)" --app your-health-mcp'
echo "     fly deploy --app your-health-mcp"
echo ""
echo "  5. Connect to Claude.ai:"
echo "     Settings → Customize → Connectors → Add custom connector"
echo "     URL: https://your-health-mcp.fly.dev/mcp"
echo ""
