# SIMON AI - PORT FIX SCRIPT
# Frontend 3001'e tasiniyor (Grafana 3000'de kalacak)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "SIMON AI - PORT FIX" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$FrontendDir = "C:\Users\ceyhu\Desktop\simonai\frontend"

# STEP 1: Stop existing node
Write-Host "[1/3] Node process durduruluyor..." -ForegroundColor Yellow
Get-Process -Name node -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "  [OK] Node stopped" -ForegroundColor Green
Write-Host ""

# STEP 2: Start on port 3001
Write-Host "[2/3] Frontend baslatiluyor (port 3001)..." -ForegroundColor Yellow
Set-Location $FrontendDir

$env:PORT = "3001"
$processInfo = Start-Process -FilePath "npm" -ArgumentList "run", "dev" -WorkingDirectory $FrontendDir -PassThru -WindowStyle Hidden

Write-Host "  -> Waiting 15 seconds..." -ForegroundColor Gray
Start-Sleep -Seconds 15

# STEP 3: Test
Write-Host "[3/3] Test ediliyor..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3001" -Method GET -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "  [OK] Frontend RUNNING on port 3001" -ForegroundColor Green
        $success = $true
    }
} catch {
    Write-Host "  [ERROR] Frontend failed to start" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    $success = $false
}

Write-Host ""

# SUMMARY
Write-Host "=====================================" -ForegroundColor Cyan
if ($success) {
    Write-Host "SUCCESS - FRONTEND HAZIR!" -ForegroundColor Green
} else {
    Write-Host "ERROR - MANUEL BASLATIN" -ForegroundColor Red
}
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Erisim:" -ForegroundColor Yellow
Write-Host "  Frontend:  http://localhost:3001" -ForegroundColor Cyan
Write-Host "  Backend:   http://localhost:8000" -ForegroundColor Gray
Write-Host "  Grafana:   http://localhost:3000" -ForegroundColor Gray
Write-Host ""

if ($success) {
    Write-Host "SIMDIKI ADIM:" -ForegroundColor Yellow
    Write-Host "  1. Tarayicida ac: http://localhost:3001" -ForegroundColor Cyan
    Write-Host "  2. Mesaj yaz: 'Hello Simon AI'" -ForegroundColor Gray
    Write-Host "  3. Test et!" -ForegroundColor Gray
} else {
    Write-Host "MANUEL BASLAT:" -ForegroundColor Yellow
    Write-Host "  cd C:\Users\ceyhu\Desktop\simonai\frontend" -ForegroundColor Gray
    Write-Host "  `$env:PORT='3001'; npm run dev" -ForegroundColor Gray
}

Write-Host ""
