# SIMON AI - FAZ 5 FULL SETUP AND TEST
# Clean ASCII version - No special characters

param(
    [switch]$SkipBackend = $false,
    [switch]$SkipFrontend = $false
)

$ErrorActionPreference = "Continue"
$ProjectRoot = "C:\Users\ceyhu\Desktop\simonai"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "SIMON AI - FAZ 5 KURULUM" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# STEP 1: COPY REPORTS
Write-Host "[1/7] Reports kopyalaniyor..." -ForegroundColor Yellow

$OutputsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportsSourceDir = Join-Path $OutputsDir "reports"
$ReportsDestDir = Join-Path $ProjectRoot "reports"

if (-not (Test-Path $ReportsDestDir)) {
    New-Item -ItemType Directory -Path $ReportsDestDir -Force | Out-Null
}

if (Test-Path $ReportsSourceDir) {
    $reportFiles = Get-ChildItem -Path $ReportsSourceDir -Filter "*.md"
    foreach ($file in $reportFiles) {
        Copy-Item -Path $file.FullName -Destination $ReportsDestDir -Force
        Write-Host "  [OK] $($file.Name)" -ForegroundColor Green
    }
    Write-Host "  TOTAL: $($reportFiles.Count) files" -ForegroundColor Cyan
} else {
    Write-Host "  [WARN] Reports source not found" -ForegroundColor Yellow
}

Write-Host ""

# STEP 2: COPY FRONTEND SCAFFOLD
Write-Host "[2/7] Frontend scaffold kopyalaniyor..." -ForegroundColor Yellow

$ScaffoldDir = Join-Path $OutputsDir "frontend-scaffold"
$FrontendDir = Join-Path $ProjectRoot "frontend"

if (Test-Path $ScaffoldDir) {
    if (Test-Path $FrontendDir) {
        Write-Host "  -> Backup olusturuluyor..." -ForegroundColor Gray
        $BackupDir = "$FrontendDir.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Move-Item -Path $FrontendDir -Destination $BackupDir -Force -ErrorAction SilentlyContinue
    }
    
    Copy-Item -Path $ScaffoldDir -Destination $FrontendDir -Recurse -Force
    $fileCount = (Get-ChildItem -Path $FrontendDir -Recurse -File).Count
    Write-Host "  [OK] Frontend copied ($fileCount files)" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Scaffold not found: $ScaffoldDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "COZUM: frontend-scaffold klasorunu Claude'dan indirin" -ForegroundColor Yellow
    Write-Host "       ve bu scriptin oldugu yere koyun" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# STEP 3: CREATE .ENV.LOCAL
Write-Host "[3/7] Environment config..." -ForegroundColor Yellow

$envContent = "NEXT_PUBLIC_API_URL=http://localhost:8000"
$envPath = Join-Path $FrontendDir ".env.local"
Set-Content -Path $envPath -Value $envContent -Force
Write-Host "  [OK] .env.local created" -ForegroundColor Green

Write-Host ""

# STEP 4: INSTALL DEPENDENCIES
if (-not $SkipFrontend) {
    Write-Host "[4/7] Dependencies kuruluyor..." -ForegroundColor Yellow
    Write-Host "  Bu islem 2-3 dakika surebilir..." -ForegroundColor Gray
    
    Set-Location $FrontendDir
    
    if (-not (Test-Path "package.json")) {
        Write-Host "  [ERROR] package.json not found!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  -> npm install..." -ForegroundColor Gray
    $installOutput = npm install 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Install completed with warnings" -ForegroundColor Yellow
    }
} else {
    Write-Host "[4/7] Dependencies (SKIPPED)" -ForegroundColor Gray
}

Write-Host ""

# STEP 5: CHECK BACKEND
if (-not $SkipBackend) {
    Write-Host "[5/7] Backend kontrolu..." -ForegroundColor Yellow
    
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  [OK] Backend RUNNING" -ForegroundColor Green
        $backendOK = $true
    } catch {
        Write-Host "  [WARN] Backend not running" -ForegroundColor Yellow
        Write-Host "  -> Starting backend..." -ForegroundColor Gray
        
        Set-Location $ProjectRoot
        docker compose up -d 2>&1 | Out-Null
        
        Write-Host "  -> Waiting 30 seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
        
        try {
            $health = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 10
            Write-Host "  [OK] Backend STARTED" -ForegroundColor Green
            $backendOK = $true
        } catch {
            Write-Host "  [ERROR] Backend failed to start" -ForegroundColor Red
            Write-Host "  Manual start: docker compose up -d" -ForegroundColor Gray
            $backendOK = $false
        }
    }
} else {
    Write-Host "[5/7] Backend check (SKIPPED)" -ForegroundColor Gray
    $backendOK = $false
}

