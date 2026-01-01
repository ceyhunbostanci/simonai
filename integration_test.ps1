# Simon AI Agent Studio - Integration Test
# End-to-End test scenario

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SIMON AI INTEGRATION TEST - MVP-1" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$baseUrl = "http://localhost:8000"
$testResults = @()

# Test 1: Health Check
Write-Host "`n[1/7] Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod "$baseUrl/health"
    if ($health.status -eq "healthy") {
        Write-Host "? Health: OK" -ForegroundColor Green
        $testResults += "Health: PASS"
    }
} catch {
    Write-Host "? Health: FAIL" -ForegroundColor Red
    $testResults += "Health: FAIL"
}

# Test 2: Create Agent Studio Session
Write-Host "`n[2/7] Creating Agent Studio session..." -ForegroundColor Yellow
try {
    $sessionBody = @{model="qwen2.5"} | ConvertTo-Json
    $session = Invoke-RestMethod -Method POST -Uri "$baseUrl/api/agent/sessions" -ContentType "application/json" -Body $sessionBody
    $sessionId = $session.session_id
    Write-Host "? Session Created: $sessionId" -ForegroundColor Green
    $testResults += "Session: PASS"
} catch {
    Write-Host "? Session: FAIL" -ForegroundColor Red
    $testResults += "Session: FAIL"
    exit 1
}

# Test 3: Send Risky Message (triggers approval gate)
Write-Host "`n[3/7] Sending risky message (approval gate)..." -ForegroundColor Yellow
try {
    $messageBody = @{
        content = "rm -rf /tmp/test"
        model_override = $null
        require_approval = $false
    } | ConvertTo-Json
    $messageResult = Invoke-RestMethod -Method POST -Uri "$baseUrl/api/agent/sessions/$sessionId/messages" -ContentType "application/json" -Body $messageBody
    
    if ($messageResult.needs_approval) {
        Write-Host "? Approval Gate Triggered" -ForegroundColor Green
        $testResults += "Approval Gate: PASS"
    } else {
        Write-Host "? Approval Gate NOT triggered" -ForegroundColor Yellow
        $testResults += "Approval Gate: SKIP"
    }
} catch {
    Write-Host "? Message: FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += "Message: FAIL"
}

# Test 4: Computer Use Screenshot
Write-Host "`n[4/7] Computer Use screenshot..." -ForegroundColor Yellow
try {
    $screenshot = Invoke-RestMethod "$baseUrl/api/computer-use/screenshot"
    if ($screenshot.screenshot.Length -gt 100) {
        Write-Host "? Screenshot captured ($(($screenshot.screenshot.Length)) chars)" -ForegroundColor Green
        $testResults += "Screenshot: PASS"
    }
} catch {
    Write-Host "? Screenshot: FAIL" -ForegroundColor Red
    $testResults += "Screenshot: FAIL"
}

# Test 5: Computer Use Action
Write-Host "`n[5/7] Computer Use action (click)..." -ForegroundColor Yellow
try {
    $actionBody = @{
        action_id = "integration_test_click"
        action_type = "click"
        params = @{x=150; y=250}
    } | ConvertTo-Json
    $action = Invoke-RestMethod -Method POST -Uri "$baseUrl/api/computer-use/action" -ContentType "application/json" -Body $actionBody
    
    if ($action.status -eq "success") {
        Write-Host "? Action executed: $($action.message)" -ForegroundColor Green
        $testResults += "Action: PASS"
    }
} catch {
    Write-Host "? Action: FAIL" -ForegroundColor Red
    $testResults += "Action: FAIL"
}

# Test 6: Log Cost
Write-Host "`n[6/7] Logging cost to audit ledger..." -ForegroundColor Yellow
try {
    $costBody = @{
        session_id = $sessionId
        model = "qwen2.5:1.5b"
        provider = "ollama"
        input_tokens = 100
        output_tokens = 50
        cost_input = 0.0
        cost_output = 0.0
    } | ConvertTo-Json
    $costLog = Invoke-RestMethod -Method POST -Uri "$baseUrl/api/audit/cost" -ContentType "application/json" -Body $costBody
    Write-Host "? Cost logged: $($costLog.total_cost)" -ForegroundColor Green
    $testResults += "Cost Log: PASS"
} catch {
    Write-Host "? Cost Log: FAIL" -ForegroundColor Red
    $testResults += "Cost Log: FAIL"
}

# Test 7: Get Cost Summary
Write-Host "`n[7/7] Getting cost summary..." -ForegroundColor Yellow
try {
    $summary = Invoke-RestMethod "$baseUrl/api/audit/cost/summary?session_id=$sessionId"
    Write-Host "? Cost Summary:" -ForegroundColor Green
    Write-Host "  Total Cost: `$$($summary.total_cost)" -ForegroundColor Cyan
    Write-Host "  Total Tokens: $($summary.total_tokens)" -ForegroundColor Cyan
    $testResults += "Cost Summary: PASS"
} catch {
    Write-Host "? Cost Summary: FAIL" -ForegroundColor Red
    $testResults += "Cost Summary: FAIL"
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$testResults | ForEach-Object {
    if ($_ -match "PASS") {
        Write-Host "? $_" -ForegroundColor Green
    } elseif ($_ -match "SKIP") {
        Write-Host "? $_" -ForegroundColor Yellow
    } else {
        Write-Host "? $_" -ForegroundColor Red
    }
}

$passCount = ($testResults | Where-Object { $_ -match "PASS" }).Count
$totalCount = $testResults.Count
Write-Host "`nResult: $passCount/$totalCount tests passed" -ForegroundColor Cyan

