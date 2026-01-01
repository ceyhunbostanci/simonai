import axios from 'axios'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

export const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 60000, // 60 seconds
})

// Request interceptor
apiClient.interceptors.request.use(
  (config) => {
    // Add request ID
    config.headers['X-Request-ID'] = crypto.randomUUID()
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message)
    return Promise.reject(error)
  }
)

// Types
export interface ChatMessage {
  role: 'user' | 'assistant' | 'system'
  content: string
}

export interface ChatRequest {
  messages: ChatMessage[]
  model: string
  key_mode?: 'free' | 'free_plus' | 'byok'
  user_api_key?: string
  temperature?: number
  max_tokens?: number
  stream?: boolean
}

export interface ChatResponse {
  id: string
  model: string
  content: string
  usage: {
    input_tokens: number
    output_tokens: number
    total_tokens: number
  }
  cost: number
  created_at: string
}

export interface Model {
  id: string
  name: string
  provider: string
  key_mode: string
  description: string
  context_window: number
  capabilities: string[]
  cost: {
    input_per_1m: number
    output_per_1m: number
  }
}

// API functions
export const api = {
  // Health check
  health: async () => {
    const { data } = await apiClient.get('/health')
    return data
  },

  // Get models
  getModels: async (): Promise<{ models: Model[] }> => {
    const { data } = await apiClient.get('/api/models')
    return data
  },

  // Chat completion (non-streaming)
  chat: async (request: ChatRequest): Promise<ChatResponse> => {
    const { data } = await apiClient.post('/api/chat', request)
    return data
  },

  // Streaming chat
  streamChat: async function* (
    request: ChatRequest
  ): AsyncGenerator<string, void, unknown> {
    const response = await fetch(`${API_URL}/api/chat/stream`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(request),
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const reader = response.body?.getReader()
    const decoder = new TextDecoder()

    if (!reader) {
      throw new Error('No response body')
    }

    try {
      while (true) {
        const { done, value } = await reader.read()
        
        if (done) break

        const chunk = decoder.decode(value, { stream: true })
        const lines = chunk.split('\n')

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.slice(6)
            
            if (data === '[DONE]') {
              return
            }

            try {
              const parsed = JSON.parse(data)
              
              if (parsed.type === 'content' && parsed.content) {
                yield parsed.content
              } else if (parsed.type === 'error') {
                throw new Error(parsed.error)
              }
            } catch (e) {
              // Skip invalid JSON
              continue
            }
          }
        }
      }
    } finally {
      reader.releaseLock()
    }
  },
}
