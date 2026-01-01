# Simon AI - API-Only Başlatma
# Web frontend geçici disabled (build sorunu nedeniyle)

Write-Host "=== SIMON AI API BAŞLATILIYOR ===" -ForegroundColor Green

$repoPath = "C:\Users\ceyhu\Downloads\simon-ai-faz3-complete\simon-ai-agent-studio"
Set-Location $repoPath

Write-Host "1. Eski containerları temizliyorum..." -ForegroundColor Yellow
docker compose down --remove-orphans 2>$null

Write-Host "2. API-only compose kullanıyorum..." -ForegroundColor Yellow
Copy-Item "docker-compose-api-only.yml" "docker-compose.yml" -Force

Write-Host "3. Containerları başlatıyorum (web yok, sadece API)..." -ForegroundColor Yellow
docker compose up -d --build

Write-Host "4. Container durumunu kontrol ediyorum..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
docker compose ps

Write-Host ""
Write-Host "=== TAMAMLANDI! ===" -ForegroundColor Green
Write-Host "API: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "Health: http://localhost:8000/health" -ForegroundColor Cyan
Write-Host "LiteLLM: http://localhost:4000" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOT: Web frontend geçici disabled (npm hatası). Önce API'yi test edelim." -ForegroundColor Yellow
Write-Host ""
Write-Host "Logları görmek için: docker compose logs -f api" -ForegroundColor Gray
