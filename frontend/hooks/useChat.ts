'use client'

import { useState, useCallback } from 'react'
import { useChatStore } from '@/lib/store'
import { streamChat } from '@/lib/api-client'
import type { Message } from '@/lib/types'

interface UseChatReturn {
  sendMessage: (content: string) => Promise<void>
  isLoading: boolean
  error: string | null
  clearError: () => void
}

export function useChat(): UseChatReturn {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  const { 
    messages, 
    selectedModel, 
    keyMode, 
    addMessage, 
    setStreaming 
  } = useChatStore()

  const sendMessage = useCallback(async (content: string) => {
    if (!content.trim()) return

    setError(null)
    setIsLoading(true)
    setStreaming(true)

    // Add user message
    const userMessage: Message = {
      id: `user-${Date.now()}`,
      role: 'user',
      content: content.trim(),
      timestamp: new Date(),
    }
    addMessage(userMessage)

    // Prepare assistant message (will be filled by streaming)
    const assistantMessageId = `assistant-${Date.now()}`
    let assistantContent = ''

    const assistantMessage: Message = {
      id: assistantMessageId,
      role: 'assistant',
      content: '',
      timestamp: new Date(),
      model: selectedModel,
    }
    addMessage(assistantMessage)

    try {
      // Call streaming API
      await streamChat(
        {
          messages: [...messages, userMessage],
          model: selectedModel,
          keyMode,
        },
        // On token callback
        (token: string) => {
          assistantContent += token
          
          // Update assistant message in store
          useChatStore.setState((state) => ({
            messages: state.messages.map((msg) =>
              msg.id === assistantMessageId
                ? { ...msg, content: assistantContent }
                : msg
            ),
          }))
        },
        // On complete callback
        (usage) => {
          setIsLoading(false)
          setStreaming(false)
          
          // Update final message with usage
          if (usage) {
            useChatStore.setState((state) => ({
              messages: state.messages.map((msg) =>
                msg.id === assistantMessageId
                  ? { ...msg, tokens: usage.inputTokens + usage.outputTokens }
                  : msg
              ),
            }))
          }
        },
        // On error callback
        (err: Error) => {
          setError(err.message || 'Failed to get response')
          setIsLoading(false)
          setStreaming(false)
          
          // Update message with error
          useChatStore.setState((state) => ({
            messages: state.messages.map((msg) =>
              msg.id === assistantMessageId
                ? { 
                    ...msg, 
                    content: `❌ Error: ${err.message}\n\nPlease try again or check backend connection.` 
                  }
                : msg
            ),
          }))
        }
      )
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      setError(errorMessage)
      setIsLoading(false)
      setStreaming(false)
    }
  }, [messages, selectedModel, keyMode, addMessage, setStreaming])

  const clearError = useCallback(() => {
    setError(null)
  }, [])

  return {
    sendMessage,
    isLoading,
    error,
    clearError,
  }
}
