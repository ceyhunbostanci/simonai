# tools\fix-agent-studio-router.ps1
$ErrorActionPreference = "Stop"

function Write-FileUtf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path $path -Parent
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$mainPath = Join-Path $RepoRoot "apps\api\main.py"
if (!(Test-Path $mainPath)) { throw "main.py bulunamadı: $mainPath" }

$main = Get-Content $mainPath -Raw

# 1) import satırına agent_studio ekle (varsa genişlet, yoksa yeni ekle)
if ($main -match "from\s+app\.routers\s+import\s+([^\r\n]+)") {
  $full = $Matches[0]
  $mods = $Matches[1].Trim()

  if ($mods -notmatch "\bagent_studio\b") {
    $newMods = $mods + ", agent_studio"
    $main = $main -replace [regex]::Escape($full), ("from app.routers import " + $newMods)
  }
} else {
  # dosyada bu import yoksa en üste ekle
  $main = "from app.routers import agent_studio`n" + $main
}

# 2) include_router satırını ekle (yoksa)
if ($main -notmatch "include_router\(\s*agent_studio\.router") {
  # mevcut include_router bloklarının hemen altına ekle (en güvenlisi dosya sonuna yakın eklemek)
  $insert = 'app.include_router(agent_studio.router, prefix="/api", tags=["Agent Studio"])'

  # "app = FastAPI(" satırından sonra ilk include_router'ların olduğu bölgeyi bulmaya çalış
  if ($main -match "app\s*=\s*FastAPI\([^\)]*\)\s*") {
    # zaten include_router'lar varsa onların sonrasına ekleyeceğiz: en basit yöntem dosyanın sonuna eklemek
    $main = $main.TrimEnd() + "`n" + $insert + "`n"
  } else {
    $main = $main.TrimEnd() + "`n" + $insert + "`n"
  }
}

Write-FileUtf8NoBom $mainPath $main

Write-Host "✅ main.py güncellendi. Aşağıda doğrulama:"
Select-String -Path $mainPath -Pattern "from app.routers import", "include_router\(" |
  Select-Object LineNumber, Line | Format-Table -AutoSize | Out-String -Width 300 | Write-Host
