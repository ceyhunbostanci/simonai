'use client'

import { ChevronDown } from 'lucide-react'
import { useChatStore } from '@/lib/store'
import { MODEL_CATALOG } from '@/lib/models'

export default function ModelDropdown() {
  const { selectedModel, keyMode, setSelectedModel } = useChatStore()
  
  // Filter models by current key mode
  const availableModels = MODEL_CATALOG.filter(
    (model) => model.keyMode === keyMode
  )

  const currentModel = availableModels.find((m) => m.id === selectedModel)

  return (
    <div className="relative">
      <select
        value={selectedModel}
        onChange={(e) => setSelectedModel(e.target.value)}
        className="appearance-none bg-slate-800/50 px-4 py-2 pr-10 rounded-lg border border-slate-700/50 text-sm text-slate-300 hover:bg-slate-800 transition-colors cursor-pointer focus:outline-none focus:ring-2 focus:ring-primary"
      >
        {availableModels.map((model) => (
          <option key={model.id} value={model.id} className="bg-slate-900">
            {model.icon} {model.name}
          </option>
        ))}
      </select>
      <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none" />
    </div>
  )
}
