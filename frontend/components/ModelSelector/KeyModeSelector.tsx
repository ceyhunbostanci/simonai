'use client'

import { useChatStore } from '@/lib/store'
import type { KeyMode } from '@/lib/types'

const KEY_MODES: { value: KeyMode; label: string; icon: string }[] = [
  { value: 'FREE', label: 'FREE', icon: '🆓' },
  { value: 'FREE+', label: 'FREE+', icon: '⭐' },
  { value: 'BYOK', label: 'BYOK', icon: '🔑' },
]

export default function KeyModeSelector() {
  const { keyMode, setKeyMode } = useChatStore()

  return (
    <div className="flex items-center gap-1 bg-slate-800/50 rounded-lg p-1 border border-slate-700/50">
      {KEY_MODES.map((mode) => (
        <button
          key={mode.value}
          onClick={() => setKeyMode(mode.value)}
          className={`px-3 py-1.5 rounded-md text-xs font-medium transition-all ${
            keyMode === mode.value
              ? 'bg-primary text-white shadow-lg'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          <span className="mr-1">{mode.icon}</span>
          {mode.label}
        </button>
      ))}
    </div>
  )
}
