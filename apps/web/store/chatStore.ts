import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { ChatMessage, Model } from '@/lib/api'

interface ChatStore {
  // Messages
  messages: ChatMessage[]
  addMessage: (message: ChatMessage) => void
  clearMessages: () => void
  updateLastMessage: (content: string) => void

  // Models
  selectedModel: string
  availableModels: Model[]
  setSelectedModel: (model: string) => void
  setAvailableModels: (models: Model[]) => void

  // Key Mode
  keyMode: 'free' | 'free_plus' | 'byok'
  setKeyMode: (mode: 'free' | 'free_plus' | 'byok') => void
  userApiKey: string | null
  setUserApiKey: (key: string | null) => void

  // UI State
  isStreaming: boolean
  setIsStreaming: (streaming: boolean) => void
  
  // Sidebar
  isSidebarOpen: boolean
  toggleSidebar: () => void
  
  // Right Panel
  isRightPanelOpen: boolean
  toggleRightPanel: () => void
  
  // Theme
  theme: 'light' | 'dark'
  toggleTheme: () => void
}

export const useChatStore = create<ChatStore>()(
  persist(
    (set) => ({
  persist(
    (set) => ({
      // Messages
      messages: [],
      addMessage: (message) =>
        set((state) => ({
          messages: [...state.messages, message],
        })),
      clearMessages: () => set({ messages: [] }),
      updateLastMessage: (content) =>
        set((state) => {
          const messages = [...state.messages]
          if (messages.length > 0) {
            const lastMessage = messages[messages.length - 1]
            if (lastMessage.role === 'assistant') {
              lastMessage.content += content
            }
          }
          return { messages }
        }),

      // Models
      selectedModel: 'claude-sonnet-4.5',
      availableModels: [],
      setSelectedModel: (model) => set({ selectedModel: model }),
      setAvailableModels: (models) => set({ availableModels: models }),

      // Key Mode
      keyMode: 'free',
      setKeyMode: (mode) => set({ keyMode: mode }),
      userApiKey: null,
      setUserApiKey: (key) => set({ userApiKey: key }),

      // UI State
      isStreaming: false,
      setIsStreaming: (streaming) => set({ isStreaming: streaming }),
      
      // Sidebar
      isSidebarOpen: true,
      toggleSidebar: () =>
        set((state) => ({ isSidebarOpen: !state.isSidebarOpen })),
      
      // Right Panel
      isRightPanelOpen: false,
      toggleRightPanel: () =>
        set((state) => ({ isRightPanelOpen: !state.isRightPanelOpen })),
      
      // Theme
      theme: 'dark',
      toggleTheme: () =>
        set((state) => ({ theme: state.theme === 'dark' ? 'light' : 'dark' })),
    }),
    {
      name: 'simon-ai-storage',
      partialize: (state) => ({
        selectedModel: state.selectedModel,
        keyMode: state.keyMode,
        theme: state.theme,
        isSidebarOpen: state.isSidebarOpen,
        isRightPanelOpen: state.isRightPanelOpen,
      }),
    }
  )
)
