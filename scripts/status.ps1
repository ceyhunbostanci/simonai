# --- UTF-8 Console Safety Header ---
try {
  [Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
  $OutputEncoding = [Console]::OutputEncoding
} catch {}
# -----------------------------------

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$Docs = Join-Path $Root "docs"

Write-Host "=== Automation OS Status ==="
Write-Host "Root: $Root"
Write-Host "Docs: $Docs"

if (-not (Test-Path $Docs)) {
  Write-Host "ERROR: docs klasörü bulunamadı. (Beklenen: $Docs)"
  Write-Host "Fix: powershell -ExecutionPolicy Bypass -File .\bootstrap_automation_os.ps1"
  exit 1
}

Write-Host "Docs list:"
Get-ChildItem $Docs | Select-Object Name

Write-Host ""
Write-Host "Key files:"
@(
  "docs\PROJECT_STATE.md",
  "docs\RUN_LOG.md",
  "docs\ARCHITECTURE.md",
  "docs\SECURITY.md",
  "docs\MODEL_ROUTING.md",
  "docs\COST_BUDGET.md",
  "docs\APPROVAL_GATE.md",
  ".env.template",
  ".gitignore"
) | ForEach-Object {
  $p = Join-Path $Root $_
  if (Test-Path $p) { Write-Host " OK   $_" } else { Write-Host " MISS $_" }
}
