# Simon AI - LiteLLM Config Düzeltme
Write-Host "=== LiteLLM CONFIG EKLENİYOR ===" -ForegroundColor Green

$repoPath = "C:\Users\ceyhu\Downloads\simon-ai-faz3-complete\simon-ai-agent-studio"
Set-Location $repoPath

Write-Host "1. Containerları durduruyor..." -ForegroundColor Yellow
docker compose down

Write-Host "2. Config dosyasını kopyalıyorum..." -ForegroundColor Yellow
Copy-Item "litellm-config.yaml" "litellm-config.yaml" -Force

Write-Host "3. Final compose dosyasını kopyalıyorum..." -ForegroundColor Yellow
Copy-Item "docker-compose-final.yml" "docker-compose.yml" -Force

Write-Host "4. LiteLLM'i yeniden başlatıyorum..." -ForegroundColor Yellow
docker compose up -d

Write-Host "5. 15 saniye bekliyorum..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "6. Container durumunu kontrol ediyorum..." -ForegroundColor Yellow
docker compose ps

Write-Host ""
Write-Host "=== TAMAMLANDI! ===" -ForegroundColor Green
Write-Host "Swagger UI'de chat endpoint'ini test edin!" -ForegroundColor Cyan
Write-Host "Model ismi: qwen2.5" -ForegroundColor Yellow
