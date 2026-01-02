'use client'

import { useState, useCallback } from 'react'
import { useChatStore } from '@/lib/store'
import { streamChat } from '@/lib/api-client'
import type { Message } from '@/lib/types'

interface UseChatReturn {
  sendMessage: (content: string) => Promise<void>
  regenerateMessage: (messageId: string) => Promise<void>
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
    removeMessage,
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

    // Prepare assistant message
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
      await streamChat(
        {
          messages: [...messages, userMessage],
          model: selectedModel,
          keyMode,
        },
        (token: string) => {
          assistantContent += token
          useChatStore.setState((state) => ({
            messages: state.messages.map((msg) =>
              msg.id === assistantMessageId
                ? { ...msg, content: assistantContent }
                : msg
            ),
          }))
        },
        (usage) => {
          setIsLoading(false)
          setStreaming(false)
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
        (err: Error) => {
          setError(err.message || 'Failed to get response')
          setIsLoading(false)
          setStreaming(false)
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

  const regenerateMessage = useCallback(async (messageId: string) => {
    // Find the assistant message index
    const assistantIndex = messages.findIndex(m => m.id === messageId)
    if (assistantIndex === -1) return

    // Get the previous user message
    const userMessage = messages[assistantIndex - 1]
    if (!userMessage || userMessage.role !== 'user') {
      setError('Cannot find user message to regenerate')
      return
    }

    // Remove the old assistant message
    removeMessage(messageId)

    // Wait a bit for state update
    await new Promise(resolve => setTimeout(resolve, 100))

    // Resend the user message
    await sendMessage(userMessage.content)
  }, [messages, removeMessage, sendMessage])

  const clearError = useCallback(() => {
    setError(null)
  }, [])

  return {
    sendMessage,
    regenerateMessage,
    isLoading,
    error,
    clearError,
  }
}
