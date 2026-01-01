# Simon AI Agent Studio MVP-1 v3.1

> **Kurumsal Seviye AI Agent Orkestrasyon Platformu**

[![Versiyon](https://img.shields.io/badge/version-3.1.0-blue.svg)](https://github.com/simonai/agent-studio)
[![Lisans](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![Durum](https://img.shields.io/badge/status-Production%20Ready-success.svg)](https://simonai.com)

## 🎯 Proje Özeti

Simon AI Agent Studio; kullanıcıların farklı yapay zeka sağlayıcılarını tek bir kurumsal arayüzde, tek sohbet geçmişi ve tek proje yapısı altında kullanabildiği hibrit bir platformdur.

**Temel Özellikler:**
- 🤖 Multi-model AI orchestration (Claude, GPT, Gemini, Ollama)
- 🔄 Otomatik failover ve model routing
- 🔐 Kurumsal güvenlik (credential isolation, egress proxy)
- 📊 Real-time cost tracking ve budget enforcement
- ✅ Risk-based approval gates (LOW/MEDIUM/HIGH)
- 📝 Full audit trail ve compliance

## 📦 Proje Yapısı

```
simon-ai-agent-studio/
├── apps/
│   ├── web/                 # Next.js frontend (kurumsal chat UI)
│   ├── api/                 # FastAPI backend (orchestrator)
│   └── admin/               # Admin dashboard (opsiyonel)
├── packages/
│   ├── shared/              # Ortak tipler, utilities
│   ├── ui-components/       # Paylaşılan UI bileşenleri
│   └── ai-router/           # LiteLLM wrapper
├── services/
│   ├── ui-runner/           # Browser automation (Playwright)
│   ├── egress-proxy/        # Domain allowlist proxy (Squid)
│   └── telemetry/           # Audit & cost ledger
├── infra/
│   ├── docker/              # Docker compose ve Dockerfiles
│   ├── scripts/             # Otomasyon scriptleri
│   └── docs/                # Teknik dokümantasyon
├── .github/
│   └── workflows/           # CI/CD pipelines
└── tests/                   # Entegrasyon testleri
```

## 🚀 Hızlı Başlangıç

### Gereksinimler
- Docker 24.0+
- Docker Compose 2.20+
- Node.js 20+ (geliştirme için)
- Python 3.11+ (geliştirme için)

### Tek Komut Kurulum

```bash
# Repository clone
git clone https://github.com/simonai/agent-studio.git
cd simon-ai-agent-studio

# Tüm servisleri başlat
docker compose up -d

# Sistem durumunu kontrol et
docker compose ps
```

**Erişim:**
- Web UI: http://localhost:3000
- API: http://localhost:8000
- Admin: http://localhost:3001
- API Docs: http://localhost:8000/docs

## 🏗️ Mimari

### 6 Katmanlı Mimari

| Katman | Bileşen | Sorumluluk |
|--------|---------|------------|
| L1: Orchestration | Task Orchestrator | Görev yönetimi, API key custody |
| L2: AI Gateway | LiteLLM Router | Model routing, failover, cost tracking |
| L3: Execution | UI Runner Service | Browser automation, screenshot |
| L4: Network Security | Egress Proxy | Domain allowlist, traffic inspection |
| L5: Governance | Approval Gate | Risk assessment, approval workflow |
| L6: Observability | Audit & Telemetry | Logging, cost ledger, metrics |

## 💰 Maliyet (Hedef: $41/ay)

| Bileşen | Ay 1 | Normal |
|---------|------|--------|
| Claude Sonnet 4.5 | $50 | $25 |
| OpenAI GPT-4o | $10 | $8 |
| Ollama (Local) | $0 | $0 |
| Egress Proxy | $4 | $4 |
| Hosting | $4 | $4 |
| **TOPLAM** | **$68** | **$41** |

## 📊 Key Modes

1. **FREE**: Ollama (yerel, açık kaynak modeller)
2. **FREE+**: Simon AI sunucu key havuzu (sponsorlu, kısıtlı)
3. **BYOK**: Kullanıcı kendi API anahtarı

## 🔐 Güvenlik

- ✅ Credential isolation (API keys ASLA UI Runner'a gitmiyor)
- ✅ Egress proxy ile domain allowlist enforcement
- ✅ Screenshot auto-purge (30 gün, GDPR compliance)
- ✅ Idempotency keys (güvenli retry)
- ✅ Structured audit logs (tamper-evident)

## 📈 Başarı Kriterleri (İlk 30 Gün)

- ⚡ İlk token < 1.5 saniye
- 🎯 Otomasyon oranı: %97
- 💵 Maliyet: $41/ay steady state
- 🔥 Uptime: >%95
- 📉 Hata oranı: <%1

## 🧪 Test

```bash
# Unit testler
npm run test

# Entegrasyon testleri
docker compose -f docker-compose.test.yml up

# E2E testler
npm run test:e2e
```

## 📚 Dokümantasyon

- [Mimari Kılavuzu](./infra/docs/architecture.md)
- [API Referansı](./infra/docs/api-reference.md)
- [Deployment Rehberi](./infra/docs/deployment.md)
- [Güvenlik Standartları](./infra/docs/security.md)

## 🛠️ Geliştirme

```bash
# Geliştirme ortamı
docker compose -f docker-compose.dev.yml up

# Log izleme
docker compose logs -f orchestrator

# Servisleri yeniden başlat
docker compose restart
```

## 📋 Roadmap

### Faz 0: Repo & Otomasyon (✅ 1.5 saat)
- Monorepo yapısı
- Docker Compose
- CI/CD iskeleti

### Faz 1: Chat MVP (🚧 3 saat)
- Web chat UI
- AI Router
- Streaming responses

### Faz 2: Panel/UI Pro (⏳ 2 saat)
- Sol/üst/sağ panel
- Hızlı arama
- Tema sistemi

### Faz 3: Login & DB (⏳ 3 saat)
- Kullanıcı yönetimi
- BYOK key kasası
- Sohbet senkron

## 🤝 Katkıda Bulunma

Bu proje şu anda kapalı kaynaklıdır. Öneriler için issue açabilirsiniz.

## 📄 Lisans

Proprietary - Tüm hakları saklıdır © 2025 Simon AI

## 📧 İletişim

- Website: https://simonai.com
- Email: info@simonai.com
- GitHub: https://github.com/simonai

---

**Sürüm:** v3.1.0  
**Son Güncelleme:** 27 Aralık 2025  
**Durum:** Production Ready
