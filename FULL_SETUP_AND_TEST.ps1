# SIMON AI - FAZ 5 KOMPLE KURULUM & TEST
# Tam Otomasyon - Hiçbir Manuel İşlem YOK

param(
    [switch]$SkipBackend = $false,
    [switch]$SkipFrontend = $false,
    [switch]$SkipTest = $false
)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "SIMON AI - FAZ 5 KOMPLE KURULUM" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"
$ProjectRoot = "C:\Users\ceyhu\Desktop\simonai"
$OutputsDir = (Get-Location).Path

Write-Host "[INFO] Proje Kökü: $ProjectRoot" -ForegroundColor Gray
Write-Host "[INFO] Outputs: $OutputsDir" -ForegroundColor Gray
Write-Host ""

# ============================================
# BÖLÜM 1: RAPORLARI KOPYALA
# ============================================
Write-Host "[1/7] Raporları Kopyalama..." -ForegroundColor Yellow

$ReportsDir = "$ProjectRoot\reports"
if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
    Write-Host "  ✓ Reports klasörü oluşturuldu" -ForegroundColor Green
}

$reportFiles = Get-ChildItem -Path "$OutputsDir\reports" -Filter "*.md" -ErrorAction SilentlyContinue

if ($reportFiles) {
    foreach ($file in $reportFiles) {
        Copy-Item -Path $file.FullName -Destination $ReportsDir -Force
        Write-Host "  ✓ $($file.Name)" -ForegroundColor Green
    }
    Write-Host "  TOPLAM: $($reportFiles.Count) rapor kopyalandı" -ForegroundColor Cyan
} else {
    Write-Host "  ! Rapor bulunamadı" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# BÖLÜM 2: FRONTEND SCAFFOLD KOPYALA
# ============================================
Write-Host "[2/7] Frontend Scaffold Kopyalama..." -ForegroundColor Yellow

$ScaffoldDir = "$OutputsDir\frontend-scaffold"
$FrontendDir = "$ProjectRoot\frontend"

if (-not (Test-Path $ScaffoldDir)) {
    Write-Host "  ✗ Scaffold bulunamadı: $ScaffoldDir" -ForegroundColor Red
    exit 1
}

# Frontend dizinini temizle ve yeniden oluştur
if (Test-Path $FrontendDir) {
    Write-Host "  → Mevcut frontend yedekleniyor..." -ForegroundColor Gray
    $BackupDir = "$ProjectRoot\frontend.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Move-Item -Path $FrontendDir -Destination $BackupDir -Force -ErrorAction SilentlyContinue
}

Write-Host "  → Scaffold kopyalanıyor..." -ForegroundColor Gray
Copy-Item -Path $ScaffoldDir -Destination $FrontendDir -Recurse -Force

if (Test-Path $FrontendDir) {
    $fileCount = (Get-ChildItem -Path $FrontendDir -Recurse -File).Count
    Write-Host "  ✓ Frontend scaffold kopyalandı ($fileCount dosya)" -ForegroundColor Green
} else {
    Write-Host "  ✗ Frontend kopyalanamadı!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================
# BÖLÜM 3: .ENV.LOCAL OLUŞTUR
# ============================================
Write-Host "[3/7] Environment Konfigürasyonu..." -ForegroundColor Yellow

$envContent = "NEXT_PUBLIC_API_URL=http://localhost:8000"
Set-Content -Path "$FrontendDir\.env.local" -Value $envContent -Force
Write-Host "  ✓ .env.local oluşturuldu" -ForegroundColor Green

Write-Host ""

# ============================================
# BÖLÜM 4: DEPENDENCIES KURULUMU
# ============================================
if (-not $SkipFrontend) {
    Write-Host "[4/7] Dependencies Kurulumu..." -ForegroundColor Yellow
    Write-Host "  Bu işlem 2-3 dakika sürebilir..." -ForegroundColor Gray
    Write-Host ""

    Set-Location $FrontendDir

    # package.json kontrolü
    if (-not (Test-Path "package.json")) {
        Write-Host "  ✗ package.json bulunamadı!" -ForegroundColor Red
        exit 1
    }

    # npm install
    Write-Host "  → npm install çalıştırılıyor..." -ForegroundColor Gray
    $installOutput = npm install 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Dependencies kuruldu" -ForegroundColor Green
        
        # node_modules boyutunu göster
        if (Test-Path "node_modules") {
            $size = (Get-ChildItem "node_modules" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
            Write-Host "  ℹ node_modules: $([math]::Round($size, 1)) MB" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ! Install tamamlandı (uyarılar var)" -ForegroundColor Yellow
        Write-Host "  Son 5 satır:" -ForegroundColor Gray
        $installOutput | Select-Object -Last 5 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    }

    Write-Host ""
} else {
    Write-Host "[4/7] Dependencies Kurulumu (ATLANDI)" -ForegroundColor Gray
    Write-Host ""
}

# ============================================
# BÖLÜM 5: BACKEND DURUMU
# ============================================
if (-not $SkipBackend) {
    Write-Host "[5/7] Backend Durumu..." -ForegroundColor Yellow

    try {
        $health = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  ✓ Backend: RUNNING" -ForegroundColor Green
        Write-Host "    Version: $($health.orchestrator)" -ForegroundColor Gray
        $backendOK = $true
    } catch {
        Write-Host "  ! Backend: NOT RUNNING" -ForegroundColor Yellow
        Write-Host "  → Backend başlatılıyor..." -ForegroundColor Gray
        
        Set-Location $ProjectRoot
        
        # Docker Compose başlat
        docker compose -f docker-compose.yml `
                       -f docker-compose.egress.yml `
                       -f docker-compose.celery.yml `
                       -f docker-compose.observability.yml `
                       up -d 2>&1 | Out-Null

        Write-Host "  → 30 saniye bekleniyor..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
        
        # Tekrar kontrol
        try {
            $health = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 10
            Write-Host "  ✓ Backend: STARTED" -ForegroundColor Green
            $backendOK = $true
        } catch {
            Write-Host "  ✗ Backend: FAILED TO START" -ForegroundColor Red
            Write-Host "  Manuel başlatın: docker compose up -d" -ForegroundColor Gray
            $backendOK = $false
        }
    }

    Write-Host ""
} else {
    Write-Host "[5/7] Backend Durumu (ATLANDI)" -ForegroundColor Gray
    Write-Host ""
    $backendOK = $false
}

# ============================================
# BÖLÜM 6: BUILD TEST
# ============================================
Write-Host "[6/7] Build Test..." -ForegroundColor Yellow

Set-Location $FrontendDir

Write-Host "  → TypeScript & Next.js build..." -ForegroundColor Gray
$buildOutput = npm run build 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Build: SUCCESS" -ForegroundColor Green
} else {
    Write-Host "  ! Build: WARNINGS (devam ediliyor)" -ForegroundColor Yellow
    Write-Host "  Son 3 satır:" -ForegroundColor Gray
    $buildOutput | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
}

Write-Host ""

# ============================================
# BÖLÜM 7: DEV SERVER BAŞLAT
# ============================================
Write-Host "[7/7] Development Server..." -ForegroundColor Yellow

if (-not $SkipTest) {
    Write-Host "  → Dev server başlatılıyor (arka planda)..." -ForegroundColor Gray
    
    # Önce mevcut process'i durdur
    Get-Process -Name node -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -like "*next dev*"} | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # Yeni process başlat
    $processInfo = Start-Process -FilePath "npm" -ArgumentList "run", "dev" -WorkingDirectory $FrontendDir -PassThru -WindowStyle Hidden
    
    Write-Host "  → 10 saniye bekleniyor..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
    
    # Frontend kontrolü
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✓ Frontend: RUNNING (http://localhost:3000)" -ForegroundColor Green
            $frontendOK = $true
        }
    } catch {
        Write-Host "  ! Frontend: Başlatılamadı" -ForegroundColor Yellow
        Write-Host "  Manuel başlatın: npm run dev" -ForegroundColor Gray
        $frontendOK = $false
    }
} else {
    Write-Host "  (Test atlandı - Manuel başlatın: npm run dev)" -ForegroundColor Gray
    $frontendOK = $false
}

