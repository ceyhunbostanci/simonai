# Simon AI - Metadata Hatasını Düzelt ve Restart
Write-Host "=== SIMON AI HATASI DÜZELTİLİYOR ===" -ForegroundColor Green

$repoPath = "C:\Users\ceyhu\Downloads\simon-ai-faz3-complete\simon-ai-agent-studio"
Set-Location $repoPath

Write-Host "1. Models.py dosyasını düzeltiyorum..." -ForegroundColor Yellow
Copy-Item "models-fixed.py" "apps\api\app\database\models.py" -Force

Write-Host "2. API container'ı yeniden başlatıyorum..." -ForegroundColor Yellow
docker compose restart api

Write-Host "3. 10 saniye bekliyorum..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "4. API loglarını kontrol ediyorum..." -ForegroundColor Yellow
docker logs simon-api --tail 20

Write-Host ""
Write-Host "5. Health check yapıyorum..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5
    Write-Host "✅ API ÇALIŞIYOR!" -ForegroundColor Green
    Write-Host $response.Content
} catch {
    Write-Host "❌ API henüz hazır değil. Logları kontrol edin." -ForegroundColor Red
}

Write-Host ""
Write-Host "=== İŞLEM TAMAMLANDI ===" -ForegroundColor Cyan
Write-Host "API Docs: http://localhost:8000/docs" -ForegroundColor Cyan
