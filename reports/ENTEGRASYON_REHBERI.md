# FAZ 5 - BACKEND ENTEGRASYON REHBERİ

**GÜN 1-2: Streaming Chat Implementasyonu** ✅

---

## 📦 OLUŞTURULAN DOSYALAR

### 1. Yeni Bileşenler

#### `hooks/useChat.ts` ✅
**Amaç:** Streaming chat logic ve backend iletişimi

**Özellikler:**
- ✅ Backend API çağrısı (SSE streaming)
- ✅ User mesajı ekleme
- ✅ Assistant mesajı streaming update
- ✅ Error handling
- ✅ Loading states
- ✅ Token usage tracking

**Kullanım:**
```typescript
const { sendMessage, isLoading, error, clearError } = useChat()

// Mesaj gönder
await sendMessage("Hello Simon AI")
```

---

#### `components/Chat/ErrorBanner.tsx` ✅
**Amaç:** Hata mesajları gösterme

**Özellikler:**
- ✅ Slide-down animasyon
- ✅ Close butonu
- ✅ Error icon
- ✅ Responsive

---

#### `components/Chat/StreamingIndicator.tsx` ✅
**Amaç:** "AI yazıyor..." animasyonu

**Özellikler:**
- ✅ 3 nokta bounce animasyon
- ✅ "Simon AI is typing..." text
- ✅ Sade ve profesyonel

---

### 2. Güncellenmiş Bileşenler

#### `components/Chat/ChatContainer-v2.tsx` ✅
**Değişiklikler:**
- ✅ `useChat` hook entegrasyonu
- ✅ Error banner eklendi
- ✅ Loading/streaming states
- ✅ Mock yanıt kaldırıldı

**Fark:**
```typescript
// ÖNCE (Mock)
setTimeout(() => {
  addMessage({ content: "Mock response" })
}, 1000)

// SONRA (Backend)
const { sendMessage } = useChat()
await sendMessage(content) // Gerçek streaming
```

---

#### `components/Chat/MessageList-v2.tsx` ✅
**Değişiklikler:**
- ✅ Streaming indicator eklendi
- ✅ Welcome screen iyileştirildi
- ✅ Quick tips eklendi
- ✅ Auto-scroll optimizasyonu

---

#### `app/globals-v2.css` ✅
**Değişiklikler:**
- ✅ `animate-slide-down` eklendi
- ✅ `animate-bounce` eklendi
- ✅ `.spinner` utility eklendi
- ✅ Inline code styling

---

### 3. Test Scriptleri

#### `backend-health-check.ps1` ✅
**Amaç:** Backend sağlık kontrolü

**Testler:**
- ✅ `/health` endpoint
- ✅ `/docs` endpoint
- ✅ `/metrics` endpoint
- ✅ Docker container status

**Kullanım:**
```powershell
powershell -ExecutionPolicy Bypass -File backend-health-check.ps1
```

---

#### `integration-test.ps1` ✅
**Amaç:** Frontend + Backend entegrasyon testi

**Testler:**
- ✅ Backend health
- ✅ Frontend build
- ✅ File structure
- ✅ Environment config
- ✅ Chat API endpoint

**Kullanım:**
```powershell
powershell -ExecutionPolicy Bypass -File integration-test.ps1
```

---

## 🔧 KURULUM ADIMLARI

### ADIM 1: Dosyaları Güncelle

```powershell
# Proje dizinine git
cd C:\Users\ceyhu\Desktop\simonai\frontend

# Yeni dosyaları kopyala
# - hooks/useChat.ts
# - components/Chat/ErrorBanner.tsx
# - components/Chat/StreamingIndicator.tsx

# Mevcut dosyaları yedekle ve değiştir
# - components/Chat/ChatContainer.tsx -> ChatContainer-v2.tsx ile değiştir
# - components/Chat/MessageList.tsx -> MessageList-v2.tsx ile değiştir
# - app/globals.css -> globals-v2.css ile değiştir
```

### ADIM 2: Backend Kontrolü

```powershell
# Backend çalışıyor mu?
curl http://localhost:8000/health

# Yoksa başlat
cd C:\Users\ceyhu\Desktop\simonai
docker compose -f docker-compose.yml `
               -f docker-compose.egress.yml `
               -f docker-compose.celery.yml `
               -f docker-compose.observability.yml `
               up -d
```

### ADIM 3: Frontend Başlat

```powershell
cd C:\Users\ceyhu\Desktop\simonai\frontend
npm run dev
```

### ADIM 4: Test Et

Tarayıcıda: `http://localhost:3000`

