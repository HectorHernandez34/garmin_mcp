# Health MCP Setup — Windows PowerShell
# Run as: powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"

function Step($msg)  { Write-Host "`n▶ $msg" -ForegroundColor Green }
function Info($msg)  { Write-Host "✓ $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "! $msg" -ForegroundColor Yellow }
function Die($msg)   { Write-Host "✗ $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      Health MCP — Setup Script           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── 1. uv ────────────────────────────────────────────────────────────────────
Step "Installing uv (Python package manager)"
if (Get-Command uv -ErrorAction SilentlyContinue) {
    Info "uv already installed: $(uv --version)"
} else {
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    $env:PATH += ";$env:USERPROFILE\.local\bin;$env:USERPROFILE\.cargo\bin"
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        Die "uv installation failed. Install manually: https://docs.astral.sh/uv/getting-started/installation/"
    }
    Info "uv installed: $(uv --version)"
}

# ── 2. Python 3.12 ───────────────────────────────────────────────────────────
Step "Installing Python 3.12"
$pythonList = uv python list 2>$null
if ($pythonList -match "3\.12") {
    Info "Python 3.12 already available"
} else {
    uv python install 3.12
    Info "Python 3.12 installed"
}

# ── 3. flyctl ────────────────────────────────────────────────────────────────
Step "Installing flyctl (Fly.io CLI)"
if (Get-Command fly -ErrorAction SilentlyContinue) {
    Info "flyctl already installed: $(fly version)"
} else {
    powershell -ExecutionPolicy ByPass -c "iwr https://fly.io/install.ps1 -useb | iex"
    $env:PATH += ";$env:USERPROFILE\.fly\bin"
    if (-not (Get-Command fly -ErrorAction SilentlyContinue)) {
        Die "flyctl installation failed. Install manually: https://fly.io/docs/hands-on/install-flyctl/"
    }
    Info "flyctl installed"
    Warn "Add flyctl to your PATH permanently:"
    Write-Host '  $env:PATH += ";$env:USERPROFILE\.fly\bin"'
}

# ── 4. Project dependencies ──────────────────────────────────────────────────
Step "Installing project dependencies"
uv sync --python 3.12
Info "Dependencies installed"

# ── Done ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Setup complete!                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Authenticate with Garmin (run once locally):"
Write-Host "     `$env:GARMIN_EMAIL='your@email.com'; `$env:GARMIN_PASSWORD='yourpassword'; uv run garmin-mcp-auth"
Write-Host ""
Write-Host "  2. Create your Fly.io app:"
Write-Host "     fly auth login"
Write-Host "     fly apps create your-health-mcp --org personal"
Write-Host "     fly volumes create garmin_tokens --size 1 --region iad --app your-health-mcp"
Write-Host ""
Write-Host "  3. Set your credentials:"
Write-Host "     fly secrets set GARMIN_EMAIL=your@email.com GARMIN_PASSWORD=yourpassword --app your-health-mcp"
Write-Host ""
Write-Host "  4. Deploy:"
Write-Host "     fly deploy --app your-health-mcp"
Write-Host ""
Write-Host "  5. Connect to Claude.ai:"
Write-Host "     Settings → Customize → Connectors → Add custom connector"
Write-Host "     URL: https://your-health-mcp.fly.dev/mcp"
Write-Host ""
