# tools\fix-litellm-auth-allcallers.ps1
$ErrorActionPreference = "Stop"

function Find-RepoRoot {
  param([string]$start)
  $p = Resolve-Path $start
  while ($true) {
    if (Test-Path (Join-Path $p "docker-compose.yml")) { return $p }
    $parent = Split-Path $p -Parent
    if ($parent -eq $p) { throw "Repo root bulunamadı (docker-compose.yml yok). Script'i repo içinde çalıştır." }
    $p = $parent
  }
}

$RepoRoot = Find-RepoRoot -start (Get-Location).Path
Write-Host "RepoRoot: $RepoRoot"

# 1) Ortak helper modülü yaz
$utilsDir = Join-Path $RepoRoot "apps\api\app\utils"
New-Item -ItemType Directory -Force -Path $utilsDir | Out-Null

$utilsInit = Join-Path $utilsDir "__init__.py"
if (!(Test-Path $utilsInit)) { Set-Content -Encoding UTF8 $utilsInit "" }

$authPy = Join-Path $utilsDir "litellm_auth.py"
@"
import os

def litellm_headers() -> dict:
    """
    LiteLLM proxy auth:
      - Prefer LITELLM_API_KEY, fallback LITELLM_MASTER_KEY
      - Send both Authorization Bearer + x-api-key for maximum compatibility
    """
    key = os.getenv("LITELLM_API_KEY") or os.getenv("LITELLM_MASTER_KEY") or ""
    key = key.strip()
    if not key:
        return {}

    # If user accidentally sets "Bearer sk-..." keep it clean
    if key.lower().startswith("bearer "):
        raw = key.split(" ", 1)[1].strip()
        return {"Authorization": f"Bearer {raw}", "x-api-key": raw}

    return {"Authorization": f"Bearer {key}", "x-api-key": key}
"@ | Set-Content -Encoding UTF8 $authPy

Write-Host "OK: apps\api\app\utils\litellm_auth.py yazildi."

# 2) /chat/completions geçen python dosyalarında headers enjekte et
$apiRoot = Join-Path $RepoRoot "apps\api"
$targets = @()

$matches = Select-String -Path (Join-Path $apiRoot "**\*.py") -Pattern "/chat/completions" -List -ErrorAction SilentlyContinue
if ($matches) { $targets = $matches.Path | Sort-Object -Unique }

if ($targets.Count -eq 0) {
  throw "Hedef dosya bulunamadi: apps\api altinda '/chat/completions' string'i yok."
}

Write-Host "Patch hedefleri:"
$targets | ForEach-Object { Write-Host " - $_" }

function Ensure-Import($content) {
  if ($content -match "from\s+app\.utils\.litellm_auth\s+import\s+litellm_headers") { return $content }
  # import blokunun sonuna eklemeye çalış
  $lines = $content -split "`n"
  $insertAt = 0
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^\s*(import|from)\s+") { $insertAt = $i + 1 } else { break }
  }
  $newLines = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines.Count; $i++) {
    $newLines.Add($lines[$i])
    if ($i -eq $insertAt - 1) {
      $newLines.Add("from app.utils.litellm_auth import litellm_headers")
    }
  }
  return ($newLines -join "`n")
}

function Inject-Headers-IntoPost($content) {
  $lines = $content -split "`n"
  $out = New-Object System.Collections.Generic.List[string]

  for ($i=0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    # Tek satır .post(...) yakala
    if ($line -match "\.post\(" -and $line -match "\)" -and $line -notmatch "headers\s*=") {
      # ".post(X, ..." formuna headers ekle
      $patched = $line -replace "\.post\(\s*([^,]+)\s*,", ".post(`$1, headers=litellm_headers(),"
      if ($patched -ne $line) {
        $out.Add($patched)
        continue
      }
    }

    # Çok satır .post( bloğu yakala: headers yoksa ikinci satıra ekle
    if ($line -match "\.post\(" -and $line -notmatch "headers\s*=" -and $line -notmatch "\)") {
      # Bu bloğun içinde headers var mı bak (15 satıra kadar)
      $hasHeaders = $false
      for ($j=$i; $j -lt [Math]::Min($i+15, $lines.Count); $j++) {
        if ($lines[$j] -match "headers\s*=") { $hasHeaders = $true; break }
        if ($lines[$j] -match "^\s*\)\s*$") { break }
      }
      $out.Add($line)
      if (-not $hasHeaders) {
        # İlk argüman genelde bir sonraki satır: onun hemen altına ekleyelim
        if ($i + 1 -lt $lines.Count) {
          $argLine = $lines[$i+1]
          $indent = ($argLine -replace "(\S.*)$","")  # leading spaces
          # argLine'ı önce eklemeyelim burada; normal akışta i++ ile eklenecek.
          # Bunun yerine bir sonraki satır eklendikten sonra enjekte edeceğiz:
          # => işaret koy
          $out.Add("{{{__INJECT_AFTER_NEXT_LINE__:$indent}}}")
        }
      }
      continue
    }

    $out.Add($line)
  }

  # Placeholder'ları çöz: "bir sonraki satırdan sonra"
  $final = New-Object System.Collections.Generic.List[string]
  for ($k=0; $k -lt $out.Count; $k++) {
    $l = $out[$k]
    if ($l -like "{{{__INJECT_AFTER_NEXT_LINE__:*}}}") {
      # Bu satır placeholder; kendinden önceki satır zaten eklendi; şimdi headers ekle
      $indent = $l.Substring($l.IndexOf(":")+1).TrimEnd("}}}".ToCharArray())
      $final.Add("$indent"+"headers=litellm_headers(),")
      continue
    }
    $final.Add($l)
  }

  return ($final -join "`n")
}

$changedCount = 0
foreach ($f in $targets) {
  $before = Get-Content -Raw -Encoding UTF8 $f
  $after = $before
  $after = Ensure-Import $after
  $after = Inject-Headers-IntoPost $after

  if ($after -ne $before) {
    Set-Content -Encoding UTF8 -Path $f -Value $after
    $changedCount++
    Write-Host "PATCH OK: $f"
  } else {
    Write-Host "SKIP (degismedi): $f"
  }
}

Write-Host "DONE. Degisen dosya sayisi: $changedCount"
Write-Host "Sonraki: docker compose restart api + tools\agent-studio-test.ps1"
