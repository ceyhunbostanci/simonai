'use client'

import { useState } from 'react'
import { Copy, Trash2, RefreshCw, Check } from 'lucide-react'
import type { Message } from '@/lib/types'

interface MessageActionsProps {
  message: Message
  onDelete?: (messageId: string) => void
  onRegenerate?: (messageId: string) => void
}

export default function MessageActions({ message, onDelete, onRegenerate }: MessageActionsProps) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(message.content)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error('Failed to copy:', err)
    }
  }

  const handleDelete = () => {
    if (onDelete && confirm('Delete this message?')) {
      onDelete(message.id)
    }
  }

  const handleRegenerate = () => {
    if (onRegenerate) {
      onRegenerate(message.id)
    }
  }

  return (
    <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
      {/* Copy Button */}
      <button
        onClick={handleCopy}
        className="p-1.5 rounded hover:bg-slate-700/50 transition-colors"
        title="Copy message"
      >
        {copied ? (
          <Check className="w-4 h-4 text-green-400" />
        ) : (
          <Copy className="w-4 h-4 text-slate-400" />
        )}
      </button>

      {/* Regenerate Button (Assistant messages only) */}
      {message.role === 'assistant' && onRegenerate && (
        <button
          onClick={handleRegenerate}
          className="p-1.5 rounded hover:bg-slate-700/50 transition-colors"
          title="Regenerate response"
        >
          <RefreshCw className="w-4 h-4 text-slate-400" />
        </button>
      )}

      {/* Delete Button */}
      {onDelete && (
        <button
          onClick={handleDelete}
          className="p-1.5 rounded hover:bg-red-900/30 transition-colors"
          title="Delete message"
        >
          <Trash2 className="w-4 h-4 text-slate-400 hover:text-red-400" />
        </button>
      )}
    </div>
  )
}
