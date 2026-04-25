# ============================================================
# Hikayati - Story Pack Publisher
# ============================================================
# Usage:
#   .\tools\publish_pack.ps1 -Slug layla_wolf
#   .\tools\publish_pack.ps1 -Slug layla_wolf -AllowMissingAudio
#   .\tools\publish_pack.ps1 -Slug layla_wolf -DryRun
#
# Pipeline:
#   1. Read content_studio/public_library/packs/<slug>/story_pack.yaml
#   2. Validate images and audio
#   3. Copy assets to assets/public_library/<slug>/
#   4. Generate assets/public_library/<slug>/story_pack.json
#   5. Update assets/public_library/catalog.json
#   6. Update pubspec.yaml
#   7. Print readiness report
# ============================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [switch]$AllowMissingAudio,
    [switch]$DryRun,

    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Section($title) {
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
}
function Write-Ok($msg)   { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [ERR]  $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "  [INFO] $msg" -ForegroundColor Gray }

# Minimal YAML reader for the story_pack.yaml shape we use.
function ConvertFrom-StoryPackYaml {
    param([string]$Path)
    $lines = Get-Content -Path $Path -Encoding UTF8
    $result = [ordered]@{
        scenes = New-Object System.Collections.ArrayList
    }
    $currentScene = $null
    $inScenes = $false
    foreach ($raw in $lines) {
        if ($raw -match '^\s*#') { continue }
        if ([string]::IsNullOrWhiteSpace($raw)) { continue }

        if ($raw -match '^scenes:\s*$') {
            $inScenes = $true
            continue
        }

        if ($inScenes) {
            if ($raw -match '^\s*-\s+scene:\s*(\d+)\s*$') {
                if ($currentScene) { [void]$result.scenes.Add($currentScene) }
                $currentScene = [ordered]@{ scene = [int]$Matches[1] }
                continue
            }
            if ($raw -match '^\s+(text|image|audio):\s*(.+?)\s*$' -and $currentScene) {
                $key = $Matches[1]
                $val = $Matches[2].Trim('"').Trim("'")
                $currentScene[$key] = $val
                continue
            }
            continue
        }

        if ($raw -match '^([a-zA-Z_]+):\s*(.+?)\s*$') {
            $key = $Matches[1]
            $val = $Matches[2].Trim('"').Trim("'")
            if ($val -match '^\d+$') { $val = [int]$val }
            $result[$key] = $val
        }
    }
    if ($currentScene) { [void]$result.scenes.Add($currentScene) }
    return $result
}

# Paths
$packDir       = Join-Path $ProjectRoot "content_studio\public_library\packs\$Slug"
$packYaml      = Join-Path $packDir "story_pack.yaml"
$packImagesDir = Join-Path $packDir "images"
$packAudioDir  = Join-Path $packDir "audio"

$assetsRoot     = Join-Path $ProjectRoot "assets\public_library"
$storyAssetsDir = Join-Path $assetsRoot $Slug
$storyImagesDir = Join-Path $storyAssetsDir "images"
$storyAudioDir  = Join-Path $storyAssetsDir "audio"
$storyJsonPath  = Join-Path $storyAssetsDir "story_pack.json"
$catalogPath    = Join-Path $assetsRoot "catalog.json"
$pubspecPath    = Join-Path $ProjectRoot "pubspec.yaml"

Write-Section "Hikayati Story Pack Publisher - slug: $Slug"
Write-Info "Project: $ProjectRoot"
if ($DryRun) { Write-Warn "DRY RUN - no files will be written" }

# 1) Validate pack structure
Write-Section "1. Validate pack structure"
if (-not (Test-Path $packYaml)) {
    Write-Err "story_pack.yaml not found: $packYaml"
    exit 1
}
Write-Ok "story_pack.yaml found"

$pack = ConvertFrom-StoryPackYaml -Path $packYaml
foreach ($req in @('slug','id','title','price_credits','cover')) {
    if (-not $pack.Contains($req)) {
        Write-Err "missing required field in YAML: $req"
        exit 1
    }
}
if ($pack.scenes.Count -eq 0) {
    Write-Err "no scenes in story_pack.yaml"
    exit 1
}
Write-Ok "required fields present | scenes: $($pack.scenes.Count)"

