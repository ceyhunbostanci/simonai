'use client'

import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { Message, KeyMode } from './types'

interface ChatStore {
  messages: Message[]
  selectedModel: string
  keyMode: KeyMode
  isStreaming: boolean
  
  addMessage: (message: Message) => void
  removeMessage: (messageId: string) => void
  clearMessages: () => void
  setModel: (modelId: string) => void
  setKeyMode: (mode: KeyMode) => void
  setStreaming: (streaming: boolean) => void
}

export const useChatStore = create<ChatStore>()(
  persist(
    (set) => ({
      messages: [],
      selectedModel: 'qwen2.5:7b',
      keyMode: 'FREE',
      isStreaming: false,

      addMessage: (message) =>
        set((state) => ({
          messages: [...state.messages, message],
        })),

      removeMessage: (messageId) =>
        set((state) => ({
          messages: state.messages.filter((msg) => msg.id !== messageId),
        })),

      clearMessages: () =>
        set({
          messages: [],
        }),

      setModel: (modelId) =>
        set({
          selectedModel: modelId,
        }),

      setKeyMode: (mode) =>
        set({
          keyMode: mode,
        }),

      setStreaming: (streaming) =>
        set({
          isStreaming: streaming,
        }),
    }),
    {
      name: 'simonai-chat-storage',
      partialize: (state) => ({
        messages: state.messages,
        selectedModel: state.selectedModel,
        keyMode: state.keyMode,
      }),
    }
  )
)
