# Simon AI - LiteLLM Endpoint Fix & Test
# Tek komut: .\fix-and-test.ps1
$ErrorActionPreference = "Stop"

Write-Host "`n🔧 Simon AI - LiteLLM Endpoint Otomatik Düzeltme`n" -ForegroundColor Cyan

# 1) Dizin kontrolü
$repoRoot = "C:\Users\ceyhu\Downloads\simon-ai-faz3-complete\simon-ai-agent-studio"
if (-not (Test-Path $repoRoot)) {
    Write-Host "❌ Repo bulunamadı: $repoRoot" -ForegroundColor Red
    exit 1
}

Set-Location $repoRoot
Write-Host "✅ Dizin: $repoRoot" -ForegroundColor Green

# 2) Dosya yedekleme
$targetFile = "apps\api\agent_studio_service.py"
$backupFile = "apps\api\agent_studio_service.py.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

if (-not (Test-Path $targetFile)) {
    Write-Host "❌ Dosya bulunamadı: $targetFile" -ForegroundColor Red
    exit 1
}

Copy-Item $targetFile $backupFile -Force
Write-Host "✅ Yedek: $backupFile" -ForegroundColor Green

# 3) Patch uygula
$content = Get-Content $targetFile -Raw -Encoding UTF8
$originalContent = $content

# Satır 161: /chat/completions → /v1/chat/completions
$pattern = '(\s+url = f"\{self\.litellm_base_url\})/chat/completions"'
$replacement = '$1/v1/chat/completions"'

$content = $content -replace $pattern, $replacement

if ($content -eq $originalContent) {
    Write-Host "⚠️  Patch zaten uygulanmış veya pattern bulunamadı" -ForegroundColor Yellow
} else {
    Set-Content $targetFile -Value $content -Encoding UTF8 -NoNewline
    Write-Host "✅ Patch uygulandı: /v1/chat/completions" -ForegroundColor Green
}

# 4) Docker Compose down
Write-Host "`n🛑 Container'lar durduruluyor..." -ForegroundColor Yellow
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.agentstudio.override.yml down 2>&1 | Out-Null
Write-Host "✅ Container'lar durduruldu" -ForegroundColor Green

# 5) Docker Compose up (rebuild)
Write-Host "`n🚀 Container'lar başlatılıyor (rebuild)..." -ForegroundColor Yellow
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.agentstudio.override.yml up -d --build 2>&1 | Out-Host

# 6) Healthcheck bekleme
Write-Host "`n⏳ API hazır olması bekleniyor (max 40 saniye)..." -ForegroundColor Yellow
$apiReady = $false
for ($i = 1; $i -le 40; $i++) {
    try {
        $health = Invoke-RestMethod -Method Get -Uri "http://localhost:8000/health" -TimeoutSec 3
        Write-Host "✅ API hazır! ($i/40)" -ForegroundColor Green
        $apiReady = $true
        break
    } catch {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    }
}

if (-not $apiReady) {
    Write-Host "`n❌ API 40 saniyede hazır olmadı. Loglar:" -ForegroundColor Red
    docker logs simon-api --tail=30
    exit 1
}

# 7) Test çalıştır
Write-Host "`n🧪 Test başlatılıyor...`n" -ForegroundColor Cyan
if (Test-Path "tools\agent-studio-test.ps1") {
    & "tools\agent-studio-test.ps1"
} else {
    Write-Host "⚠️  Test scripti bulunamadı, manuel test:" -ForegroundColor Yellow
    Write-Host "  Invoke-RestMethod -Method Post -Uri http://localhost:8000/api/agent/sessions -ContentType 'application/json' -Body '{`"model`":`"qwen2.5`"}'"
}

Write-Host "`n✅ İşlem tamamlandı!" -ForegroundColor Green
Write-Host "📋 Yedek dosya: $backupFile" -ForegroundColor Gray