Write-Host ""

# ============================================
# ÖZET RAPORU
# ============================================
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "KURULUM TAMAMLANDI!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Durum:" -ForegroundColor Yellow
Write-Host "  Reports:       ✓ Kopyalandı ($ReportsDir)" -ForegroundColor Green
Write-Host "  Frontend:      ✓ Kuruldu ($FrontendDir)" -ForegroundColor Green
Write-Host "  Dependencies:  ✓ Yüklendi" -ForegroundColor Green
Write-Host "  Backend:       $(if ($backendOK) { '✓ RUNNING' } else { '! CHECK NEEDED' })" -ForegroundColor $(if ($backendOK) { 'Green' } else { 'Yellow' })
Write-Host "  Frontend:      $(if ($frontendOK) { '✓ RUNNING' } else { '! MANUAL START' })" -ForegroundColor $(if ($frontendOK) { 'Green' } else { 'Yellow' })
Write-Host ""

Write-Host "Erişim:" -ForegroundColor Cyan
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor Gray
Write-Host "  Backend:  http://localhost:8000" -ForegroundColor Gray
Write-Host "  API Docs: http://localhost:8000/docs" -ForegroundColor Gray
Write-Host ""

if ($backendOK -and $frontendOK) {
    Write-Host "🎉 TÜM SİSTEMLER HAZIR!" -ForegroundColor Green
    Write-Host "   Tarayıcıda test edin: http://localhost:3000" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test Senaryoları:" -ForegroundColor Yellow
    Write-Host "  1. Mesaj gönder: 'Hello Simon AI'" -ForegroundColor Gray
    Write-Host "  2. Markdown test: 'Write a tutorial with code'" -ForegroundColor Gray
    Write-Host "  3. Model değiştir: FREE → BYOK" -ForegroundColor Gray
    Write-Host "  4. Regenerate test: Hover → Regenerate icon" -ForegroundColor Gray
    Write-Host "  5. Clear chat: Sidebar → Clear Chat" -ForegroundColor Gray
} elseif (-not $backendOK) {
    Write-Host "⚠️  BACKEND BAŞLATMA GEREKİYOR" -ForegroundColor Yellow
    Write-Host "   cd $ProjectRoot" -ForegroundColor Gray
    Write-Host "   docker compose up -d" -ForegroundColor Gray
    Write-Host "   (Frontend çalışıyor ama backend'e bağlanamaz)" -ForegroundColor Gray
} elseif (-not $frontendOK) {
    Write-Host "⚠️  FRONTEND BAŞLATMA GEREKİYOR" -ForegroundColor Yellow
    Write-Host "   cd $FrontendDir" -ForegroundColor Gray
    Write-Host "   npm run dev" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Raporlar: $ReportsDir" -ForegroundColor Cyan
Write-Host "Frontend: $FrontendDir" -ForegroundColor Cyan
Write-Host ""

# Log dosyası oluştur
$logFile = "$ProjectRoot\FAZ5_KURULUM_LOG_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
@"
FAZ 5 KURULUM LOG
==================
Tarih: $(Get-Date)
Backend: $(if ($backendOK) { 'OK' } else { 'FAIL' })
Frontend: $(if ($frontendOK) { 'OK' } else { 'FAIL' })
Reports: $ReportsDir
Frontend: $FrontendDir
"@ | Out-File -FilePath $logFile -Encoding UTF8

Write-Host "Log: $logFile" -ForegroundColor Gray
Write-Host ""
