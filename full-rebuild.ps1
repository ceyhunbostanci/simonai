# Simon AI - Tam Rebuild (Metadata + Enum Hatası Düzeltme)
Write-Host "=== SIMON AI TAM REBUILD ===" -ForegroundColor Green

$repoPath = "C:\Users\ceyhu\Downloads\simon-ai-faz3-complete\simon-ai-agent-studio"
Set-Location $repoPath

Write-Host "1. Containerları durdurup siliyorum..." -ForegroundColor Yellow
docker compose down -v

Write-Host "2. Models.py dosyasını düzeltiyorum..." -ForegroundColor Yellow
Copy-Item "models-fixed.py" "apps\api\app\database\models.py" -Force

Write-Host "3. Docker cache'i temizliyorum..." -ForegroundColor Yellow
docker builder prune -f

Write-Host "4. Yeniden build ediyorum (cache yok)..." -ForegroundColor Yellow
docker compose build --no-cache api

Write-Host "5. Tüm servisleri başlatıyorum..." -ForegroundColor Yellow
docker compose up -d

Write-Host "6. 15 saniye bekliyorum..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "7. Container durumunu kontrol ediyorum..." -ForegroundColor Yellow
docker compose ps

Write-Host ""
Write-Host "8. API loglarını kontrol ediyorum..." -ForegroundColor Yellow
docker logs simon-api --tail 30

Write-Host ""
Write-Host "9. Health check yapıyorum..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5
    Write-Host "✅ API ÇALIŞIYOR!" -ForegroundColor Green
    Write-Host $response.Content
} catch {
    Write-Host "❌ API hazır değil. Manuel kontrol: http://localhost:8000/health" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== TAMAMLANDI ===" -ForegroundColor Cyan
Write-Host "API Docs: http://localhost:8000/docs" -ForegroundColor Cyan
