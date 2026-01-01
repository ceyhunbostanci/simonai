'use client'

import { useState, KeyboardEvent } from 'react'
import { Send, Loader2 } from 'lucide-react'
import { useChat } from '@/hooks/useChat'

export function MessageInput() {
  const [input, setInput] = useState('')
  const { sendMessage, isStreaming } = useChat()

  const handleSubmit = async () => {
    if (!input.trim() || isStreaming) return

    await sendMessage(input)
    setInput('')
  }

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSubmit()
    }
  }

  return (
    <div className="border-t border-dark-border bg-dark-surface p-4">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-end gap-3">
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Mesajınızı yazın... (Enter = gönder, Shift+Enter = yeni satır)"
            disabled={isStreaming}
            className="flex-1 resize-none rounded-xl border border-dark-border bg-dark-bg text-dark-text px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500 disabled:opacity-50 min-h-[60px] max-h-[200px]"
            rows={2}
          />
          
          <button
            onClick={handleSubmit}
            disabled={!input.trim() || isStreaming}
            className="flex items-center justify-center w-12 h-12 rounded-xl bg-primary-600 text-white hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {isStreaming ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              <Send className="w-5 h-5" />
            )}
          </button>
        </div>
        
        {isStreaming && (
          <p className="text-sm text-gray-500 mt-2 text-center animate-pulse">
            AI yanıt yazıyor...
          </p>
        )}
      </div>
    </div>
  )
}
