# SIMON AI - FAZ 5 DETAY PLANI
**Web MVP-1: Temel Chat UI**

**Süre:** 3-5 gün  
**Tarih:** 02-07 Ocak 2026  
**Durum:** BAŞLIYOR ⏳

---

## 📋 HEDEF VE KAPSAM

### Ana Hedef
Kullanıcının 10 saniye içinde chat yapabileceği, model seçebileceği ve streaming yanıt alabileceği temel web arayüzü.

### Kabul Kriteri
✅ 1 kullanıcı 5 dakikada:
- Chat başlatıyor
- Model değiştirebiliyor
- Streaming yanıt alıyor
- Mesajları kaydedebiliyor (localStorage)

---

## 🎯 TESLİMATLAR (MVP-1)

### 1. Next.js Proje Scaffold ✅
```
simonai/
├── frontend/              # Next.js 14+ App Router
│   ├── app/
│   │   ├── page.tsx      # Ana chat sayfası
│   │   ├── layout.tsx    # Root layout
│   │   └── api/
│   │       └── chat/
│   │           └── route.ts  # Chat API route
│   ├── components/
│   │   ├── Chat/
│   │   │   ├── ChatContainer.tsx
│   │   │   ├── MessageList.tsx
│   │   │   ├── MessageBubble.tsx
│   │   │   ├── ChatInput.tsx
│   │   │   └── StreamingIndicator.tsx
│   │   ├── Layout/
│   │   │   ├── Sidebar.tsx (iskelet)
│   │   │   └── TopBar.tsx (iskelet)
│   │   └── ModelSelector/
│   │       ├── ModelDropdown.tsx
│   │       └── KeyModeSelector.tsx
│   ├── lib/
│   │   ├── api-client.ts  # Backend API client
│   │   ├── storage.ts     # localStorage helper
│   │   └── types.ts       # TypeScript types
│   ├── hooks/
│   │   ├── useChat.ts
│   │   ├── useStreaming.ts
│   │   └── useLocalStorage.ts
│   ├── styles/
│   │   └── globals.css    # Tailwind + custom
│   └── public/
│       └── logo.svg
└── backend/               # Mevcut FastAPI (değişiklik yok)
```

### 2. Chat Bileşenleri
- **ChatContainer**: Ana chat layout
- **MessageList**: Mesaj akışı, auto-scroll
- **MessageBubble**: Tek mesaj bileşeni (user/assistant)
- **ChatInput**: Textarea + gönder butonu
- **StreamingIndicator**: "Typing..." animasyonu

### 3. Model Seçimi
- **ModelDropdown**: 15 FREE + 4 BYOK modelleri
- **KeyModeSelector**: FREE / FREE+ / BYOK
- Seçim localStorage'da saklanır

### 4. API Entegrasyonu
- Backend: `http://localhost:8000/api/chat` (streaming)
- Request: `{ messages, model, keyMode }`
- Response: SSE (Server-Sent Events)

