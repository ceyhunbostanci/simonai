'use client'

import { format } from 'date-fns'
import { User, Bot } from 'lucide-react'
import MessageActions from './MessageActions'
import { useChatStore } from '@/lib/store'
import type { Message } from '@/lib/types'

interface MessageBubbleProps {
  message: Message
}

export default function MessageBubble({ message }: MessageBubbleProps) {
  const { removeMessage } = useChatStore()
  const isUser = message.role === 'user'

  const handleDelete = (messageId: string) => {
    removeMessage(messageId)
  }

  const handleRegenerate = (messageId: string) => {
    // TODO: Implement regenerate logic
    console.log('Regenerate:', messageId)
  }

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'} group`}>
      <div
        className={`
          max-w-[85%] md:max-w-[70%] rounded-2xl p-4 md:p-6 shadow-xl
          ${isUser
            ? 'bg-gradient-to-br from-cyan-600 to-blue-700 text-white rounded-br-none'
            : 'bg-slate-800 border border-slate-700/50 text-slate-200 rounded-bl-none'
          }
        `}
      >
        {/* Header */}
        <div className="flex items-center justify-between gap-3 mb-2">
          <div className="flex items-center gap-2 text-xs opacity-70 font-mono uppercase tracking-wider">
            {isUser ? (
              <>
                <User className="w-3 h-3" />
                <span>You</span>
              </>
            ) : (
              <>
                <Bot className="w-3 h-3 text-cyan-400" />
                <span>Simon AI</span>
                {message.model && (
                  <>
                    <span className="opacity-50">•</span>
                    <span className="opacity-50">{message.model}</span>
                  </>
                )}
              </>
            )}
          </div>

          {/* Actions */}
          <MessageActions
            message={message}
            onDelete={handleDelete}
            onRegenerate={!isUser ? handleRegenerate : undefined}
          />
        </div>

        {/* Content */}
        <div className="whitespace-pre-wrap leading-relaxed break-words">
          {message.content}
        </div>

        {/* Footer */}
        <div className="flex items-center gap-3 mt-3 text-[10px] opacity-50">
          <span>{format(new Date(message.timestamp), 'HH:mm')}</span>
          {message.tokens && (
            <>
              <span>•</span>
              <span>{message.tokens.toLocaleString()} tokens</span>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
