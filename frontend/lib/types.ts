export type KeyMode = 'FREE' | 'FREE+' | 'BYOK'

export type MessageRole = 'user' | 'assistant' | 'system'

export interface Message {
  id: string
  role: MessageRole
  content: string
  timestamp: Date
  model?: string
  tokens?: number
}

export interface Model {
  id: string
  name: string
  icon: string
  keyMode: KeyMode
  provider: string
  description?: string
}

export interface ChatState {
  messages: Message[]
  selectedModel: string
  keyMode: KeyMode
  isStreaming: boolean
  addMessage: (message: Message) => void
  setSelectedModel: (modelId: string) => void
  setKeyMode: (mode: KeyMode) => void
  setStreaming: (streaming: boolean) => void
  clearMessages: () => void
}