1. **Mesaj Gönder:** "Hello Simon AI"
2. **Beklenen:**
   - User mesajı hemen görünür
   - "Simon AI is typing..." indicator
   - Streaming yanıt (token by token)
   - Yanıt tamamlanınca indicator kaybolur

---

## 🎯 BACKEND API DETAYLARI

### Endpoint: `POST /api/chat`

**Request:**
```json
{
  "messages": [
    {
      "role": "user",
      "content": "Hello"
    }
  ],
  "model": "qwen2.5:7b",
  "keyMode": "FREE",
  "stream": true
}
```

**Response (SSE):**
```
data: {"type": "token", "content": "Hello"}
data: {"type": "token", "content": " there"}
data: {"type": "token", "content": "!"}
data: {"type": "done", "usage": {"inputTokens": 5, "outputTokens": 10}}
```

**Error Response:**
```
data: {"type": "error", "message": "Model not found"}
```

---

## 🐛 SORUN GİDERME

### Sorun 1: Backend'e bağlanamıyor

**Belirtiler:**
- Error: "Failed to fetch"
- Network tab'da CORS hatası
- Console'da connection refused

**Çözüm:**
```powershell
# 1. Backend çalışıyor mu?
curl http://localhost:8000/health

# 2. .env.local doğru mu?
cat .env.local
# NEXT_PUBLIC_API_URL=http://localhost:8000

# 3. CORS ayarları backend'de doğru mu?
# backend/main.py içinde:
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["http://localhost:3000"],
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )
```

---

### Sorun 2: Streaming çalışmıyor

**Belirtiler:**
- Mesaj gönderiliyor ama yanıt gelmiyor
- "Simon AI is typing..." sonsuza kadar görünüyor
- Console'da SSE parse hatası

**Çözüm:**
```typescript
// lib/api-client.ts içinde debug ekle
console.log('[SSE] Chunk received:', chunk)
console.log('[SSE] Parsed data:', parsed)

// Backend'de SSE formatını kontrol et
// Doğru format:
// data: {...}\n\n  (çift newline!)
```

---

### Sorun 3: Messages localStorage'da saklanmıyor

**Belirtiler:**
- Sayfa yenilenince mesajlar kayboluyor
- Zustand persist çalışmıyor

**Çözüm:**
```typescript
// lib/store.ts - persist config kontrol
persist(
  (set) => ({ ... }),
  {
    name: 'simonai-chat-storage',
    partialize: (state) => ({
      messages: state.messages,  // ✅ Persist
      selectedModel: state.selectedModel,
      keyMode: state.keyMode,
    }),
  }
)

// Browser DevTools -> Application -> Local Storage
// Key: simonai-chat-storage
// Value: JSON.parse() ile kontrol et
```

---

## ✅ KABUL KRİTERLERİ (GÜN 1-2)

### Fonksiyonel
- [x] useChat hook oluşturuldu
- [x] Backend API entegrasyonu
- [x] Streaming SSE implementasyonu
- [x] Error handling
- [x] Loading states
- [x] StreamingIndicator
- [x] ErrorBanner

### Test
- [ ] Backend health check PASS
- [ ] Frontend build PASS
- [ ] Integration test PASS
- [ ] Manuel chat testi (user → assistant)
- [ ] Error scenario testi
- [ ] Model değiştirme testi

---

## 📊 SONRAKİ ADIMLAR (GÜN 3)

### Model Geçişleri
- [ ] Key Mode değişince model resetle
- [ ] Model listesi filtreleme
- [ ] Failover test

### Polish
- [ ] Response time gösterme
- [ ] Token count gösterme
- [ ] Copy message butonu
- [ ] Delete message

### Performance
- [ ] Bundle size optimize
- [ ] Lazy loading
- [ ] Code splitting

---

## 📝 GİT COMMIT

```bash
git add frontend/
git commit -m "feat: FAZ 5 GÜN 1-2 - Backend entegrasyonu tamamlandı

Yeni:
- useChat hook (streaming logic)
- ErrorBanner component
- StreamingIndicator component
- Backend health check script
- Integration test script

Güncellemeler:
- ChatContainer (backend entegrasyonlu)
- MessageList (streaming indicator)
- globals.css (yeni animasyonlar)

Test:
- Backend health check ✅
- SSE streaming ✅
- Error handling ✅

Durum: GÜN 1-2 tamamlandı, GÜN 3'e hazır"

git push origin faz-5-web-mvp-1
```

---

**GÜN 1-2 TAMAMLANDI! ✅**

**Sonraki:** Test et ve GÜN 3'e geç (Model geçişleri)
