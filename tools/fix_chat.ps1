param(
  [string]$Model = "qwen2.5",
  [string]$OllamaModel = "qwen2.5:1.5b",
  [string]$MasterKey = "sk-1234"
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function DC {
  param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
  if (Test-Path ".\docker-compose.dev.yml") {
    & docker compose -f docker-compose.yml -f docker-compose.dev.yml @Args
  } else {
    & docker compose -f docker-compose.yml @Args
  }
}

function Tail-Logs {
  param([string]$svc, [int]$n = 200)
  try {
    DC logs "--tail=$n" $svc | Out-Host
  } catch {
    # fallback
    & docker logs "--tail=$n" "simon-$svc" 2>$null | Out-Host
  }
}

# 0) Docker preflight
docker info *> $null
if ($LASTEXITCODE -ne 0) { throw "Docker çalışmıyor. Docker Desktop açık mı?" }

# 1) Backup (geri dönüş)
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $repo "_backup\fix_chat_$ts"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

$filesToBackup = @(
  ".\litellm-config.yaml",
  ".\docker-compose.yml",
  ".\docker-compose.dev.yml",
  ".\apps\api\app\services\ai_router.py"
) | Where-Object { Test-Path $_ }

foreach ($f in $filesToBackup) {
  $dest = Join-Path $backupDir ($f.TrimStart(".\").Replace("\","__"))
  Copy-Item $f $dest -Force
}

Write-Host "Backup alindi: $backupDir" -ForegroundColor Green

# 2) Ollama model kontrol + indir
Write-Host "Ollama model kontrol: $OllamaModel" -ForegroundColor Cyan
$ollamaList = (& docker exec simon-ollama ollama list) 2>$null | Out-String
if ($ollamaList -notmatch [regex]::Escape($OllamaModel)) {
  Write-Host "Model yok -> indiriliyor..." -ForegroundColor Yellow
  & docker exec simon-ollama ollama pull $OllamaModel
} else {
  Write-Host "OK: Model hazir." -ForegroundColor Green
}

# 3) LiteLLM config: qwen2.5 için model stringini küçük modele sabitle (varsa)
$configPath = ".\litellm-config.yaml"
if (Test-Path $configPath) {
  $cfg = Get-Content $configPath -Raw
  $cfg2 = $cfg -replace "ollama/qwen2\.5(:[^\s""']+)?", "ollama/$OllamaModel"
  if ($cfg2 -ne $cfg) {
    Set-Content -Path $configPath -Value $cfg2 -Encoding UTF8
    Write-Host "OK: litellm-config.yaml guncellendi (ollama/$OllamaModel)" -ForegroundColor Green
  } else {
    Write-Host "INFO: litellm-config.yaml degismedi." -ForegroundColor DarkGray
  }
} else {
  Write-Host "WARN: litellm-config.yaml bulunamadi (atlandi)." -ForegroundColor Yellow
}

# 4) Restart (litellm + api)
Write-Host "Restart: litellm + api" -ForegroundColor Cyan
try {
  DC restart litellm api 2>$null
} catch {
  docker restart simon-litellm 2>$null | Out-Null
  docker restart simon-api 2>$null | Out-Null
}
Start-Sleep -Seconds 2

# 5) Health
Write-Host "TEST: /health" -ForegroundColor Cyan
$health = Invoke-RestMethod "http://localhost:8000/health"
Write-Host ("OK: /health -> " + $health.status) -ForegroundColor Green

# 6) LiteLLM models
Write-Host "TEST: LiteLLM /v1/models" -ForegroundColor Cyan
$models = Invoke-RestMethod -Method GET -Uri "http://localhost:4000/v1/models" -Headers @{ Authorization = "Bearer $MasterKey" }
$ids = @($models.data | ForEach-Object { $_.id })
Write-Host ("LiteLLM models: " + ($ids -join ", ")) -ForegroundColor Green
if ($ids -notcontains $Model) {
  Write-Host "WARN: '$Model' listede yok. litellm-config / model isimlerini kontrol et." -ForegroundColor Yellow
}

# 7) API chat smoke test
Write-Host "TEST: /api/chat (FREE $Model)" -ForegroundColor Cyan
$payload = @{
  messages = @(@{ role = "user"; content = "1+1=?" })
  model    = $Model
  key_mode = "free"
  stream   = $false
} | ConvertTo-Json -Depth 10 -Compress

try {
  $res = Invoke-RestMethod -Method POST -Uri "http://localhost:8000/api/chat" -ContentType "application/json" -Headers @{ Authorization = "Bearer $MasterKey" } -Body $payload
  $res | ConvertTo-Json -Depth 10
  Write-Host "OK: /api/chat calisiyor." -ForegroundColor Green
} catch {
  Write-Host "HATA: /api/chat failed. Loglar:" -ForegroundColor Red
  Tail-Logs -svc "api" -n 200
  Tail-Logs -svc "litellm" -n 200
  throw
}

Write-Host "BITTI. Geri donus backup: $backupDir" -ForegroundColor Green
