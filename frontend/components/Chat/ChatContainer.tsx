'use client'

import MessageList from './MessageList'
import ChatInput from './ChatInput'
import TopBar from '../Layout/TopBar'
import Sidebar from '../Layout/Sidebar'
import { useChatStore } from '@/lib/store'
import { useChat } from '@/hooks/useChat-v2'
import { useState } from 'react'

export default function ChatContainer() {
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const { messages, isStreaming } = useChatStore()
  const { sendMessage, isLoading, error } = useChat()

  const handleSendMessage = async (content: string) => {
    await sendMessage(content)
  }

  return (
    <div className="flex h-screen w-full overflow-hidden">
      {/* Sidebar */}
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
          <ChatInput 
            onSend={handleSendMessage} 
            disabled={isLoading || isStreaming}
          />

          {/* Error Display */}
          {error && (
            <div className="px-4 py-2 bg-red-500/10 text-red-400 text-sm border-t border-red-500/20">
              Error: {error}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
