# Simon AI - Hızlı Başlatma Scripti
# Kullanım: .\start-simon.ps1

Write-Host "=== SIMON AI BAŞLATILIYOR ===" -ForegroundColor Green

# Repo klasörüne git
$repoPath = "C:\Users\ceyhu\Downloads\simon-ai-faz3-complete\simon-ai-agent-studio"
Set-Location $repoPath

Write-Host "1. Eski containerları temizliyorum..." -ForegroundColor Yellow
docker compose down --remove-orphans 2>$null

Write-Host "2. Minimal compose dosyasını kopyalıyorum..." -ForegroundColor Yellow
Copy-Item "docker-compose-minimal.yml" "docker-compose.yml" -Force

Write-Host "3. Containerları başlatıyorum..." -ForegroundColor Yellow
docker compose up -d --build

Write-Host "4. Container durumunu kontrol ediyorum..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
docker compose ps

Write-Host ""
Write-Host "=== TAMAMLANDI! ===" -ForegroundColor Green
Write-Host "Frontend: http://localhost:3000" -ForegroundColor Cyan
Write-Host "API: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "Health: http://localhost:8000/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "Logları görmek için: docker compose logs -f" -ForegroundColor Yellow