### 5. State Yönetimi
- Zustand: Global state (messages, model, keyMode)
- React Query: API cache + retry
- localStorage: Persist messages (MVP'de login yok)

---

## 📦 TEKNOLOJİ STACK

### Frontend
- **Framework**: Next.js 14.x (App Router)
- **UI Library**: shadcn/ui + Tailwind CSS
- **State**: Zustand + React Query
- **Streaming**: EventSource (SSE)
- **Icons**: Lucide React
- **Deployment**: Vercel (otomatik)

### Bağımlılıklar
```json
{
  "dependencies": {
    "next": "^14.2.0",
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "zustand": "^4.5.0",
    "@tanstack/react-query": "^5.0.0",
    "tailwindcss": "^3.4.0",
    "lucide-react": "^0.400.0"
  }
}
```

---

## 🔧 IMPLEMENTASYON ADIMLARI

### GÜN 1: Scaffold + Temel Layout (4-6 saat)
```bash
# 1. Next.js projesi oluştur
npx create-next-app@latest frontend --typescript --tailwind --app

# 2. shadcn/ui ekle
npx shadcn-ui@latest init

# 3. Bağımlılıkları kur
cd frontend
npm install zustand @tanstack/react-query lucide-react

# 4. Temel layout oluştur
# - app/layout.tsx
# - components/Layout/Sidebar.tsx (iskelet)
# - components/Layout/TopBar.tsx (iskelet)
```

**Teslimat**: Sayfa yükleniyor, boş layout görünüyor

---

### GÜN 2: Chat UI + Mesaj Akışı (6-8 saat)
```typescript
// components/Chat/ChatContainer.tsx
// - MessageList (scroll container)
// - ChatInput (textarea + send button)
// - Mock mesajlar ile test

// lib/storage.ts
// - saveMessages()
// - loadMessages()
// - clearMessages()
```

**Teslimat**: Mesaj gönderme/alma çalışıyor (mock data)

---

### GÜN 3: Model Seçimi + Backend Entegrasyon (6-8 saat)
```typescript
// components/ModelSelector/
// - FREE: 15 model listesi
// - BYOK: 4 model listesi
// - KeyMode dropdown

// lib/api-client.ts
// - streamChat() - SSE client
// - Backend: http://localhost:8000/api/chat

// hooks/useStreaming.ts
// - EventSource wrapper
// - Token by token render
```

**Teslimat**: Backend'den streaming yanıt alınıyor

---

### GÜN 4-5: Polish + Test + Deploy (4-6 saat)
- Loading states
- Error handling
- Responsive design test
- Vercel deployment
- End-to-end test

**Teslimat**: Production'da çalışan MVP

---

## 🎨 UI/UX STANDARTLARI

### Renk Paleti (Dark Mode)
```css
--background: #0f172a;      /* slate-950 */
--foreground: #f1f5f9;      /* slate-100 */
--primary: #0ea5e9;         /* sky-500 */
--secondary: #64748b;       /* slate-500 */
--border: #334155;          /* slate-700 */
--error: #ef4444;           /* red-500 */
--success: #10b981;         /* green-500 */
```

### Tipografi
```css
font-family: 'Inter', sans-serif;
font-size: 14px (base)
line-height: 1.5
```

### Spacing
```
4px grid system
Padding: 16px (container)
Gap: 12px (elements)
```

---

## 🔌 API ENTEGRASYON

### Backend Endpoint (Mevcut)
```http
POST http://localhost:8000/api/chat
Content-Type: application/json

{
  "messages": [
    {"role": "user", "content": "Hello"}
  ],
  "model": "claude-sonnet-4.5",
  "keyMode": "BYOK"
}
```

### Response (SSE)
```
data: {"type": "token", "content": "Hello"}
data: {"type": "token", "content": " there"}
data: {"type": "done", "usage": {...}}
```

---

## ✅ KABUL KRİTERLERİ

### Fonksiyonel
- [ ] Chat arayüzü yükleniyor (< 3 saniye)
- [ ] Model seçimi değiştirilebiliyor
- [ ] Key Mode seçimi değiştirilebiliyor
- [ ] Mesaj gönderilebiliyor
- [ ] Streaming yanıt alınıyor
- [ ] Mesajlar localStorage'da saklanıyor
- [ ] Sayfa yenilendiğinde mesajlar geri geliyor

### Non-Fonksiyonel
- [ ] İlk token < 2 saniye
- [ ] UI 60 FPS (smooth scroll)
- [ ] Mobile responsive (360px+)
- [ ] Hata durumları yönetiliyor
- [ ] Loading states gösteriliyor

---

## 📊 BAŞARI METRİKLERİ

| Metrik | Hedef | Ölçüm |
|--------|-------|-------|
| İlk yükleme | < 3s | Lighthouse |
| İlk token | < 2s | Custom timing |
| Mesaj gönder → yanıt | < 500ms | Network tab |
| UI frame rate | 60 FPS | DevTools |
| Bundle size | < 500KB | next build |

---

## 🚨 RİSKLER VE AZALTIM

### Risk 1: Streaming Kesintileri
**Azaltım**: Retry + reconnect logic, timeout 30s

### Risk 2: Backend Hazır Değil
**Azaltım**: Mock API + localStorage, backend'den bağımsız geliştirme

### Risk 3: Model Listesi Değişikliği
**Azaltım**: JSON config dosyası, hard-coded değil

---

## 📝 NOTLAR

### Kapsam Dışı (Sonraki Fazlar)
- ❌ Kullanıcı login/kayıt (FAZ 6)
- ❌ Proje yönetimi (FAZ 6)
- ❌ Sağ panel widgets (FAZ 7)
- ❌ Admin panel (FAZ 8)
- ❌ Geri bildirim sistemi (FAZ 8)

### Teknik Borç
- [ ] Unit testler (FAZ 6'da)
- [ ] E2E testler (FAZ 6'da)
- [ ] Performance optimization (FAZ 6'da)
- [ ] A11y audit (FAZ 6'da)

---

**Son Güncelleme**: 02 Ocak 2026, 22:00  
**Durum**: PLAN HAZIRLANDI ✅  
**Sonraki**: Next.js scaffold oluştur