# 2) Validate assets
Write-Section "2. Validate assets"
$missingImages = @()
$missingAudio  = @()
foreach ($scene in $pack.scenes) {
    $imgPath = Join-Path $packImagesDir $scene.image
    if (-not (Test-Path $imgPath)) { $missingImages += $scene.image }

    if ($scene.Contains('audio') -and $scene.audio) {
        $audPath = Join-Path $packAudioDir $scene.audio
        if (-not (Test-Path $audPath)) { $missingAudio += $scene.audio }
    } else {
        $missingAudio += "scene_$($scene.scene) (no audio key)"
    }
}

if ($missingImages.Count -gt 0) {
    Write-Err "missing images: $($missingImages -join ', ')"
    exit 1
}
Write-Ok "all images ($($pack.scenes.Count)) present"

$audioReady = ($missingAudio.Count -eq 0)
if (-not $audioReady) {
    if ($AllowMissingAudio) {
        Write-Warn "audio missing ($($missingAudio.Count)) - continuing with -AllowMissingAudio"
        foreach ($m in $missingAudio) { Write-Info "  - $m" }
    } else {
        Write-Err "audio missing ($($missingAudio.Count)). Use -AllowMissingAudio to publish without audio."
        foreach ($m in $missingAudio) { Write-Info "  - $m" }
        exit 1
    }
} else {
    Write-Ok "all audio ($($pack.scenes.Count)) present"
}

# 3) Copy assets
Write-Section "3. Copy assets to assets/"
if (-not $DryRun) {
    New-Item -ItemType Directory -Force -Path $storyImagesDir | Out-Null
    New-Item -ItemType Directory -Force -Path $storyAudioDir  | Out-Null
}

$copiedImages = 0
foreach ($scene in $pack.scenes) {
    $src = Join-Path $packImagesDir $scene.image
    $dst = Join-Path $storyImagesDir $scene.image
    if (-not $DryRun) { Copy-Item -Path $src -Destination $dst -Force }
    $copiedImages++
}
Write-Ok "images copied: $copiedImages"

$copiedAudio = 0
foreach ($scene in $pack.scenes) {
    if ($scene.Contains('audio') -and $scene.audio) {
        $src = Join-Path $packAudioDir $scene.audio
        if (Test-Path $src) {
            $dst = Join-Path $storyAudioDir $scene.audio
            if (-not $DryRun) { Copy-Item -Path $src -Destination $dst -Force }
            $copiedAudio++
        }
    }
}
Write-Ok "audio copied: $copiedAudio"

# 4) Generate story_pack.json
Write-Section "4. Generate story_pack.json"

$assetPrefix = "assets/public_library/$Slug"
$scenesJson  = New-Object System.Collections.ArrayList
foreach ($scene in $pack.scenes) {
    $audioUrl = ""
    if ($scene.Contains('audio') -and $scene.audio) {
        $audioFile = Join-Path $storyAudioDir $scene.audio
        if (Test-Path $audioFile) {
            $audioUrl = "$assetPrefix/audio/$($scene.audio)"
        }
    }
    [void]$scenesJson.Add([ordered]@{
        scene     = $scene.scene
        text      = $scene.text
        imageUrl  = "$assetPrefix/images/$($scene.image)"
        audio_url = $audioUrl
    })
}

$storyJson = [ordered]@{
    id              = $pack.id
    slug            = $pack.slug
    title           = $pack.title
    summary         = $pack.summary
    cover           = "$assetPrefix/images/$($pack.cover)"
    price_credits   = $pack.price_credits
    category        = $pack.category
    voice_type      = if ($pack.Contains('voice_type')) { $pack.voice_type } else { "fable" }
    is_static_local = $true
    scenes_json     = $scenesJson
}

