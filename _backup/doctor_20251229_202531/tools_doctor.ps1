# tools\doctor.ps1
# Simon AI Agent Studio - One-click Doctor (Windows PowerShell)
# Goal: run from anywhere, auto-fix common issues, restart stack, smoke-test /api/chat.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Title($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Write-Ok($t)    { Write-Host "OK:  $t" -ForegroundColor Green }
function Write-Warn($t)  { Write-Host "WARN: $t" -ForegroundColor Yellow }
function Write-Fail($t)  { Write-Host "FAIL: $t" -ForegroundColor Red }

function Get-RepoRoot {
  $root = Split-Path -Parent $PSScriptRoot
  if (-not (Test-Path (Join-Path $root "docker-compose.yml"))) {
    throw "Repo root bulunamadı. doctor.ps1 'tools' altında olmalı ve repo kökünde docker-compose.yml olmalı."
  }
  return $root
}

function Ensure-Dir($p) {
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

function Backup-Files($backupDir, $repoRoot) {
  Ensure-Dir $backupDir
  $items = @(
    "docker-compose.yml",
    "docker-compose.dev.yml",
    "litellm-config.yaml",
    "tools\fix_chat.ps1",
    "tools\doctor.ps1",
    "apps\api\app\services\ai_router.py",
    "apps\api\app\database\connection.py",
    "apps\api\app\database.py"
  )
  foreach ($rel in $items) {
    $src = Join-Path $repoRoot $rel
    if (Test-Path $src) {
      $dst = Join-Path $backupDir ($rel -replace "[\\/:*?""<>|]", "_")
      Copy-Item $src $dst -Force
    }
  }
}

function Patch-ComposeDev-Network($repoRoot) {
  $p = Join-Path $repoRoot "docker-compose.dev.yml"
  if (-not (Test-Path $p)) { return }

  $txt = Get-Content $p -Raw
  $uses = ($txt -match "simon-network")
  $defined = ($txt -match "(?m)^\s*simon-network\s*:\s*$")

  if ($uses -and (-not $defined)) {
    if ($txt -match "(?m)^\s*networks\s*:\s*$") {
      $txt = [regex]::Replace(
        $txt,
        "(?m)^(?<indent>\s*)networks\s*:\s*$",
        '${indent}networks:' + "`n" + '${indent}  simon-network:' + "`n" + '${indent}    driver: bridge'
      )
    } else {
      $txt = $txt.TrimEnd() + "`n`nnetworks:`n  simon-network:`n    driver: bridge`n"
    }
    Set-Content -Path $p -Value $txt -Encoding UTF8
    Write-Ok "docker-compose.dev.yml: simon-network tanımı eklendi."
  }
}

function Patch-SQLAlchemy-Select1($repoRoot) {
  $candidates = @(
    Join-Path $repoRoot "apps\api\app\database\connection.py",
    Join-Path $repoRoot "apps\api\app\database.py"
  ) | Where-Object { Test-Path $_ }

  foreach ($file in $candidates) {
    $txt = Get-Content $file -Raw
    $changed = $false

    $needsText = ($txt -match "SELECT 1") -and (-not ($txt -match "(?m)^\s*from\s+sqlalchemy\s+import\s+.*\btext\b"))
    if ($needsText) {
      if ($txt -match "(?m)^\s*from\s+sqlalchemy\s+import\s+(.+)$") {
        $txt = [regex]::Replace($txt, "(?m)^(\s*from\s+sqlalchemy\s+import\s+.+)$", '$1, text', 1)
      } else {
        $txt = "from sqlalchemy import text`n" + $txt
      }
      $changed = $true
    }

    $before = $txt
    $txt = $txt -replace "execute\(\s*['""]SELECT\s+1['""]\s*\)", "execute(text('SELECT 1'))"
    $txt = $txt -replace "execute\(\s*['""]SELECT\s+1;?['""]\s*\)", "execute(text('SELECT 1'))"
    if ($txt -ne $before) { $changed = $true }

    if ($changed) {
      Set-Content -Path $file -Value $txt -Encoding UTF8
      Write-Ok ("SQLAlchemy SELECT 1 patch: " + (Split-Path $file -Leaf))
    }
  }
}

function Get-MasterKey($repoRoot) {
  $envPath = Join-Path $repoRoot ".env"
  if (Test-Path $envPath) {
    $lines = Get-Content $envPath
    foreach ($line in $lines) {
      if ($line -match "^\s*LITELLM_MASTER_KEY\s*=\s*(.+)\s*$") {
        return $Matches[1].Trim().Trim("'").Trim('"')
      }
      if ($line -match "^\s*MASTER_KEY\s*=\s*(.+)\s*$") {
        return $Matches[1].Trim().Trim("'").Trim('"')
      }
    }
  }
  return "sk-1234"
}

function Compose-Args($repoRoot) {
  $base = Join-Path $repoRoot "docker-compose.yml"
  $dev  = Join-Path $repoRoot "docker-compose.dev.yml"
  if (Test-Path $dev) { return @("-f", $base, "-f", $dev) }
  return @("-f", $base)
}

function Dc($args) {
  & docker compose @args
  if ($LASTEXITCODE -ne 0) { throw "docker compose komutu hata verdi." }
}

function Wait-Http($url, $tries = 20, $sleepSec = 2) {
  for ($i=1; $i -le $tries; $i++) {
    try {
      $r = Invoke-RestMethod -Method GET -Uri $url -TimeoutSec 10
      return $r
    } catch {
      Start-Sleep -Seconds $sleepSec
    }
  }
  throw "HTTP bekleme zaman aşımı: $url"
}

function Get-LiteLLM-Models($masterKey) {
  $hdr = @{ Authorization = "Bearer $masterKey" }
  $r = Invoke-RestMethod -Method GET -Uri "http://localhost:4000/v1/models" -Headers $hdr -TimeoutSec 20
  return @($r.data | ForEach-Object { $_.id })
}

function Test-Chat($masterKey, $model) {
  $hdr = @{ Authorization = "Bearer $masterKey" }
  $payload = @{
    messages = @(@{ role="user"; content="1+1=?" })
    model    = $model
    key_mode = "free"
    stream   = $false
  } | ConvertTo-Json -Depth 10 -Compress

  return Invoke-RestMethod -Method POST -Uri "http://localhost:8000/api/chat" -ContentType "application/json" -Headers $hdr -Body $payload -TimeoutSec 60
}

function Tail-Logs($composeArgs, $svc, $n=200) {
  Write-Host "`n--- logs: $svc (tail=$n) ---" -ForegroundColor Yellow
  & docker compose @composeArgs logs ("--tail=$n") $svc
}

$backupDir = "(not-set)"

try {
  Write-Title "ÖN KONTROL"
  docker info *> $null
  Write-Ok "Docker OK"

  $repoRoot = Get-RepoRoot
  Set-Location $repoRoot
  Ensure-Dir (Join-Path $repoRoot "tools")

  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $backupDir = Join-Path $repoRoot ("_backup\doctor_" + $ts)
  Backup-Files $backupDir $repoRoot
  Write-Ok "Backup alındı: $backupDir"

  Write-Title "PATCH"
  Patch-ComposeDev-Network $repoRoot
  Patch-SQLAlchemy-Select1 $repoRoot

  Write-Title "RESTART"
  $composeArgs = Compose-Args $repoRoot
  Dc ($composeArgs + @("up","-d","--build"))
  Write-Ok "docker compose up -d --build"

  Write-Title "HEALTH BEKLE"
  $health = Wait-Http "http://localhost:8000/health" 25 2
  Write-Ok ("/health: " + $health.status)

  Write-Title "LITELLM MODELLER"
  $masterKey = Get-MasterKey $repoRoot
  $models = Get-LiteLLM-Models $masterKey
  Write-Ok ("LiteLLM models: " + ($models -join ", "))

  $chosen = $null
  if ($models -contains "qwen2.5") { $chosen = "qwen2.5" }
  elseif ($models.Count -gt 0) { $chosen = $models[0] }
  else { throw "LiteLLM model listesi boş." }

  Write-Title "SMOKE TEST /api/chat"
  $res = Test-Chat $masterKey $chosen
  Write-Ok ("PASS (model=$chosen) cevap=" + ($res.content | Out-String).Trim())

  Write-Title "SONUÇ"
  Write-Ok "Doctor PASS"
  Write-Host "Geri dönüş için backup: $backupDir" -ForegroundColor Green
  exit 0
}
catch {
  Write-Title "SONUÇ"
  Write-Fail ($_.Exception.Message)

  try {
    $repoRoot2 = $null
    try { $repoRoot2 = Get-RepoRoot } catch { }
    if ($repoRoot2) {
      $composeArgs2 = Compose-Args $repoRoot2
      Write-Warn "Hızlı kontrol komutları:"
      Write-Host "  docker compose ps" -ForegroundColor Yellow
      Write-Host "  docker compose logs --tail=200 api" -ForegroundColor Yellow
      Write-Host "  docker compose logs --tail=200 litellm" -ForegroundColor Yellow
      Tail-Logs $composeArgs2 "api" 200
      Tail-Logs $composeArgs2 "litellm" 200
    }
  } catch { }

  Write-Host "Geri dönüş için backup: $backupDir" -ForegroundColor Yellow
  exit 1
}
