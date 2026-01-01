# Simon AI Agent Studio - Mimari Dokümantasyon

## 📐 Sistem Mimarisi

### Genel Bakış

Simon AI Agent Studio, 6 katmanlı mikroservis mimarisine sahip, kurumsal seviye bir AI agent orkestrasyon platformudur.

### Tasarım Prensipleri

1. **Separation of Concerns**: Her katman tek bir sorumluluğa sahiptir
2. **Defense in Depth**: Çok katmanlı güvenlik
3. **Least Privilege**: Minimum erişim hakları
4. **Observability**: Kapsamlı logging ve metrik toplama
5. **Fault Tolerance**: Graceful degradation
6. **Cost Awareness**: Real-time maliyet takibi

## 🏗️ 6 Katmanlı Mimari

### L1: Orchestration (Orkestratör)
**Bileşen**: Task Orchestrator (FastAPI)

**Sorumluluklar**:
- Görev analizi ve alt görevlere bölme
- API key custody (anahtarlar SADECE burada)
- Model seçimi ve routing stratejisi
- Workflow state management
- Risk skorlama

**Teknolojiler**: FastAPI, PostgreSQL, Redis, Celery

**Kritik Noktalar**:
- API anahtarları ASLA UI Runner'a gitmiyor
- Her görev için benzersiz idempotency key
- Tüm işlemler audit log'a kaydediliyor

### L2: AI Gateway (LiteLLM Router)
**Bileşen**: LiteLLM Gateway

**Sorumluluklar**:
- Model abstraction layer
- Request routing (cost-based, latency-based)
- Automatic failover
- Token tracking ve cost aggregation
- Prompt caching (%90 maliyet tasarrufu)

**Teknolojiler**: LiteLLM, Redis (cache)

**Routing Stratejileri**:
- Cost-based: En ucuz modeli seç
- Latency-based: En hızlı modeli seç
- Load-balanced: Yükü dağıt
- Fallback: Hata durumunda alternatif model

### L3: Execution (UI Runner Service)
**Bileşen**: Browser Automation Worker

**Sorumluluklar**:
- Computer Use döngüsü (screenshot → action → tool_result)
- Browser automation (Playwright)
- Screenshot capture ve evidence collection
- Idempotency enforcement
- Result packaging

**Teknolojiler**: Python, Playwright, Celery

**MVP-1 Kapsamı**: Browser Sandbox
**MVP-2 Planı**: Desktop VM (VNC/RDP)

**Kritik Güvenlik**:
- ZERO API key access
- Tüm egress traffic Proxy üzerinden
- Screenshot auto-purge (30 gün, GDPR)

### L4: Network Security (Egress Proxy)
**Bileşen**: Squid Proxy

**Sorumluluklar**:
- Domain allowlist enforcement
- Traffic inspection
- Request logging
- Protocol validation

**Teknolojiler**: Squid Proxy, iptables

**Allowlist Domains** (MVP-1):
- .anthropic.com
- .openai.com
- .googleapis.com
- .github.com
- .vercel.app
- .simonai.com

**Log Analizi**: Tüm denied requests forensic için loglanıyor

### L5: Governance (Approval Gate)
**Bileşen**: Approval Workflow Engine

**Sorumluluklar**:
- Risk assessment (LOW/MEDIUM/HIGH)
- Approval workflow yönetimi
- Timeout management (default: 5 dakika)
- Rollback coordination

**Risk Matris**:

| Risk Level | Örnekler | Onay | Timeout |
|------------|----------|------|---------|
| LOW | read_file, analyze_code | Otomatik | - |
| MEDIUM | write_code, deploy_staging | Bildirim | - |
| HIGH | deploy_production, delete_data, send_email | Zorunlu | 5 dk |

**Approval Flow**:
1. Task → Risk assessment
2. HIGH risk → Onay ekranı (WebSocket)
3. Kullanıcı/Admin onayı
4. Timeout (5 dk) → Otomatik red
5. Rollback planı zorunlu

### L6: Observability (Audit & Telemetry)
**Bileşen**: Logging, Metrics, Tracing

**Sorumluluklar**:
- Structured logging (JSON)
- Cost ledger (her API call)
- Approval ledger
- Screenshot archival
- Metrics collection
- Alerting

**Veri Katmanları**:
- **audit_logs**: Tamper-evident log kayıtları
- **cost_ledger**: Token ve maliyet tracking
- **usage_events**: Performance metrikleri
- **approval_ledger**: Onay geçmişi

**Retention Policies**:
- Logs: 90 gün
- Screenshots: 30 gün (GDPR)
- Metrics: 1 yıl (aggregated)
- Audit logs: 7 yıl (compliance)

## 🔄 Veri Akışı

### Tipik Task Yürütme Akışı

```
1. User Prompt
   ↓
2. Orchestrator → Risk Assessment
   ↓
3. [HIGH Risk] → Approval Gate → User Confirmation
   ↓
4. LiteLLM Gateway → Model Selection
   ↓
5. Orchestrator → Plan Generation (Claude Sonnet 4.5)
   ↓
6. Sub-tasks → Celery Queue
   ↓
7. UI Runner Workers → Browser Automation
   ↓
8. Egress Proxy → Allowed Domains Only
   ↓
9. Screenshot → Evidence Storage
   ↓
10. Results → Orchestrator → Validation
   ↓
11. Cost Ledger Update
   ↓
12. Audit Log Entry
   ↓
13. User Notification
```

### Güvenlik Katmanları

