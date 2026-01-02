import type { Message } from './types'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

export interface ChatRequest {
  messages: Message[]
  model: string
  keyMode: string
  stream?: boolean
}

export interface ChatResponse {
  content: string
  usage?: {
    inputTokens: number
    outputTokens: number
  }
}

/**
 * Send a chat message to the backend (streaming)
 */
export async function streamChat(
  request: ChatRequest,
  onToken: (token: string) => void,
  onComplete: (usage?: ChatResponse['usage']) => void,
  onError: (error: Error) => void
): Promise<void> {
  try {
    const response = await fetch(`${API_URL}/api/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        ...request,
        stream: true,
      }),
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const reader = response.body?.getReader()
    const decoder = new TextDecoder()

    if (!reader) {
      throw new Error('No response body')
    }

    while (true) {
      const { done, value } = await reader.read()

      if (done) {
        onComplete()
        break
      }

      const chunk = decoder.decode(value)
      const lines = chunk.split('\n')

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6)
          
          if (data === '[DONE]') {
            continue
          }

          try {
            const parsed = JSON.parse(data)
            
            if (parsed.type === 'token') {
              onToken(parsed.content)
            } else if (parsed.type === 'done') {
              onComplete(parsed.usage)
            } else if (parsed.type === 'error') {
              onError(new Error(parsed.message))
            }
          } catch (e) {
            // Ignore JSON parse errors
            console.warn('Failed to parse SSE data:', data)
          }
        }
      }
    }
  } catch (error) {
    onError(error as Error)
  }
}

/**
 * Send a chat message to the backend (non-streaming)
 */
export async function sendChat(request: ChatRequest): Promise<ChatResponse> {
  const response = await fetch(`${API_URL}/api/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      ...request,
      stream: false,
    }),
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.message || `HTTP error! status: ${response.status}`)
  }

  return response.json()
}

/**
 * Check backend health
 */
export async function checkHealth(): Promise<boolean> {
  try {
    const response = await fetch(`${API_URL}/health`)
    return response.ok
  } catch {
    return false
  }
}
