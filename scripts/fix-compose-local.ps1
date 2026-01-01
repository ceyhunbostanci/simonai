$ErrorActionPreference = "Stop"

# Repo kökü (scripts içinden 1 üst)
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot
Write-Host "Repo root: $repoRoot"

# --- docker-compose.yml yedeğini al
$compose = "docker-compose.yml"
if (!(Test-Path $compose)) { throw "docker-compose.yml bulunamadı: $repoRoot" }

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item $compose "$compose.bak-$ts" -Force
Write-Host "OK: Yedek alındı => $compose.bak-$ts"

# --- deploy/replicas bloğunu kaldır (local compose uyumluluğu)
$content = Get-Content $compose -Raw
$fixed = [regex]::Replace($content, "(?m)^\s*deploy:\s*\r?\n\s*replicas:\s*\d+\s*\r?\n", "")

if ($fixed -eq $content) {
  Write-Host "WARN: deploy/replicas bloğu bulunamadı (zaten kaldırılmış olabilir)."
} else {
  Set-Content -Path $compose -Value $fixed -Encoding UTF8
  Write-Host "OK: deploy/replicas bloğu kaldırıldı (local compose için)."
}

# --- .env oluştur (varsa dokunma)
$envFile = ".env"
if (!(Test-Path $envFile)) {
@"
# Simon AI Agent Studio - Local Dev
# Not: LLM çağrıları için doldurmanız gerekir.
CLAUDE_API_KEY=
OPENAI_API_KEY=
GOOGLE_API_KEY=
"@ | Set-Content -Encoding UTF8 $envFile
  Write-Host "OK: .env oluşturuldu (anahtarları sonra doldurabilirsiniz)."
} else {
  Write-Host "OK: .env zaten var."
}

# --- Compose doğrulama
docker compose -f docker-compose.yml -f docker-compose.dev.yml config | Out-Null
Write-Host "OK: docker compose config valid."

# --- Ayağa kaldır
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
docker compose -f docker-compose.yml -f docker-compose.dev.yml ps

# --- RUN_LOG'a kısa kayıt (varsa)
$runLog = "docs\RUN_LOG.md"
if (Test-Path $runLog) {
  Add-Content -Encoding UTF8 $runLog "`n## $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n### Command`nfix-compose-local.ps1 (deploy/replicas removed; .env ensured; compose up)`n### Output`nOK"
  Write-Host "OK: docs/RUN_LOG.md güncellendi."
} else {
  Write-Host "WARN: docs/RUN_LOG.md yok; atlandı."
}

Write-Host "DONE: Sistem ayağa kaldırıldı. Web: http://localhost:3000  API: http://localhost:8000/health"
