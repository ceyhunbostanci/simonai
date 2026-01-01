# Simon AI - Faz 3 Observability Test Script
# PowerShell

Write-Host "=== SIMON AI FAZ 3 TEST ===" -ForegroundColor Cyan
Write-Host ""

$tests = @()
$passed = 0
$failed = 0

# Test 1: Docker containers
Write-Host "[1/8] Container Status..." -NoNewline
try {
    $containers = docker ps --format "{{.Names}}" | Select-String "simon-"
    $count = ($containers | Measure-Object).Count
    
    if ($count -ge 10) {
        Write-Host " PASS ($count containers)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL ($count/10 containers)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    $failed++
}

# Test 2: Prometheus
Write-Host "[2/8] Prometheus..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9090/-/healthy" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host " PASS" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL (Status: $($response.StatusCode))" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host " FAIL (Not reachable)" -ForegroundColor Red
    $failed++
}

# Test 3: Grafana
Write-Host "[3/8] Grafana..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host " PASS" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL (Status: $($response.StatusCode))" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host " FAIL (Not reachable)" -ForegroundColor Red
    $failed++
}

# Test 4: Loki
Write-Host "[4/8] Loki..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3100/ready" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host " PASS" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL (Status: $($response.StatusCode))" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host " FAIL (Not reachable)" -ForegroundColor Red
    $failed++
}

# Test 5: API Metrics endpoint
Write-Host "[5/8] API Metrics..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/metrics" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200 -and $response.Content -like "*http_requests_total*") {
        Write-Host " PASS" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL (Invalid metrics)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host " FAIL (Not reachable)" -ForegroundColor Red
    $failed++
}

# Test 6: Prometheus targets
Write-Host "[6/8] Prometheus Targets..." -NoNewline
try {
    $response = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/targets" -TimeoutSec 5
    $up_targets = ($response.data.activeTargets | Where-Object { $_.health -eq "up" }).Count
    $total_targets = $response.data.activeTargets.Count
    
    if ($up_targets -ge 3) {
        Write-Host " PASS ($up_targets/$total_targets up)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL ($up_targets/$total_targets up)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host " FAIL (Query error)" -ForegroundColor Red
    $failed++
}

# Test 7: Prometheus rules
Write-Host "[7/8] Prometheus Rules..." -NoNewline
try {
    $response = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/rules" -TimeoutSec 5
    $rules_count = 0
    foreach ($group in $response.data.groups) {
        $rules_count += $group.rules.Count
    }
    
    if ($rules_count -ge 8) {
        Write-Host " PASS ($rules_count rules)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL ($rules_count/8 rules)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host " FAIL (Query error)" -ForegroundColor Red
    $failed++
}

# Test 8: Grafana datasources
Write-Host "[8/8] Grafana Datasources..." -NoNewline
try {
    $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:admin"))
    $headers = @{
        "Authorization" = "Basic $cred"
    }
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/datasources" -Headers $headers -TimeoutSec 5
    $ds_count = $response.Count
    
    if ($ds_count -ge 2) {
        Write-Host " PASS ($ds_count datasources)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL ($ds_count/2 datasources)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host " FAIL (Auth or query error)" -ForegroundColor Red
    $failed++
}

# Summary
Write-Host ""
Write-Host "=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Passed: $passed/8" -ForegroundColor Green
Write-Host "Failed: $failed/8" -ForegroundColor Red

if ($failed -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS! Observability stack çalışıyor." -ForegroundColor Green
    Write-Host ""
    Write-Host "Erişim Adresleri:" -ForegroundColor Yellow
    Write-Host "  Prometheus: http://localhost:9090"
    Write-Host "  Grafana:    http://localhost:3000 (admin/admin)"
    Write-Host "  Loki:       http://localhost:3100"
    Write-Host "  API Metrics: http://localhost:8000/metrics"
    exit 0
} else {
    Write-Host ""
    Write-Host "FAILED! Sorunları düzeltin." -ForegroundColor Red
    Write-Host "Detaylı log için: docker compose logs <service_name>"
    exit 1
}
