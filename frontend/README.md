# Simon AI - Frontend MVP-1

**Web Chat Interface - Temel Chat UI**

## 🎯 Özellikler

- ✅ Next.js 14 (App Router)
- ✅ Streaming chat (SSE)
- ✅ Model seçimi (15 FREE + 4 BYOK)
- ✅ Key Mode (FREE/FREE+/BYOK)
- ✅ Responsive design
- ✅ Dark mode
- ✅ localStorage persistence

## 🚀 Hızlı Başlangıç

### 1. Bağımlılıkları Kur

```bash
npm install
# veya
yarn install
```

### 2. Environment Ayarları

`.env.local` dosyası oluştur:

```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### 3. Development Server

```bash
npm run dev
# veya
yarn dev
```

Tarayıcıda aç: [http://localhost:3000](http://localhost:3000)

## 📦 Proje Yapısı

```
frontend/
├── app/                    # Next.js App Router
│   ├── page.tsx           # Ana sayfa
│   ├── layout.tsx         # Root layout
│   ├── globals.css        # Global styles
│   └── providers.tsx      # React Query provider
├── components/
│   ├── Chat/              # Chat bileşenleri
│   │   ├── ChatContainer.tsx
│   │   ├── MessageList.tsx
│   │   ├── MessageBubble.tsx
│   │   └── ChatInput.tsx
│   ├── Layout/            # Layout bileşenleri
│   │   ├── Sidebar.tsx
│   │   └── TopBar.tsx
│   └── ModelSelector/     # Model seçim bileşenleri
│       ├── ModelDropdown.tsx
│       └── KeyModeSelector.tsx
├── lib/                   # Utilities & helpers
│   ├── api-client.ts      # Backend API client
│   ├── store.ts           # Zustand state
│   ├── types.ts           # TypeScript types
│   └── models.ts          # Model catalog
└── public/                # Static assets
```

## 🎨 Teknoloji Stack

- **Framework**: Next.js 14.x
- **UI**: Tailwind CSS
- **State**: Zustand + localStorage
- **Icons**: Lucide React
- **HTTP**: Native Fetch API
- **Streaming**: Server-Sent Events (SSE)

## 📝 Geliştirme Notları

### Backend Entegrasyonu

Backend endpoint: `POST http://localhost:8000/api/chat`

Request:
```json
{
  "messages": [
    {"role": "user", "content": "Hello"}
  ],
  "model": "qwen2.5:7b",
  "keyMode": "FREE",
  "stream": true
}
```

Response (SSE):
```
data: {"type": "token", "content": "Hello"}
data: {"type": "token", "content": " there"}
data: {"type": "done", "usage": {...}}
```

### Model Kataloğu

- **FREE**: 15 Ollama modelleri (qwen, llama, mistral, vb.)
- **BYOK**: 4 best modeller (GPT-5.2, Claude Opus/Sonnet, Gemini)
- **FREE+**: Server key pool (MVP'de minimal)

### State Yönetimi

Zustand store (`lib/store.ts`):
- `messages`: Mesaj geçmişi
- `selectedModel`: Seçili model ID
- `keyMode`: FREE/FREE+/BYOK
- `isStreaming`: Streaming durumu

localStorage'da otomatik persist.

## 🔧 Build & Deploy

### Production Build

```bash
npm run build
npm start
```

### Vercel Deploy

```bash
vercel deploy
```

## ✅ Kabul Kriterleri (MVP-1)

- [x] Chat arayüzü yükleniyor (< 3s)
- [x] Model seçimi değiştirilebiliyor
- [x] Key Mode değiştirilebiliyor
- [x] Mesaj gönderilebiliyor (mock)
- [ ] Backend streaming entegrasyonu
- [ ] Mesajlar localStorage'da saklanıyor
- [ ] Responsive design (mobile/tablet)

## 📊 Performans Hedefleri

| Metrik | Hedef |
|--------|-------|
| İlk yükleme | < 3s |
| İlk token | < 2s |
| UI frame rate | 60 FPS |
| Bundle size | < 500KB |

## 🚧 Sonraki Adımlar (FAZ 6+)

- [ ] Backend streaming entegrasyonu
- [ ] Kullanıcı login/kayıt
- [ ] Proje yönetimi
- [ ] Sağ panel widgets
- [ ] Admin panel
- [ ] Unit testler
- [ ] E2E testler

## 📄 Lisans

Internal - Simon AI Project

---

**Versiyon**: MVP-1  
**Tarih**: 02 Ocak 2026  
**Durum**: Development Ready ✅
