# Simon AI - Ollama Ekleme ve Yeniden Başlatma
Write-Host "=== OLLAMA EKLENİYOR ===" -ForegroundColor Green

$repoPath = "C:\Users\ceyhu\Downloads\simon-ai-faz3-complete\simon-ai-agent-studio"
Set-Location $repoPath

Write-Host "1. Mevcut containerları durduruyor..." -ForegroundColor Yellow
docker compose down

Write-Host "2. Yeni compose dosyasını kopyalıyorum (Ollama ekli)..." -ForegroundColor Yellow
Copy-Item "docker-compose-with-ollama.yml" "docker-compose.yml" -Force

Write-Host "3. Tüm servisleri başlatıyorum (Ollama dahil)..." -ForegroundColor Yellow
docker compose up -d

Write-Host "4. 20 saniye bekliyorum..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

Write-Host "5. Container durumunu kontrol ediyorum..." -ForegroundColor Yellow
docker compose ps

Write-Host ""
Write-Host "6. Ollama'ya qwen2.5 modelini indiriyorum..." -ForegroundColor Cyan
docker exec simon-ollama ollama pull qwen2.5

Write-Host ""
Write-Host "7. Model listesini kontrol ediyorum..." -ForegroundColor Cyan
docker exec simon-ollama ollama list

Write-Host ""
Write-Host "=== TAMAMLANDI! ===" -ForegroundColor Green
Write-Host "Ollama: http://localhost:11434" -ForegroundColor Cyan
Write-Host "API: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "Şimdi Swagger UI'de chat endpoint'ini tekrar test edin!" -ForegroundColor Yellow
