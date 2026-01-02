import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { ChatState, Message, KeyMode } from './types'

export const useChatStore = create<ChatState>()(
  persist(
    (set) => ({
      messages: [],
      selectedModel: 'qwen2.5:7b',
      keyMode: 'FREE',
      isStreaming: false,

      addMessage: (message: Message) =>
        set((state) => ({
          messages: [...state.messages, message],
        })),

      setSelectedModel: (modelId: string) =>
        set({ selectedModel: modelId }),

      setKeyMode: (mode: KeyMode) =>
        set((state) => {
          // Reset model when switching key mode
          let newModel = state.selectedModel
          if (mode === 'FREE') {
            newModel = 'qwen2.5:7b'
          } else if (mode === 'BYOK') {
            newModel = 'claude-sonnet-4.5'
          }
          return { keyMode: mode, selectedModel: newModel }
        }),

      setStreaming: (streaming: boolean) =>
        set({ isStreaming: streaming }),

      clearMessages: () => set({ messages: [] }),
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
