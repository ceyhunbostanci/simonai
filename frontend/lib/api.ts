/**
 * API Helper for Simon AI Backend
 */

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

export interface ChatRequest {
  message: string;
  model?: string;
  key_mode?: string;
  stream?: boolean;
}

export interface StreamChunk {
  type: 'token' | 'done' | 'error';
  content?: string;
  usage?: {
    tokens: number;
  };
  error?: string;
}

/**
 * Stream chat responses from backend
 */
export async function streamChat(
  request: ChatRequest,
  onChunk: (chunk: StreamChunk) => void,
  onError: (error: Error) => void
) {
  try {
    const response = await fetch(${API_BASE_URL}/api/chat/stream, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: request.message,
        model: request.model || 'qwen2.5:7b',
        key_mode: request.key_mode || 'FREE',
        stream: true,
      }),
    });

    if (!response.ok) {
      throw new Error(HTTP : );
    }

    const reader = response.body?.getReader();
    const decoder = new TextDecoder();

    if (!reader) {
      throw new Error('Response body is not readable');
    }

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      const lines = chunk.split('\n');

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          try {
            const data = JSON.parse(line.slice(6));
            onChunk(data);
          } catch (e) {
            console.warn('Failed to parse SSE data:', line);
          }
        }
      }
    }
  } catch (error) {
    onError(error as Error);
  }
}

/**
 * Get available models
 */
export async function getModels() {
  const response = await fetch(${API_BASE_URL}/api/models);
  return response.json();
}

/**
 * Health check
 */
export async function healthCheck() {
  const response = await fetch(${API_BASE_URL}/health);
  return response.json();
}
