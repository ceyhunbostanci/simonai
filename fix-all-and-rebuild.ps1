# Simon AI - Tüm Hataları Düzelt ve Rebuild
Write-Host "=== SIMON AI - TÜM HATALARI DÜZELTİYORUM ===" -ForegroundColor Green

$repoPath = "C:\Users\ceyhu\Downloads\simon-ai-faz3-complete\simon-ai-agent-studio"
Set-Location $repoPath

Write-Host "1. Containerları durdurup siliyorum..." -ForegroundColor Yellow
docker compose down -v

Write-Host "2. Models.py düzeltiyorum (metadata -> meta_data)..." -ForegroundColor Yellow
Copy-Item "models-fixed.py" "apps\api\app\database\models.py" -Force

Write-Host "3. Auth.py düzeltiyorum (UserRole.USER -> UserRole.user)..." -ForegroundColor Yellow
Copy-Item "auth-fixed.py" "apps\api\app\services\auth.py" -Force

Write-Host "4. Docker cache temizliyorum..." -ForegroundColor Yellow
docker builder prune -f

Write-Host "5. API rebuild ediyorum (--no-cache)..." -ForegroundColor Yellow
docker compose build --no-cache api

Write-Host "6. Tüm servisleri başlatıyorum..." -ForegroundColor Yellow
docker compose up -d

Write-Host "7. 20 saniye bekliyorum..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

Write-Host ""
Write-Host "8. Container durumu:" -ForegroundColor Cyan
docker compose ps

Write-Host ""
Write-Host "9. API logları (son 30 satır):" -ForegroundColor Cyan
docker logs simon-api --tail 30

Write-Host ""
Write-Host "10. Health check:" -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5
    Write-Host "✅✅✅ API ÇALIŞIYOR! ✅✅✅" -ForegroundColor Green
    Write-Host $response.Content
    Write-Host ""
    Write-Host "=== BAŞARILI! ===" -ForegroundColor Green
    Write-Host "Frontend: http://localhost:3000 (şu an disabled)" -ForegroundColor Gray
    Write-Host "API Docs: http://localhost:8000/docs" -ForegroundColor Cyan
    Write-Host "Health: http://localhost:8000/health" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Health check başarısız. Logları kontrol edin." -ForegroundColor Red
    Write-Host "Manuel test: http://localhost:8000/health" -ForegroundColor Yellow
}
