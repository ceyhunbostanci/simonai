# tools\fix-openai-env-for-litellm.ps1
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

function Patch-Service-Env {
  param(
    [string[]]$lines,
    [string]$serviceName,
    [hashtable]$envToAdd
  )

  $out = New-Object System.Collections.Generic.List[string]
  $inServices = $false
  $inTarget = $false
  $svcIndent = 2
  $envLineIdxInOut = -1
  $envIndent = 4
  $envStyle = ""  # "list" | "map"
  $existingKeys = New-Object System.Collections.Generic.HashSet[string]

  for ($i=0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    if ($line -match "^\s*services:\s*$") { $inServices = $true }
    if (-not $inServices) {
      $out.Add($line)
      continue
    }

    # service start at indent 2: "  api:"
    if ($line -match "^\s{$svcIndent}$serviceName:\s*$") {
      $inTarget = $true
      $envLineIdxInOut = -1
      $envStyle = ""
      $existingKeys.Clear() | Out-Null
      $out.Add($line)
      continue
    }

    # leaving target service when next service at indent 2 appears
    if ($inTarget -and ($line -match "^\s{$svcIndent}\S+:\s*$") -and ($line -notmatch "^\s{$svcIndent}$serviceName:\s*$")) {
      # before leaving, ensure environment block exists and missing vars appended
      if ($envLineIdxInOut -lt 0) {
        $out.Add((" " * $envIndent) + "environment:")
        $envLineIdxInOut = $out.Count - 1
        $envStyle = "list"  # default safest with docker-compose
      }
      foreach ($k in $envToAdd.Keys) {
        if (-not $existingKeys.Contains($k)) {
          if ($envStyle -eq "map") {
            $out.Add((" " * ($envIndent + 2)) + "$k: $($envToAdd[$k])")
          } else {
            $out.Add((" " * ($envIndent + 2)) + "- $k=$($envToAdd[$k])")
          }
        }
      }
      $inTarget = $false
      $out.Add($line)
      continue
    }

    if ($inTarget) {
      # detect environment block
      if ($line -match "^\s{$envIndent}environment:\s*$") {
        $envLineIdxInOut = $out.Count
        $out.Add($line)

        # peek next non-empty line to detect style
        $peek = ""
        for ($j=$i+1; $j -lt $lines.Count; $j++) {
          if ($lines[$j].Trim() -ne "") { $peek = $lines[$j]; break }
        }
        if ($peek -match "^\s{$($envIndent+2)}- ") { $envStyle = "list" }
        elseif ($peek -match "^\s{$($envIndent+2)}[^:\s]+:\s*") { $envStyle = "map" }
        else { $envStyle = "list" }

        continue
      }

      # collect existing env keys (list or map)
      if ($envLineIdxInOut -ge 0) {
        if ($line -match "^\s{$($envIndent+2)}- ([A-Za-z_][A-Za-z0-9_]*)=") {
          $existingKeys.Add($Matches[1]) | Out-Null
        } elseif ($line -match "^\s{$($envIndent+2)}([A-Za-z_][A-Za-z0-9_]*)\s*:") {
          $existingKeys.Add($Matches[1]) | Out-Null
        }
      }

      $out.Add($line)
      continue
    }

    $out.Add($line)
  }

  # file ended while still inside target service -> finalize append
  if ($inTarget) {
    if ($envLineIdxInOut -lt 0) {
      $out.Add((" " * $envIndent) + "environment:")
      $envStyle = "list"
    }
    foreach ($k in $envToAdd.Keys) {
      if (-not $existingKeys.Contains($k)) {
        if ($envStyle -eq "map") {
          $out.Add((" " * ($envIndent + 2)) + "$k: $($envToAdd[$k])")
        } else {
          $out.Add((" " * ($envIndent + 2)) + "- $k=$($envToAdd[$k])")
        }
      }
    }
  }

  return ,$out.ToArray()
}

$RepoRoot = Find-RepoRoot -start (Get-Location).Path
$yml = Join-Path $RepoRoot "docker-compose.agentstudio.override.yml"
if (!(Test-Path $yml)) { throw "Bulunamadı: $yml" }

$raw = Get-Content -Raw -Encoding UTF8 $yml
$backupDir = Join-Path $RepoRoot "_backup"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item $yml (Join-Path $backupDir ("docker-compose.agentstudio.override.yml.$stamp.bak")) -Force

# Master key'yi sizin mevcut çalışan değerinizle sabitliyoruz
$MASTER = "sk-simon-local-master"

$lines = $raw -split "`n"
$envToAdd = @{
  "OPENAI_API_KEY"  = $MASTER
  "OPENAI_BASE_URL" = "http://litellm:4000"
  "OPENAI_API_BASE" = "http://litellm:4000"
}

$patched = Patch-Service-Env -lines $lines -serviceName "api" -envToAdd $envToAdd
Set-Content -Encoding UTF8 -Path $yml -Value ($patched -join "`n")

Write-Host "OK: docker-compose.agentstudio.override.yml guncellendi (api: OPENAI_* eklendi)."
Write-Host "Backup: _backup/docker-compose.agentstudio.override.yml.$stamp.bak"