$storyJsonText = $storyJson | ConvertTo-Json -Depth 10
if (-not $DryRun) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($storyJsonPath, $storyJsonText, $utf8NoBom)
}
Write-Ok "story_pack.json -> $storyJsonPath"

# 5) Update catalog.json
Write-Section "5. Update catalog.json"

$catalog = [ordered]@{
    version    = 1
    updated_at = (Get-Date -Format "yyyy-MM-dd")
    stories    = New-Object System.Collections.ArrayList
}
if (Test-Path $catalogPath) {
    try {
        $existing = Get-Content -Path $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($existing.stories) {
            foreach ($s in $existing.stories) {
                if ($s.slug -ne $Slug) {
                    [void]$catalog.stories.Add([ordered]@{
                        id        = $s.id
                        slug      = $s.slug
                        pack_path = $s.pack_path
                    })
                }
            }
        }
    } catch {
        Write-Warn "existing catalog corrupt - rebuilding"
    }
}
[void]$catalog.stories.Add([ordered]@{
    id        = $pack.id
    slug      = $pack.slug
    pack_path = "$assetPrefix/story_pack.json"
})
$catalog.updated_at = (Get-Date -Format "yyyy-MM-dd")

$catalogText = $catalog | ConvertTo-Json -Depth 5
if (-not $DryRun) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($catalogPath, $catalogText, $utf8NoBom)
}
Write-Ok "catalog.json now contains $($catalog.stories.Count) story(ies)"

# 6) Update pubspec.yaml
Write-Section "6. Update pubspec.yaml"

$pubLines = Get-Content -Path $pubspecPath -Encoding UTF8
$needed = @(
    "    - assets/public_library/catalog.json",
    "    - $assetPrefix/story_pack.json",
    "    - $assetPrefix/images/",
    "    - $assetPrefix/audio/"
)
$pubText = $pubLines -join "`n"
$additions = @()
foreach ($line in $needed) {
    if ($pubText -notmatch [regex]::Escape($line.Trim())) {
        $additions += $line
    }
}

if ($additions.Count -eq 0) {
    Write-Ok "pubspec.yaml already up to date"
} else {
    Write-Info "will add:"
    foreach ($a in $additions) { Write-Info "  $a" }
    if (-not $DryRun) {
        $newLines = New-Object System.Collections.ArrayList
        $injected = $false
        foreach ($l in $pubLines) {
            [void]$newLines.Add($l)
            if (-not $injected -and $l -match '^\s*assets:\s*$') {
                foreach ($a in $additions) { [void]$newLines.Add($a) }
                $injected = $true
            }
        }
        if (-not $injected) {
            Write-Err "could not find 'assets:' section in pubspec.yaml"
            exit 1
        }
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($pubspecPath, ($newLines -join "`n"), $utf8NoBom)
        Write-Ok "pubspec.yaml updated (+$($additions.Count) line(s))"
    }
}

# 7) Final report
Write-Section "Readiness report"
Write-Host "  slug          : $Slug" -ForegroundColor White
Write-Host "  id            : $($pack.id)" -ForegroundColor White
Write-Host "  title         : $($pack.title)" -ForegroundColor White
Write-Host "  scenes        : $($pack.scenes.Count)" -ForegroundColor White
Write-Host "  images        : $copiedImages copied" -ForegroundColor White
$audioLabel = "$copiedAudio copied"
if (-not $audioReady) { $audioLabel = $audioLabel + " (incomplete)" }
Write-Host "  audio         : $audioLabel" -ForegroundColor White
Write-Host "  story_pack    : $storyJsonPath" -ForegroundColor White
Write-Host "  catalog       : $catalogPath" -ForegroundColor White
Write-Host ""

if ($audioReady) {
    Write-Host "  [READY] story is fully published (text + images + audio)" -ForegroundColor Green
} else {
    Write-Host "  [PARTIAL] published without audio - re-run after generating mp3" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  Next:" -ForegroundColor Cyan
Write-Host "    flutter pub get" -ForegroundColor White
Write-Host "    flutter analyze" -ForegroundColor White
Write-Host "    flutter run" -ForegroundColor White
Write-Host ""
