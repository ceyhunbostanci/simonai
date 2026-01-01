# tools\fix-litellm-auth-header.ps1
$ErrorActionPreference = "Stop"

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root "docker-compose.yml"))) {
  throw "RepoRoot bulunamadı. docker-compose.yml olan klasörde çalıştırın."
}

$targets = @(
  "apps\api\app\services",
  "apps\api\app\routers"
)

$files = @()
foreach ($t in $targets) {
  $p = Join-Path $root $t
  if (Test-Path $p) {
    $files += Get-ChildItem -Path $p -Recurse -Filter "*.py" | Select-Object -ExpandProperty FullName
  }
}
if ($files.Count -eq 0) { throw "Hedef python dosyası bulunamadı." }

$changed = 0

foreach ($f in $files) {
  $old = Get-Content -Raw -Path $f

  # 1) headers = {"Authorization": key}  -> Bearer + x-api-key
  $new = $old -replace 'headers\s*=\s*\{\s*["'']Authorization["'']\s*:\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}',
                       'headers = {"Authorization": f"Bearer {$1}", "x-api-key": $1}'

  # 2) inline headers={"Authorization": key} (aynı regex zaten yakalar ama garanti için tekrar)
  $new = $new -replace 'headers\s*=\s*\{\s*["'']authorization["'']\s*:\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}',
                       'headers = {"Authorization": f"Bearer {$1}", "x-api-key": $1}'

  if ($new -ne $old) {
    Set-Content -Path $f -Value $new -Encoding utf8
    $changed++
  }
}

Write-Host "✅ Patch tamam. Değişen dosya sayısı: $changed"
