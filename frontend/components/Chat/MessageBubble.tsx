'use client'

import { User, Bot } from 'lucide-react'
import { Message } from '@/lib/types'

interface MessageBubbleProps {
  message: Message
}

export default function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.role === 'user'

  // Handle timestamp - convert to Date if needed
  const timestamp = message.timestamp instanceof Date 
    ? message.timestamp 
    : new Date(message.timestamp)

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'} animate-fade-in`}>
      <div
        className={`max-w-[85%] md:max-w-[70%] rounded-2xl p-4 md:p-6 shadow-xl ${
          isUser
            ? 'bg-gradient-to-br from-primary to-blue-700 text-white rounded-br-none'
            : 'bg-slate-800 border border-slate-700/50 text-slate-200 rounded-bl-none'
        }`}
      >
        {/* Header */}
        <div className="flex items-center gap-3 mb-2 opacity-70 text-xs font-mono uppercase tracking-wider">
          {isUser ? (
            <>
              <User className="w-3 h-3" />
              <span>You</span>
            </>
          ) : (
            <>
              <Bot className="w-3 h-3 text-cyan-400" />
              <span>Simon AI</span>
            </>
          )}
          <span className="ml-auto">
            {timestamp.toLocaleTimeString([], {
              hour: '2-digit',
              minute: '2-digit',
            })}
          </span>
        </div>

        {/* Content */}
        <div className="whitespace-pre-wrap leading-relaxed">
          {message.content}
        </div>
      </div>
    </div>
  )
}
