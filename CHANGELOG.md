# Changelog

Tüm önemli değişiklikler bu dosyada dokümante edilir.

Format [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) standardına uygundur.

## [3.1.0] - 2025-12-27

### Added
- ✅ Monorepo yapısı (Turbo + workspaces)
- ✅ 6-katmanlı mimari (Orchestrator, LiteLLM, UI Runner, Egress Proxy, Approval Gate, Telemetry)
- ✅ Docker Compose ortamı (production + development)
- ✅ CI/CD pipeline (GitHub Actions)
- ✅ Sürüm yönetimi ve rollback sistemi
- ✅ Environment configuration (.env template)
- ✅ Güvenlik: Credential isolation, egress proxy allowlist
- ✅ Multi-model routing (Claude, GPT, Gemini, Ollama)
- ✅ Key Modes: FREE (Ollama), FREE+ (Sponsorlu), BYOK
- ✅ Risk-based approval gates (LOW/MEDIUM/HIGH)
- ✅ Cost tracking ve budget enforcement
- ✅ Audit logging ve compliance framework

### Technical Details
- FastAPI backend (Orchestrator)
- Next.js frontend (Web + Admin)
- LiteLLM Gateway (AI Router)
- Playwright (Browser Automation)
- Squid Proxy (Egress Control)
- PostgreSQL 16 (Database)
- Redis 7 (Cache + Queue)
- Celery (Worker Queue)

### Security
- API keys NEVER reach UI Runner
- All external traffic via allowlist proxy
- Screenshot auto-purge (30 days, GDPR)
- Idempotency keys for safe retries
- Structured audit logs (tamper-evident)

### Cost Optimization
- Month 1: $68
- Steady State: $41/month
- 90% savings via prompt caching
- Ollama for zero-cost local models

### Documentation
- README with quick start
- Architecture overview
- Deployment guide
- Security standards
- API reference (upcoming)

---

## Versioning Strategy

- **Major (X.0.0)**: Breaking changes, major architecture updates
- **Minor (x.Y.0)**: New features, backward compatible
- **Patch (x.y.Z)**: Bug fixes, security patches

**Current Version:** v3.1.0 (Production Ready)
**Next Milestone:** v3.2.0 (Chat MVP - Faz 1)
