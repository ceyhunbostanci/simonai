'use client'

import { useState } from 'react'
import MessageList from './MessageList'
import ChatInput from './ChatInput'
import TopBar from '../Layout/TopBar'
import Sidebar from '../Layout/Sidebar'
import ErrorBanner from './ErrorBanner'
import { useChatStore } from '@/lib/store'
import { useChat } from '@/hooks/useChat'

export default function ChatContainer() {
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const { messages, isStreaming } = useChatStore()
  const { sendMessage, isLoading, error, clearError } = useChat()

  return (
    <div className="flex h-screen w-full overflow-hidden">
      {/* Sidebar */}
      <Sidebar isOpen={sidebarOpen} onToggle={() => setSidebarOpen(!sidebarOpen)} />

      {/* Main Content */}
      <div className="flex flex-1 flex-col">
        {/* Top Bar */}
        <TopBar />

        {/* Error Banner */}
        {error && (
          <ErrorBanner message={error} onClose={clearError} />
        )}

        {/* Chat Area */}
        <div className="flex flex-1 flex-col overflow-hidden">
          {/* Message List */}
          <MessageList messages={messages} isStreaming={isStreaming} />

          {/* Chat Input */}
          <ChatInput 
            onSend={sendMessage} 
            disabled={isLoading || isStreaming} 
          />
        </div>
      </div>
    </div>
  )
}
