# bootstrap_automation_os.ps1
# Amaç: Automation OS repo iskeletini kurar (docs + ops + scripts)
# Güvenli: Var olan dosyaları EZMEZ (yalnızca yoksa oluşturur)

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Ensure-Dir($p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }
function Ensure-File($p, $content) {
  if (-not (Test-Path $p)) {
    $dir = Split-Path -Parent $p
    Ensure-Dir $dir
    Set-Content -Path $p -Value $content -Encoding UTF8
  }
}

# Klasörler
Ensure-Dir "$Root\docs"
Ensure-Dir "$Root\ops"
Ensure-Dir "$Root\scripts"
Ensure-Dir "$Root\workflows"
Ensure-Dir "$Root\agents"

# .gitignore + env template
Ensure-File "$Root\.gitignore" @"
.env
.env.*
**/*.log
**/node_modules/
**/.venv/
**/__pycache__/
"@

Ensure-File "$Root\.env.template" @"
# KOPYA: .env olarak kaydet (git'e girmez)
# --- LLM Keys ---
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
DEEPSEEK_API_KEY=
GOOGLE_API_KEY=

# --- Budget (USD/month) ---
BUDGET_USD_MONTH=40

# --- Orchestrator endpoints (ileride) ---
N8N_WEBHOOK_URL=
"@

# Dokümanlar (Automation OS)
Ensure-File "$Root\docs\PROJECT_STATE.md" @"
# PROJECT_STATE

## Amaç
- Projenin tek gerçek durumu (SoR)

## Son Durum
- Tarih:
- Cihaz:
- Yapılan:
- Sonraki Adım:

## Risk/Blokaj
- Yok
"@

Ensure-File "$Root\docs\RUN_LOG.md" @"
# RUN_LOG

> Her oturum sonu: tarih/saat, yapılan işler, komutlar, sonuçlar, maliyet notu.

## Log Kayıtları
- (Boş)
"@

Ensure-File "$Root\docs\ARCHITECTURE.md" @"
# ARCHITECTURE

## Pipeline (Değişmez)
Claude Code -> Open Interpreter -> Git CLI -> SSH -> Computer Use (gerekirse)

## Katmanlar
- Orchestrator
- LLM Gateway (routing + budget + cache)
- UI Runner (Playwright/Computer Use)
- Approval Gate (LOW/MED/HIGH)
- Audit & Telemetry
"@

Ensure-File "$Root\docs\SECURITY.md" @"
# SECURITY

## İlkeler
- Key/şifre asla kodda değil (.env)
- Domain allowlist (Computer Use / Playwright)
- Riskli işlemlerde Approval Gate

## Onay Kapıları
- LOW: otomatik
- MED: otomatik + log
- HIGH: manuel onay
"@

Ensure-File "$Root\docs\MODEL_ROUTING.md" @"
# MODEL_ROUTING (40$ stratejisi)

## Kural
- %80: DeepSeek-V3 (işçilik)
- %15: Gemini Flash (multimodal gözlem)
- %5: GPT-5.2 Thinking / Claude Sonnet (kilit açıcı)

## Amaç
- Abonelik yerine pay-as-you-go ile bütçe kontrolü
"@

Ensure-File "$Root\docs\COST_BUDGET.md" @"
# COST_BUDGET

## Aylık Limit
BUDGET_USD_MONTH = 40

## Cost Ledger
- Tarih | İş | Model | Tahmini Token | Tahmini $ | Not
"@

Ensure-File "$Root\docs\APPROVAL_GATE.md" @"
# APPROVAL_GATE

## Risk Sınıfları
- LOW: read-only, rapor üretimi, taslak
- MED: kod değişikliği (test zorunlu), sınırlı deploy
- HIGH: prod deploy, credential değişimi, ödeme/finans aksiyonu, veri silme

## Standart
- HIGH işlemler: manuel onay olmadan ilerlemez
"@

Ensure-File "$Root\ops\allowlist_domains.txt" @"
# Computer Use / Playwright allowlist
# Örnek:
# github.com
# api.openai.com
# console.anthropic.com
"@

Ensure-File "$Root\scripts\status.ps1" @"
# status.ps1
Write-Host "=== Automation OS Status ==="
Write-Host "Root: $PSScriptRoot"
Write-Host "Docs:"
Get-ChildItem "$PSScriptRoot\..\docs" | Select-Object Name
"@

# Git init (varsa) - otomatik ama güvenli
if (-not (Test-Path "$Root\.git")) {
  try {
    git -v *> $null
    git init $Root | Out-Null
  } catch { }
}

Write-Host "OK: Automation OS iskeleti hazır."
Write-Host "Kontrol: powershell -ExecutionPolicy Bypass -File .\scripts\status.ps1"
