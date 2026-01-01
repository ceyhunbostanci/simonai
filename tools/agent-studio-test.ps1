# tools\agent-studio-test.ps1
$ErrorActionPreference = "Stop"

$base = $env:SIMON_API_BASE
if (-not $base) { $base = "http://localhost:8000" }
$base = $base.TrimEnd("/")

Write-Host "== Agent Studio MVP-1 Test =="

# 1) Wait for API /health
$healthUrl = "$base/health"
$ok = $false
for ($i=1; $i -le 40; $i++) {
  try {
    $h = Invoke-RestMethod -Method Get -Uri $healthUrl -TimeoutSec 5
    Write-Host "API Health OK ($i/40): $($h | ConvertTo-Json -Compress)"
    $ok = $true
    break
  } catch {
    Start-Sleep -Seconds 1
  }
}
if (-not $ok) {
  Write-Host "❌ API /health 40 sn içinde gelmedi: $healthUrl" -ForegroundColor Red
  throw "API not ready"
}

# 2) Create session
$sessionUrl = "$base/api/agent/sessions"
$session = $null
try {
  $session = Invoke-RestMethod -Method Post -Uri $sessionUrl -ContentType "application/json" -Body '{"model":"qwen2.5"}' -TimeoutSec 20
  Write-Host "Session:"; $session | ConvertTo-Json -Depth 10
} catch {
  Write-Host "❌ Session create failed: $($_.Exception.Message)" -ForegroundColor Red
  throw
}

# 3) Send message
$sid = $session.session_id
$msgUrl = "$base/api/agent/sessions/$sid/messages"
$payload = @{
  content = "Ping"
  require_approval = $false
} | ConvertTo-Json

try {
  $r = Invoke-RestMethod -Method Post -Uri $msgUrl -ContentType "application/json" -Body $payload -TimeoutSec 60
  Write-Host "Response:"; $r | ConvertTo-Json -Depth 10
  Write-Host "✅ TEST OK" -ForegroundColor Green
} catch {
  Write-Host "❌ Message send failed: $($_.Exception.Message)" -ForegroundColor Red
  throw
}