**Layer 1: Network (Egress Proxy)**
- Squid proxy ile domain allowlist
- Tüm traffic logged
- DPI (Deep Packet Inspection)

**Layer 2: Credential Isolation**
- API keys SADECE Orchestrator + LiteLLM
- UI Runner ZERO access
- Secrets: Environment variables (Prod: HashiCorp Vault)
- Auto-rotation: 90 gün

**Layer 3: Data Privacy (GDPR/KVKK)**
- Screenshot TTL: 30 gün auto-purge
- PII detection & masking
- GDPR Article 17 compliance (Right to Erasure)
- Encryption: AES-256 at rest, TLS 1.3 in transit

**Layer 4: Access Control**
- RBAC (Role-Based Access Control)
- MFA (Multi-Factor Authentication) - Production
- Session timeout: 15 dakika
- Principle of least privilege

**Layer 5: Audit & Compliance**
- %100 action logging (structured JSON)
- Tamper-evident audit trail (append-only DB)
- Cost ledger + Approval ledger
- SOC 2 Type II hazırlığı (future)

## 🎯 Key Modes

### FREE (Ollama - Lokal)
- Kullanıcının cihazında çalışan açık kaynak modeller
- Zero cost
- Minimum 15 model
- Privacy: Veriler lokal kalıyor

**Varsayılan Modeller**:
- gemma3, qwen2.5, qwen2.5-coder, phi4, llama3.3, mistral, deepseek-r1, llava

### FREE+ (Sponsorlu - Server Key Pool)
- Simon AI sunucusunda yönetilen key havuzu
- Sert kota + rate limit
- Abuse kontrolü zorunlu
- MVP'de minimal (cost kontrolü için)

**Limitler**:
- Günlük bütçe: $10
- Saatlik rate limit: 100 request
- Kullanıcı başına kota

### BYOK (Bring Your Own Key)
- Kullanıcı kendi API anahtarını girer
- Kalite/limit yönetimi kullanıcıya ait
- Platform sadece orchestration sağlıyor

**Varsayılan BYOK Modelleri**:
- Claude Sonnet 4.5 (primary)
- Claude Opus 4.5 (premium complex)
- GPT-4o (failover)
- Gemini 1.5 Pro (multimodal)

## 💰 Maliyet Optimizasyonu

### Hedef: $41/ay (Steady State)

| Bileşen | Ay 1 | Normal | Optimizasyon |
|---------|------|--------|--------------|
| Claude Sonnet 4.5 | $50 | $25 | Prompt caching (%90) |
| OpenAI GPT-4o | $10 | $8 | Batch processing |
| Ollama (Local) | $0 | $0 | Self-hosted |
| Egress Proxy | $4 | $4 | Hetzner VPS |
| Hosting (Vercel) | $4 | $4 | Free tier + CDN |
| **TOPLAM** | **$68** | **$41** | **Hedef başarıldı** |

### Cost Tracking

**Real-time Cost Ledger**:
- Her API call → token count → cost calculation
- Database: `cost_ledger` table
- Dashboard: Real-time cost visualization
- Alerts: %80 budget threshold

**Budget Enforcement**:
- Daily/monthly limits per user
- Auto-pause at limit
- Grace period için override (admin)

## 🧪 Test Stratejisi

### Test Piramidi

```
           /\
          /E2E\        ← 10% (Browser automation)
         /------\
        /INTEGR.\     ← 30% (API + DB + Redis)
       /----------\
      /   UNIT     \  ← 60% (Logic + utils)
     /--------------\
```

**Unit Tests**: Fast, isolated, %60 coverage
**Integration Tests**: Docker Compose, DB + Redis + API
**E2E Tests**: Playwright, full workflow simulation

### Test Ortamı

```bash
# Tüm testler
docker compose -f docker-compose.test.yml up

# Unit testler
npm run test

# E2E testler
npm run test:e2e
```

## 📊 Monitoring & Observability

### Metrics (Prometheus)

**System Metrics**:
- Request latency (p50, p95, p99)
- Error rate (5xx, timeout)
- Throughput (req/sec)

**Business Metrics**:
- Cost per task
- Automation success rate
- Model failover frequency

### Logging (Structured JSON)

**Log Levels**: DEBUG, INFO, WARN, ERROR, CRITICAL

**Log Format**:
```json
{
  "timestamp": "2025-12-27T10:30:00Z",
  "level": "INFO",
  "service": "orchestrator",
  "task_id": "uuid",
  "event": "task_completed",
  "duration_ms": 4523,
  "cost_usd": 0.045,
  "metadata": {}
}
```

### Alerting

**Critical Alerts** (PagerDuty):
- Service down >5 min
- Error rate >5%
- Budget >90%

**Warning Alerts** (Slack):
- Latency spike >2x baseline
- Failover triggered
- Approval timeout

## 🔐 Compliance

### GDPR/KVKK
- ✅ Right to access
- ✅ Right to erasure (30-day auto-purge)
- ✅ Data minimization
- ✅ Encryption at rest/transit
- ✅ Audit trail

### Future: SOC 2 Type II
- Security policies
- Access control
- Change management
- Incident response
- Business continuity

## 📚 İlgili Dokümantasyon

- [API Reference](./api-reference.md)
- [Deployment Guide](./deployment.md)
- [Security Standards](./security.md)
- [Cost Optimization](./cost-optimization.md)
- [Troubleshooting](./troubleshooting.md)

---

**Sürüm**: v3.1.0  
**Son Güncelleme**: 27 Aralık 2025  
**Durum**: Production Ready
