# ============================================================
# Hikayati - One-Click Story Production
# ============================================================
# Run from project root:
#   .\tools\produce_all_stories.ps1                  # all 4 stories
#   .\tools\produce_all_stories.ps1 -Slug juha_market  # one story
#   .\tools\produce_all_stories.ps1 -SkipPublish     # generate only, don't publish
#   .\tools\produce_all_stories.ps1 -Force           # regenerate even if exists
# ============================================================

[CmdletBinding()]
param(
    [string]$Slug = "",
    [switch]$SkipPublish,
    [switch]$Force,
    [switch]$SkipImages,
    [switch]$SkipAudio,
    [string]$Model = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
Set-Location $ProjectRoot

# Force UTF-8 output for Arabic
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Section($title) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Write-Ok($msg)   { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [ERR]  $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "  [INFO] $msg" -ForegroundColor Gray }

# 1) Check Python
Write-Section "1. Checking Python"
try {
    $pyVersion = python --version 2>&1
    Write-Ok "$pyVersion"
} catch {
    Write-Err "Python not found. Install Python 3.10+ from python.org"
    exit 1
}

# 2) Install dependencies
Write-Section "2. Installing Python dependencies"
$packages = @("requests", "pyyaml", "python-dotenv")
foreach ($pkg in $packages) {
    Write-Host "  - Installing $pkg ..." -NoNewline
    pip install --quiet --upgrade $pkg 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

# 3) Check .env
Write-Section "3. Checking .env file"
$envPath = Join-Path $ProjectRoot ".env"
if (-not (Test-Path $envPath)) {
    Write-Err ".env file not found at: $envPath"
    exit 1
}
$envContent = Get-Content $envPath -Raw -Encoding UTF8
if ($envContent -notmatch "POLLINATIONS_IMAGE_API_KEY") {
    Write-Err "POLLINATIONS_IMAGE_API_KEY missing in .env"
    exit 1
}
if ($envContent -notmatch "ELEVENLABS_API_KEY") {
    Write-Err "ELEVENLABS_API_KEY missing in .env"
    exit 1
}
Write-Ok "All required keys present"

# 4) Generate stories
Write-Section "4. Generating stories (images + audio)"
$pyArgs = @("tools\generate_stories.py")
if ($Slug)       { $pyArgs += "--slug"; $pyArgs += $Slug }
if ($Force)      { $pyArgs += "--force" }
if ($SkipImages) { $pyArgs += "--skip-images" }
if ($SkipAudio)  { $pyArgs += "--skip-audio" }
if ($Model)      { $pyArgs += "--model"; $pyArgs += $Model }

Write-Info "Running: python $($pyArgs -join ' ')"
Write-Host ""
python @pyArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Warn "Generation finished with errors. You can re-run safely (will skip existing files)."
}

# 5) Publish to assets
if (-not $SkipPublish) {
    Write-Section "5. Publishing stories to assets/"
    $stories = if ($Slug) { @($Slug) } else { @("juha_market", "antar_courage", "sulayman_ant", "yunus_whale") }

    foreach ($s in $stories) {
        Write-Host ""
        Write-Host "  >> Publishing: $s" -ForegroundColor Cyan
        try {
            & "$PSScriptRoot\publish_pack.ps1" -Slug $s
        } catch {
            Write-Warn "publish_pack failed for $s. Try manually:"
            Write-Warn "  .\tools\publish_pack.ps1 -Slug $s"
        }
    }
}

Write-Section "Done"
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Review generated images in:" -ForegroundColor Gray
Write-Host "       content_studio\public_library\packs\<slug>\images\" -ForegroundColor Gray
Write-Host "    2. Listen to audio in:" -ForegroundColor Gray
Write-Host "       content_studio\public_library\packs\<slug>\audio\" -ForegroundColor Gray
Write-Host "    3. To regenerate a single bad scene:" -ForegroundColor Gray
Write-Host "       Delete the bad file then re-run this script" -ForegroundColor Gray
Write-Host "    4. Build APK to test in app:" -ForegroundColor Gray
Write-Host "       flutter build apk --release" -ForegroundColor Gray
Write-Host ""
