# Hızlı durum kontrolü
cd C:\Users\ceyhu\Desktop\simonai

Write-Host "=== CONTAINER DURUMU ===" -ForegroundColor Cyan
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n=== PROJE YAPISI ===" -ForegroundColor Cyan
if (Test-Path "apps\api\app\main.py") {
    Write-Host "main.py: MEVCUT" -ForegroundColor Green
} else {
    Write-Host "main.py: YOK" -ForegroundColor Red
}

if (Test-Path "apps\api\requirements.txt") {
    Write-Host "requirements.txt: MEVCUT" -ForegroundColor Green
} else {
    Write-Host "requirements.txt: YOK" -ForegroundColor Red
}

Write-Host "`n=== API YAPISI ===" -ForegroundColor Cyan
Get-ChildItem "apps\api" -Recurse -Depth 2 | Select-Object -First 20 | Format-Table Name, FullName