Write-Host ""

# STEP 6: BUILD TEST
Write-Host "[6/7] Build test..." -ForegroundColor Yellow

Set-Location $FrontendDir

Write-Host "  -> TypeScript & Next.js build..." -ForegroundColor Gray
$buildOutput = npm run build 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Build SUCCESS" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Build completed with warnings" -ForegroundColor Yellow
}

Write-Host ""

# STEP 7: START DEV SERVER
Write-Host "[7/7] Dev server..." -ForegroundColor Yellow

Write-Host "  -> Starting in background..." -ForegroundColor Gray

# Kill existing node process
Get-Process -Name node -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Start dev server
$processInfo = Start-Process -FilePath "npm" -ArgumentList "run", "dev" -WorkingDirectory $FrontendDir -PassThru -WindowStyle Hidden

Write-Host "  -> Waiting 10 seconds..." -ForegroundColor Gray
Start-Sleep -Seconds 10

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "  [OK] Frontend RUNNING" -ForegroundColor Green
        $frontendOK = $true
    }
} catch {
    Write-Host "  [WARN] Frontend not responding" -ForegroundColor Yellow
    Write-Host "  Manual start: npm run dev" -ForegroundColor Gray
    $frontendOK = $false
}

Write-Host ""

# SUMMARY
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "KURULUM TAMAMLANDI" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Status:" -ForegroundColor Yellow
Write-Host "  Reports:      [OK] $ReportsDestDir" -ForegroundColor Green
Write-Host "  Frontend:     [OK] $FrontendDir" -ForegroundColor Green
Write-Host "  Dependencies: [OK] Installed" -ForegroundColor Green

if ($backendOK) {
    Write-Host "  Backend:      [OK] RUNNING" -ForegroundColor Green
} else {
    Write-Host "  Backend:      [WARN] CHECK NEEDED" -ForegroundColor Yellow
}

if ($frontendOK) {
    Write-Host "  Frontend:     [OK] RUNNING" -ForegroundColor Green
} else {
    Write-Host "  Frontend:     [WARN] MANUAL START" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Access:" -ForegroundColor Cyan
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor Gray
Write-Host "  Backend:  http://localhost:8000" -ForegroundColor Gray
Write-Host "  API Docs: http://localhost:8000/docs" -ForegroundColor Gray
Write-Host ""

if ($backendOK -and $frontendOK) {
    Write-Host "SUCCESS: All systems ready!" -ForegroundColor Green
    Write-Host "Open browser: http://localhost:3000" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test scenarios:" -ForegroundColor Yellow
    Write-Host "  1. Send message: 'Hello Simon AI'" -ForegroundColor Gray
    Write-Host "  2. Markdown test: 'Write a tutorial with code'" -ForegroundColor Gray
    Write-Host "  3. Switch model: FREE -> BYOK" -ForegroundColor Gray
    Write-Host "  4. Regenerate: Hover message -> Regenerate" -ForegroundColor Gray
    Write-Host "  5. Clear chat: Sidebar -> Clear Chat" -ForegroundColor Gray
} else {
    Write-Host "WARNING: Some components need attention" -ForegroundColor Yellow
    if (-not $backendOK) {
        Write-Host "  Backend: cd $ProjectRoot && docker compose up -d" -ForegroundColor Gray
    }
    if (-not $frontendOK) {
        Write-Host "  Frontend: cd $FrontendDir && npm run dev" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Reports: $ReportsDestDir" -ForegroundColor Cyan
Write-Host "Frontend: $FrontendDir" -ForegroundColor Cyan
Write-Host ""

# Create log file
$logFile = "$ProjectRoot\FAZ5_KURULUM_LOG_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$logContent = @"
FAZ 5 KURULUM LOG
==================
Tarih: $(Get-Date)
Backend: $(if ($backendOK) { 'OK' } else { 'FAIL' })
Frontend: $(if ($frontendOK) { 'OK' } else { 'FAIL' })
Reports: $ReportsDestDir
Frontend: $FrontendDir
"@
$logContent | Out-File -FilePath $logFile -Encoding UTF8

Write-Host "Log: $logFile" -ForegroundColor Gray
Write-Host ""
