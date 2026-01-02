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

export async function streamChat(
  request: ChatRequest,
  onToken: (token: string) => void,
  onComplete: (usage?: ChatResponse['usage']) => void,
  onError: (error: Error) => void
): Promise<void> {
  try {
    const response = await fetch(`${API_URL}/api/chat/stream`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        messages: request.messages.map(m => ({ role: m.role, content: m.content })),
        model: request.model,
        key_mode: request.keyMode,
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
          const data = line.slice(6).trim()

          if (!data || data === '[DONE]') {
            continue
          }

          try {
            const parsed = JSON.parse(data)

            if (parsed.type === 'content') {
              onToken(parsed.content)
            } else if (parsed.type === 'done') {
              const usage = parsed.usage ? {
                inputTokens: parsed.usage.input_tokens || 0,
                outputTokens: parsed.usage.output_tokens || 0,
              } : undefined
              onComplete(usage)
            } else if (parsed.type === 'error') {
              onError(new Error(parsed.message || 'Stream error'))
            }
          } catch (e) {
            console.warn('Failed to parse SSE data:', data, e)
          }
        }
      }
    }
  } catch (error) {
    onError(error as Error)
  }
}

export async function sendChat(request: ChatRequest): Promise<ChatResponse> {
  const response = await fetch(`${API_URL}/api/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      messages: request.messages.map(m => ({ role: m.role, content: m.content })),
      model: request.model,
      key_mode: request.keyMode,
      stream: false,
    }),
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.message || `HTTP error! status: ${response.status}`)
  }

  return response.json()
}

export async function checkHealth(): Promise<boolean> {
  try {
    const response = await fetch(`${API_URL}/health`)
    return response.ok
  } catch {
    return false
  }
}
