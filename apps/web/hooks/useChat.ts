import { useState } from 'react'
import { api } from '@/lib/api'
import { useChatStore } from '@/store/chatStore'

export function useChat() {
  const [error, setError] = useState<string | null>(null)
  
  const {
    messages,
    addMessage,
    updateLastMessage,
    selectedModel,
    keyMode,
    userApiKey,
    isStreaming,
    setIsStreaming,
  } = useChatStore()

  const sendMessage = async (content: string) => {
    if (!content.trim() || isStreaming) return

    try {
      setError(null)
      setIsStreaming(true)

      // Add user message
      const userMessage = { role: 'user' as const, content }
      addMessage(userMessage)

      // Add empty assistant message
      addMessage({ role: 'assistant' as const, content: '' })

      // Stream response
      const stream = api.streamChat({
        messages: [...messages, userMessage],
        model: selectedModel,
        key_mode: keyMode,
        user_api_key: userApiKey || undefined,
        temperature: 1.0,
        max_tokens: 4096,
        stream: true,
      })

      for await (const chunk of stream) {
        updateLastMessage(chunk)
      }

      setIsStreaming(false)
    } catch (err) {
      setIsStreaming(false)
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      setError(errorMessage)
      console.error('Chat error:', err)
    }
  }

  return {
    messages,
    sendMessage,
    isStreaming,
    error,
  }
}
