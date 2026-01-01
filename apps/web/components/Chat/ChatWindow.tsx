'use client'

import { MessageList } from './MessageList'
import { MessageInput } from './MessageInput'

export function ChatWindow() {
  return (
    <div className="flex-1 flex flex-col h-full overflow-hidden">
      {/* Messages */}
      <MessageList />
      
      {/* Input */}
      <MessageInput />
    </div>
  )
}
