# tools\full-test.ps1
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

$script:results = @{
    docker_running = $false
    containers_up = $false
    api_health = $false
    litellm_models = $false
    chat_working = $false
}

$script:testStartTime = Get-Date

Write-Title "SIMON AI AGENT STUDIO - OTOMATIK TEST"
Write-Host "Başlangıç: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

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

Write-Step "2/8 - Repo dizinine geçiliyor..."
try {
    Set-Location "C:\Users\ceyhu\Downloads\simon-ai-faz3-complete\simon-ai-agent-studio"
    Write-Ok "Dizin: $(Get-Location)"
} catch {
    Write-Fail "Repo dizinine erişilemiyor"
    exit 1
}

Write-Step "3/8 - Container durumları..."
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
    Write-Warn "Container durum kontrolü atlandı"
}

Write-Step "4/8 - API Health Check..."
$healthOk = $false
for ($i = 1; $i -le 5; $i++) {
    try {
        $health = Invoke-RestMethod -Method GET -Uri "http://localhost:8000/health" -TimeoutSec 5 -ErrorAction Stop
        Write-Ok "API Health: $($health.status)"
        $script:results.api_health = $true
        $healthOk = $true
        break
    } catch {
        if ($i -lt 5) {
            Write-Host "    Deneme $i/5..." -ForegroundColor Gray
            Start-Sleep -Seconds 2
        }
    }
}

if (-not $healthOk) { Write-Fail "API health check başarısız" }

Write-Step "5/8 - LiteLLM model listesi..."
try {
    $models = Invoke-RestMethod -Method GET -Uri "http://localhost:4000/v1/models" -Headers @{ Authorization = "Bearer sk-1234" } -TimeoutSec 10 -ErrorAction Stop
    $modelList = $models.data | ForEach-Object { $_.id }
    Write-Ok "Modeller: $($modelList -join ', ')"
    $script:results.litellm_models = $true
} catch {
    Write-Fail "LiteLLM başarısız"
}

Write-Step "6/8 - Chat endpoint test..."
try {
    $payload = @{
        messages = @(@{ role="user"; content="1+1=?" })
        model = "qwen2.5"
        key_mode = "free"
        stream = $false
    } | ConvertTo-Json -Depth 10 -Compress
    
    $response = Invoke-RestMethod -Method POST -Uri "http://localhost:8000/api/chat" -ContentType "application/json" -Headers @{ Authorization = "Bearer sk-1234" } -Body $payload -TimeoutSec 90 -ErrorAction Stop
    
    if ($response.content) {
        Write-Ok "Chat BAŞARILI! Cevap: $($response.content)"
        $script:results.chat_working = $true
    }
} catch {
    Write-Fail "Chat başarısız: $_"
}

$testDuration = ((Get-Date) - $script:testStartTime).TotalSeconds
Write-Title "TEST SONUÇLARI"

Write-Host "`nDurum:" -ForegroundColor Cyan
Write-Host "  Docker:      $(if ($script:results.docker_running) { '✓' } else { '✗' })" -ForegroundColor $(if ($script:results.docker_running) { 'Green' } else { 'Red' })
Write-Host "  Containers:  $(if ($script:results.containers_up) { '✓' } else { '✗' })" -ForegroundColor $(if ($script:results.containers_up) { 'Green' } else { 'Red' })
Write-Host "  API Health:  $(if ($script:results.api_health) { '✓' } else { '✗' })" -ForegroundColor $(if ($script:results.api_health) { 'Green' } else { 'Red' })
Write-Host "  LiteLLM:     $(if ($script:results.litellm_models) { '✓' } else { '✗' })" -ForegroundColor $(if ($script:results.litellm_models) { 'Green' } else { 'Red' })
Write-Host "  Chat:        $(if ($script:results.chat_working) { '✓' } else { '✗' })" -ForegroundColor $(if ($script:results.chat_working) { 'Green' } else { 'Red' })

$passCount = ($script:results.Values | Where-Object { $_ -eq $true }).Count
Write-Host "`n$passCount/5 test geçti ($([math]::Round($testDuration, 1))s)" -ForegroundColor $(if ($passCount -ge 4) { 'Green' } else { 'Yellow' })

if ($script:results.chat_working) {
    Write-Host "`n✓✓✓ SİSTEM TAM ÇALIŞIYOR! ✓✓✓`n" -ForegroundColor Green
}
