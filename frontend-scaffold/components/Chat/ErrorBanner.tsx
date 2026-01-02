'use client'

import { AlertCircle, X } from 'lucide-react'

interface ErrorBannerProps {
  message: string
  onClose: () => void
}

export default function ErrorBanner({ message, onClose }: ErrorBannerProps) {
  return (
    <div className="bg-red-900/20 border-b border-red-500/50 p-3 animate-slide-down">
      <div className="max-w-4xl mx-auto flex items-center gap-3">
        <AlertCircle className="w-5 h-5 text-red-400 flex-shrink-0" />
        <p className="text-sm text-red-200 flex-1">{message}</p>
        <button
          onClick={onClose}
          className="p-1 hover:bg-red-900/30 rounded transition-colors"
        >
          <X className="w-4 h-4 text-red-400" />
        </button>
      </div>
    </div>
  )
}
