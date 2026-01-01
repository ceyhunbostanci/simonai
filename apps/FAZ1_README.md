# FAZ 1: CHAT MVP - QUICK START

## ✅ Tamamlandı

- Backend API (FastAPI)
- Frontend UI (Next.js)
- Streaming Chat
- Model Selection
- Cost Tracking

---

## 🚀 Hızlı Başlangıç

### 1. Backend Başlatma

```bash
# Terminal 1: Backend
cd apps/api
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Test:**
```bash
curl http://localhost:8000/health
curl http://localhost:8000/api/models
```

### 2. Frontend Başlatma

```bash
# Terminal 2: Frontend
cd apps/web
npm install
npm run dev
```

**Erişim:**
http://localhost:3000

---

## 🧪 Test

```bash
# Quick test
./infra/scripts/test-faz1.sh
```

---

## 🎯 Özellikler

### Backend
- ✅ `/api/chat` - Non-streaming
- ✅ `/api/chat/stream` - SSE streaming
- ✅ `/api/models` - Model catalog
- ✅ Cost tracking
- ✅ Request logging

### Frontend
- ✅ Chat UI
- ✅ Message list with markdown
- ✅ Code syntax highlighting
- ✅ Model selector
- ✅ Streaming indicator
- ✅ Responsive design

---

## 🐛 Troubleshooting

**Backend won't start:**
```bash
# Check Python version
python --version  # Should be 3.11+

# Reinstall dependencies
pip install --upgrade -r requirements.txt
```

**Frontend won't start:**
```bash
# Clear cache
rm -rf .next node_modules
npm install
npm run dev
```

**CORS errors:**
Check `.env`:
```
CORS_ORIGINS=["http://localhost:3000"]
```

---

## 📚 API Documentation

http://localhost:8000/docs

---

## 🎨 Tech Stack

**Backend:**
- FastAPI 0.109
- Pydantic 2.5
- httpx (async)
- Uvicorn

**Frontend:**
- Next.js 14
- React 18
- TailwindCSS
- React Query
- Zustand
- React Markdown

---

## 📝 Environment Variables

### Backend (.env)
```
CLAUDE_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
LITELLM_URL=http://localhost:4000
```

### Frontend (.env.local)
```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

## 🚀 Production Build

### Backend
```bash
cd apps/api
docker build -t simon-api:latest .
docker run -p 8000:8000 simon-api:latest
```

### Frontend
```bash
cd apps/web
npm run build
npm start
```

---

## ✅ Checklist

Faz 1 Tamamlanma:
- [x] Backend API
- [x] Streaming support
- [x] Frontend UI
- [x] Model selection
- [x] Cost tracking
- [x] Error handling
- [x] Docker support
- [x] Documentation

---

**Versiyon:** v3.1.0-faz1  
**Tarih:** 27 Aralık 2025  
**Durum:** ✅ Complete
