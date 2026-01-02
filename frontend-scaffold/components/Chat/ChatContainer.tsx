'use client'

import { useState } from 'react'
import MessageList from './MessageList'
import ChatInput from './ChatInput'
import TopBar from '../Layout/TopBar'
import Sidebar from '../Layout/Sidebar'
import { useChatStore } from '@/lib/store'

export default function ChatContainer() {
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const { messages, addMessage, isStreaming } = useChatStore()

  const handleSendMessage = async (content: string) => {
    // Add user message
    addMessage({
      id: Date.now().toString(),
      role: 'user',
      content,
      timestamp: new Date(),
    })

    // TODO: Call backend API with streaming
    // For now, mock response
    setTimeout(() => {
      addMessage({
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: 'This is a mock response. Backend integration coming soon!',
        timestamp: new Date(),
      })
    }, 1000)
  }

  return (
    <div className="flex h-screen w-full overflow-hidden">
      {/* Sidebar (MVP: iskelet) */}
      <Sidebar isOpen={sidebarOpen} onToggle={() => setSidebarOpen(!sidebarOpen)} />

      {/* Main Content */}
      <div className="flex flex-1 flex-col">
        {/* Top Bar */}
        <TopBar />

        {/* Chat Area */}
        <div className="flex flex-1 flex-col overflow-hidden">
          {/* Message List */}
          <MessageList messages={messages} />

          {/* Chat Input */}
          <ChatInput onSend={handleSendMessage} disabled={isStreaming} />
        </div>
      </div>
    </div>
  )
}
