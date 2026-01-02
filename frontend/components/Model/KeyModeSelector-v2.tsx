'use client'

import { useModelManager } from '@/hooks/useModelManager'
import type { KeyMode } from '@/lib/types'

const KEY_MODES: { id: KeyMode; label: string; icon: string; description: string }[] = [
  { 
    id: 'FREE', 
    label: 'FREE', 
    icon: '🆓',
    description: 'Local Ollama models (0 cost)'
  },
  { 
    id: 'FREE+', 
    label: 'FREE+', 
    icon: '✨',
    description: 'Sponsored pool (limited)'
  },
  { 
    id: 'BYOK', 
    label: 'BYOK', 
    icon: '🔑',
    description: 'Your API keys (unlimited)'
  },
]

export default function KeyModeSelector() {
  const { keyMode, handleKeyModeChange } = useModelManager()

  return (
    <div className="flex items-center gap-1 p-1 bg-slate-800/50 rounded-lg border border-slate-700/50">
      {KEY_MODES.map((mode) => (
        <button
          key={mode.id}
          onClick={() => handleKeyModeChange(mode.id)}
          className={`
            relative px-3 py-1.5 rounded-md text-xs font-medium transition-all
            ${keyMode === mode.id
              ? 'bg-primary text-white shadow-lg shadow-primary/20'
              : 'text-slate-400 hover:text-slate-300 hover:bg-slate-800'
            }
          `}
          title={mode.description}
        >
          <span className="flex items-center gap-1.5">
            <span>{mode.icon}</span>
            <span>{mode.label}</span>
          </span>
          
          {/* Active indicator */}
          {keyMode === mode.id && (
            <div className="absolute -bottom-0.5 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-primary" />
          )}
        </button>
      ))}
    </div>
  )
}
