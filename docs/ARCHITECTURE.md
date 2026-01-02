# ARCHITECTURE

## Pipeline (DeÄŸiÅŸmez)
Claude Code -> Open Interpreter -> Git CLI -> SSH -> Computer Use (gerekirse)

## Katmanlar
- Orchestrator
- LLM Gateway (routing + budget + cache)
- UI Runner (Playwright/Computer Use)
- Approval Gate (LOW/MED/HIGH)
- Audit & Telemetry
