'use client'

import { useState, useRef, KeyboardEvent } from 'react'
import { Send, Mic, Paperclip } from 'lucide-react'

interface ChatInputProps {
  onSend: (message: string) => void
  disabled?: boolean
}

export default function ChatInput({ onSend, disabled = false }: ChatInputProps) {
  const [input, setInput] = useState('')
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  const handleSend = () => {
    if (!input.trim() || disabled) return
    
    onSend(input.trim())
    setInput('')
    
    // Reset textarea height
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto'
    }
  }

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  const handleInput = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setInput(e.target.value)
    
    // Auto-resize textarea
    e.target.style.height = 'auto'
    e.target.style.height = Math.min(e.target.scrollHeight, 200) + 'px'
  }

  return (
    <div className="p-4 md:p-6 bg-slate-900/80 backdrop-blur-lg border-t border-slate-800">
      <div className="max-w-4xl mx-auto relative">
        {/* Input Container */}
        <div className="relative group">
          {/* Glow effect */}
          <div className="absolute inset-0 bg-gradient-to-r from-primary to-blue-600 rounded-xl blur opacity-20 group-hover:opacity-30 transition-opacity" />
          
          {/* Input Area */}
          <div className="relative bg-slate-950 border border-slate-700 rounded-xl flex items-end p-2 shadow-2xl">
            {/* Attach Button */}
            <button
              className="p-3 text-slate-400 hover:text-white transition-colors"
              disabled={disabled}
            >
              <Paperclip className="w-5 h-5" />
            </button>

            {/* Textarea */}
            <textarea
              ref={textareaRef}
              value={input}
              onChange={handleInput}
              onKeyDown={handleKeyDown}
              placeholder="Type a message (Shift+Enter for new line)..."
              className="flex-1 bg-transparent border-0 focus:ring-0 text-slate-200 placeholder-slate-500 resize-none py-3 max-h-[200px] min-h-[50px] outline-none"
              rows={1}
              disabled={disabled}
            />

            {/* Mic Button */}
            <button
              className="p-3 text-slate-400 hover:text-white transition-colors"
              disabled={disabled}
            >
              <Mic className="w-5 h-5" />
            </button>

            {/* Send Button */}
            <button
              onClick={handleSend}
              disabled={disabled || !input.trim()}
              className="p-3 bg-primary hover:bg-cyan-500 text-white rounded-lg shadow-lg shadow-cyan-900/20 transition-all hover:scale-105 active:scale-95 ml-2 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100"
            >
              <Send className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Helper Text */}
        <div className="text-center mt-2 text-[10px] text-slate-600">
          {disabled ? (
            <span>Waiting for response...</span>
          ) : (
            <span>Press Enter to send • Shift+Enter for new line</span>
          )}
        </div>
      </div>
    </div>
  )
}
