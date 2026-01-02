'use client'

import { useState, useRef, useEffect } from 'react'
import { ChevronDown, Check } from 'lucide-react'
import { getModelsByKeyMode, getModelById } from '@/lib/models'
import { useModelManager } from '@/hooks/useModelManager'

export default function ModelDropdown() {
  const [isOpen, setIsOpen] = useState(false)
  const dropdownRef = useRef<HTMLDivElement>(null)
  const { selectedModel, keyMode, handleModelChange } = useModelManager()

  // Close dropdown on outside click
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const availableModels = getModelsByKeyMode(keyMode)
  const currentModel = getModelById(selectedModel)

  return (
    <div className="relative" ref={dropdownRef}>
      {/* Trigger Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-slate-800/50 border border-slate-700/50 hover:bg-slate-800 transition-colors text-sm"
      >
        <span className="text-lg">{currentModel?.icon || '🤖'}</span>
        <span className="text-slate-300 max-w-[150px] truncate">
          {currentModel?.name || 'Select Model'}
        </span>
        <ChevronDown className={`w-4 h-4 text-slate-400 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {/* Dropdown Menu */}
      {isOpen && (
        <div className="absolute top-full left-0 mt-2 w-80 bg-slate-900 border border-slate-700 rounded-lg shadow-2xl z-50 max-h-96 overflow-y-auto animate-slide-up">
          <div className="p-2">
            {/* Header */}
            <div className="px-3 py-2 text-xs font-medium text-slate-500 uppercase tracking-wider">
              Available Models ({availableModels.length})
            </div>

            {/* Model List */}
            {availableModels.map((model) => (
              <button
                key={model.id}
                onClick={() => {
                  handleModelChange(model.id)
                  setIsOpen(false)
                }}
                className={`w-full flex items-start gap-3 px-3 py-2.5 rounded-lg transition-colors ${
                  selectedModel === model.id
                    ? 'bg-primary/10 text-primary'
                    : 'hover:bg-slate-800/50 text-slate-300'
                }`}
              >
                {/* Icon */}
                <span className="text-xl flex-shrink-0">{model.icon}</span>

                {/* Model Info */}
                <div className="flex-1 text-left">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium">{model.name}</span>
                    {selectedModel === model.id && (
                      <Check className="w-4 h-4 text-primary" />
                    )}
                  </div>
                  <div className="text-xs text-slate-500 mt-0.5">
                    {model.description}
                  </div>
                  
                  {/* Tags */}
                  <div className="flex items-center gap-1.5 mt-1.5">
                    <span className={`text-[10px] px-1.5 py-0.5 rounded ${
                      model.tier === 'premium' ? 'bg-purple-500/20 text-purple-400' :
                      model.tier === 'standard' ? 'bg-blue-500/20 text-blue-400' :
                      'bg-green-500/20 text-green-400'
                    }`}>
                      {model.tier}
                    </span>
                    {model.context && (
                      <span className="text-[10px] px-1.5 py-0.5 rounded bg-slate-700/50 text-slate-400">
                        {model.context}
                      </span>
                    )}
                  </div>
                </div>
              </button>
            ))}

            {/* Empty State */}
            {availableModels.length === 0 && (
              <div className="px-3 py-8 text-center text-slate-500 text-sm">
                No models available for {keyMode} mode
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
