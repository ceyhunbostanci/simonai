import type { Model } from './types'

// FREE Models (Ollama - Minimum 15)
export const FREE_MODELS: Model[] = [
  // Hafif (Low RAM, Hızlı)
  { id: 'qwen2.5:1.5b', name: 'Qwen 2.5 1.5B', icon: '⚡', keyMode: 'FREE', provider: 'Ollama', description: 'Hafif ve hızlı' },
  { id: 'phi-4', name: 'Phi 4', icon: '⚡', keyMode: 'FREE', provider: 'Ollama', description: 'Küçük ama güçlü' },
  { id: 'llama3.2:1b', name: 'Llama 3.2 1B', icon: '⚡', keyMode: 'FREE', provider: 'Ollama', description: 'Mini model' },
  { id: 'llama3.2:3b', name: 'Llama 3.2 3B', icon: '⚡', keyMode: 'FREE', provider: 'Ollama', description: 'Dengeli performans' },
  { id: 'gemma2:2b', name: 'Gemma 2 2B', icon: '⚡', keyMode: 'FREE', provider: 'Ollama', description: 'Google\'ın hafif modeli' },

  // Genel Amaç (Daha İyi Kalite)
  { id: 'qwen2.5:7b', name: 'Qwen 2.5 7B', icon: '🧠', keyMode: 'FREE', provider: 'Ollama', description: 'Genel kullanım - önerilen' },
  { id: 'mistral:7b', name: 'Mistral 7B', icon: '🧠', keyMode: 'FREE', provider: 'Ollama', description: 'Yüksek kalite' },
  { id: 'llama3.1:8b', name: 'Llama 3.1 8B', icon: '🧠', keyMode: 'FREE', provider: 'Ollama', description: 'Meta\'nın güçlü modeli' },
  { id: 'gemma2:9b', name: 'Gemma 2 9B', icon: '🧠', keyMode: 'FREE', provider: 'Ollama', description: 'İyi kalite' },
  { id: 'deepseek-r1:7b', name: 'DeepSeek R1 7B', icon: '🧠', keyMode: 'FREE', provider: 'Ollama', description: 'Akıl yürütme' },

  // Kod/Araç Odaklı
  { id: 'qwen2.5-coder:7b', name: 'Qwen 2.5 Coder 7B', icon: '💻', keyMode: 'FREE', provider: 'Ollama', description: 'Kod yazma' },
  { id: 'deepseek-coder:6.7b', name: 'DeepSeek Coder 6.7B', icon: '💻', keyMode: 'FREE', provider: 'Ollama', description: 'Kod uzmanı' },
  { id: 'codestral:22b', name: 'Codestral 22B', icon: '💻', keyMode: 'FREE', provider: 'Ollama', description: 'Güçlü kod modeli' },

  // Özet/Akıl Yürütme
  { id: 'llama3.1:70b', name: 'Llama 3.1 70B', icon: '🎓', keyMode: 'FREE', provider: 'Ollama', description: 'Çok güçlü (yüksek RAM)' },
  { id: 'mixtral:8x7b', name: 'Mixtral 8x7B', icon: '🎓', keyMode: 'FREE', provider: 'Ollama', description: 'MoE mimarisi' },
]

// BYOK Models (Varsayılan En İyi 4)
export const BYOK_MODELS: Model[] = [
  { id: 'gpt-5.2', name: 'GPT-5.2', icon: '🤖', keyMode: 'BYOK', provider: 'OpenAI', description: 'Genel + agentic + coding' },
  { id: 'claude-opus-4.5', name: 'Claude Opus 4.5', icon: '🧠', keyMode: 'BYOK', provider: 'Anthropic', description: 'Maksimum kalite' },
  { id: 'claude-sonnet-4.5', name: 'Claude Sonnet 4.5', icon: '⚡', keyMode: 'BYOK', provider: 'Anthropic', description: 'Hız/kalite dengesi' },
  { id: 'gemini-3-pro', name: 'Gemini 3 Pro', icon: '🌟', keyMode: 'BYOK', provider: 'Google', description: 'Multimodal + uzun context' },
]

// FREE+ Models (Server Key Pool - MVP'de boş)
export const FREE_PLUS_MODELS: Model[] = [
  { id: 'server-gpt-4o-mini', name: 'GPT-4o Mini (Server)', icon: '⭐', keyMode: 'FREE+', provider: 'OpenAI (Server)', description: 'Sponsorlu - kısıtlı' },
]

// Combined Catalog
export const MODEL_CATALOG: Model[] = [
  ...FREE_MODELS,
  ...BYOK_MODELS,
  ...FREE_PLUS_MODELS,
]

// Helper functions
export function getModelsByKeyMode(keyMode: string): Model[] {
  return MODEL_CATALOG.filter((model) => model.keyMode === keyMode)
}

export function getModelById(id: string): Model | undefined {
  return MODEL_CATALOG.find((model) => model.id === id)
}
