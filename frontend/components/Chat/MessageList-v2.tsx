'use client'

import { useEffect, useRef } from 'react'
import MessageBubble from './MessageBubble'
import StreamingIndicator from './StreamingIndicator'
import { Message } from '@/lib/types'

interface MessageListProps {
  messages: Message[]
  isStreaming?: boolean
}

export default function MessageList({ messages, isStreaming = false }: MessageListProps) {
  const messagesEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isStreaming])

  if (messages.length === 0) {
    return (
      <div className="flex flex-1 items-center justify-center p-8">
        <div className="text-center max-w-md">
          <div className="w-20 h-20 mx-auto mb-6 bg-gradient-to-br from-primary to-blue-600 rounded-2xl flex items-center justify-center">
            <svg className="w-10 h-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
            </svg>
          </div>
          <h2 className="text-2xl font-semibold text-foreground mb-3">
            Welcome to Simon AI
          </h2>
          <p className="text-secondary text-sm leading-relaxed">
            The Ultimate Hybrid Mind - Multi-model AI platform with FREE, FREE+, and BYOK modes.
            Start a conversation by typing a message below.
          </p>
          
          {/* Quick start tips */}
          <div className="mt-8 space-y-2 text-left">
            <p className="text-xs text-slate-500 font-medium uppercase tracking-wider">Quick Tips:</p>
            <div className="space-y-2">
              <div className="flex items-start gap-2 text-sm text-slate-400">
                <span className="text-primary">•</span>
                <span>Switch models anytime from the top bar</span>
              </div>
              <div className="flex items-start gap-2 text-sm text-slate-400">
                <span className="text-primary">•</span>
                <span>Use FREE mode for local Ollama models</span>
              </div>
              <div className="flex items-start gap-2 text-sm text-slate-400">
                <span className="text-primary">•</span>
                <span>BYOK mode for premium models (API key required)</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 overflow-y-auto p-4 md:p-8 scrollbar-thin">
      <div className="max-w-4xl mx-auto space-y-6">
        {messages.map((message) => (
          <MessageBubble key={message.id} message={message} />
        ))}
        
        {/* Streaming Indicator */}
        {isStreaming && (
          <div className="flex justify-start">
            <div className="max-w-[85%] md:max-w-[70%] rounded-2xl p-4 bg-slate-800 border border-slate-700/50">
              <StreamingIndicator />
            </div>
          </div>
        )}
        
        <div ref={messagesEndRef} />
      </div>
    </div>
  )
}
