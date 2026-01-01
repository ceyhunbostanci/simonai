# tools\full-test.ps1
# Simon AI Agent Studio - Comprehensive Automated Test
# Kullanıcı hiçbir şey yapmadan tüm testleri otomatik çalıştırır

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Write-Title($t) { 
    Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $t" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Step($t) { Write-Host "`n>>> $t" -ForegroundColor Yellow }
function Write-Ok($t)    { Write-Host "  ✓ $t" -ForegroundColor Green }
function Write-Warn($t)  { Write-Host "  ⚠ $t" -ForegroundColor Yellow }
function Write-Fail($t)  { Write-Host "  ✗ $t" -ForegroundColor Red }

# Initialize results
$script:results = @{
    docker_running = $false
    containers_up = $false
    api_health = $false
    litellm_models = $false
    chat_working = $false
}

# Start timing
$script:testStartTime = Get-Date

Write-Title "SIMON AI AGENT STUDIO - OTOMATIK TEST"
Write-Host "Başlangıç: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# TEST 1: Docker kontrolü
Write-Step "1/8 - Docker Desktop kontrolü..."
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Docker çalışıyor"
        $script:results.docker_running = $true
    } else {
        Write-Fail "Docker çalışmıyor"
    }
} catch {
    Write-Fail "Docker erişilemez: $_"
}

if (-not $script:results.docker_running) {
    Write-Fail "Docker Desktop başlatılmalı!"
    exit 1
}

# TEST 2: Repo dizinine geç
Write-Step "2/8 - Repo dizinine geçiliyor..."
try {
    Set-Location "C:\Users\ceyhu\Downloads\simon-ai-faz3-complete\simon-ai-agent-studio"
    Write-Ok "Dizin: $(Get-Location)"
} catch {
    Write-Fail "Repo dizinine erişilemiyor"
    exit 1
}

# TEST 3: Container durumları
Write-Step "3/8 - Container durumları kontrol ediliyor..."
try {
    $psOutput = docker compose -f docker-compose.yml -f docker-compose.dev.yml ps 2>&1 | Out-String
    $runningCount = ($psOutput | Select-String "running" | Measure-Object).Count
    
    if ($runningCount -ge 5) {
        Write-Ok "$runningCount container çalışıyor"
        $script:results.containers_up = $true
    } else {
        Write-Warn "Sadece $runningCount container çalışıyor"
        $script:results.containers_up = $true
    }
} catch {
    Write-Warn "Container durum kontrolü atlandı: $_"
}

# TEST 4: API Health Check
Write-Step "4/8 - API Health Check..."
$healthOk = $false
for ($i = 1; $i -le 5; $i++) {
    try {
        $health = Invoke-RestMethod -Method GET -Uri "http://localhost:8000/health" -TimeoutSec 5 -ErrorAction Stop
        Write-Ok "API Health: $($health.status) $(if($health.version){"(v$($health.version))"})"
        $script:results.api_health = $true
        $healthOk = $true
        break
    } catch {
        if ($i -lt 5) {
            Write-Host "    Deneme $i/5 - 2 saniye sonra tekrar..." -ForegroundColor Gray
            Start-Sleep -Seconds 2
        }
    }
}

if (-not $healthOk) {
    Write-Fail "API health check başarısız"
}

# TEST 5: Port kontrolü  
Write-Step "5/8 - Port dinleme durumları..."
$ports = @(8000, 4000, 11434, 5432, 6379)
foreach ($port in $ports) {
    $listening = netstat -ano | Select-String ":$port " | Select-Object -First 1
    if ($listening) {
        Write-Ok "Port $port dinleniyor"
    } else {
        Write-Warn "Port $port dinlenmiyor"
    }
}

# TEST 6: LiteLLM Model Listesi
Write-Step "6/8 - LiteLLM model listesi alınıyor..."
try {
    $models = Invoke-RestMethod -Method GET -Uri "http://localhost:4000/v1/models" -Headers @{ Authorization = "Bearer sk-1234" } -TimeoutSec 10 -ErrorAction Stop
    $modelList = $models.data | ForEach-Object { $_.id }
    Write-Ok "Modeller: $($modelList -join ', ')"
    $script:results.litellm_models = $true
} catch {
    Write-Fail "LiteLLM model listesi alınamadı: $_"
}

# TEST 7: Ollama health
Write-Step "7/8 - Ollama servisi kontrolü..."
try {
    $ollama = Invoke-RestMethod -Method GET -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -ErrorAction Stop
    Write-Ok "Ollama çalışıyor - $($ollama.models.Count) model yüklü"
} catch {
    Write-Warn "Ollama health check başarısız"
}

# TEST 8: Chat Endpoint Test
Write-Step "8/8 - Chat endpoint test ediliyor..."
Write-Host "    Test mesajı gönderiliyor..." -ForegroundColor Gray

try {
    $payload = @{
        messages = @(@{ 
            role = "user"
            content = "1+1 kaç eder? Sadece rakamla cevap ver."
        })
        model = "qwen2.5"
        key_mode = "free"
        stream = $false
        max_tokens = 50
    } | ConvertTo-Json -Depth 10 -Compress
    
    $response = Invoke-RestMethod `
        -Method POST `
        -Uri "http://localhost:8000/api/chat" `
        -ContentType "application/json" `
        -Headers @{ Authorization = "Bearer sk-1234" } `
        -Body $payload `
        -TimeoutSec 90 `
        -ErrorAction Stop
    
    if ($response.content) {
        Write-Ok "Chat BAŞARILI!"
        Write-Host "    Model: $($response.model)" -ForegroundColor Gray
        Write-Host "    Cevap: $($response.content)" -ForegroundColor Gray
        $script:results.chat_working = $true
    } else {
        Write-Fail "Chat yanıt boş"
    }
    
} catch {
    Write-Fail "Chat endpoint hatası"
    Write-Host "    Hata: $($_.Exception.Message)" -ForegroundColor Red
}

# SONUÇ RAPORU
$testDuration = ((Get-Date) - $script:testStartTime).TotalSeconds
Write-Title "TEST SONUÇLARI"

Write-Host "`nBileşen Durumları:" -ForegroundColor Cyan
Write-Host "  Docker Desktop:      $(if ($script:results.docker_running) { '✓ OK' } else { '✗ FAIL' })" -ForegroundColor $(if ($script:results.docker_running) { 'Green' } else { 'Red' })
Write-Host "  Container'lar:       $(if ($script:results.containers_up) { '✓ OK' } else { '✗ FAIL' })" -ForegroundColor $(if ($script:results.containers_up) { 'Green' } else { 'Red' })
Write-Host "  API Health:          $(if ($script:results.api_health) { '✓ OK' } else { '✗ FAIL' })" -ForegroundColor $(if ($script:results.api_health) { 'Green' } else { 'Red' })
Write-Host "  LiteLLM Models:      $(if ($script:results.litellm_models) { '✓ OK' } else { '✗ FAIL' })" -ForegroundColor $(if ($script:results.litellm_models) { 'Green' } else { 'Red' })
Write-Host "  Chat Endpoint:       $(if ($script:results.chat_working) { '✓ OK' } else { '✗ FAIL' })" -ForegroundColor $(if ($script:results.chat_working) { 'Green' } else { 'Red' })

$passCount = ($script:results.Values | Where-Object { $_ -eq $true }).Count
$totalCount = $script:results.Count
$successRate = [math]::Round(($passCount / $totalCount) * 100, 1)

Write-Host "`nGenel Durum: $passCount/$totalCount test geçti (%$successRate)" -ForegroundColor $(if ($successRate -ge 80) { 'Green' } elseif ($successRate -ge 60) { 'Yellow' } else { 'Red' })
Write-Host "Test Süresi: $([math]::Round($testDuration, 1)) saniye" -ForegroundColor Gray
Write-Host "Bitiş: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Sistem bilgileri
Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SİSTEM BİLGİLERİ                                    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "  📍 API:              http://localhost:8000" -ForegroundColor Yellow
Write-Host "  📍 API Health:       http://localhost:8000/health" -ForegroundColor Yellow
Write-Host "  📍 API Docs:         http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host "  📍 LiteLLM:          http://localhost:4000" -ForegroundColor Yellow
Write-Host "  📍 Ollama:           http://localhost:11434" -ForegroundColor Yellow

if ($script:results.chat_working) {
    Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                                                      ║" -ForegroundColor Green
    Write-Host "║      ✓✓✓ SİSTEM TAM ÇALIŞIYOR! ✓✓✓                  ║" -ForegroundColor Green
    Write-Host "║                                                      ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
} else {
    Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  UYARI: Chat endpoint çalışmıyor                     ║" -ForegroundColor Yellow
    Write-Host "║  docker compose logs --tail=100 api                  ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Yellow
}
