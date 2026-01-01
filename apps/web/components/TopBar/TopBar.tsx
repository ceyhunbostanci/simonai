'use client'

import { useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { ChevronDown, Zap } from 'lucide-react'
import { api } from '@/lib/api'
import { useChatStore } from '@/store/chatStore'

export function TopBar() {
  const { selectedModel, setSelectedModel, keyMode, setAvailableModels } = useChatStore()

  // Fetch models
  const { data: modelsData } = useQuery({
    queryKey: ['models'],
    queryFn: api.getModels,
  })

  useEffect(() => {
    if (modelsData?.models) {
      setAvailableModels(modelsData.models)
    }
  }, [modelsData, setAvailableModels])

  // Filter models by key mode
  const availableModels = modelsData?.models.filter(
    (m) => m.key_mode === keyMode
  ) || []

  const currentModel = availableModels.find((m) => m.id === selectedModel)

  return (
    <div className="border-b border-dark-border bg-dark-surface px-4 py-3">
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        {/* Model Selector */}
        <div className="flex items-center gap-4">
          <div className="relative">
            <select
              value={selectedModel}
              onChange={(e) => setSelectedModel(e.target.value)}
              className="appearance-none bg-dark-bg border border-dark-border rounded-lg px-4 py-2 pr-10 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 cursor-pointer"
            >
              {availableModels.map((model) => (
                <option key={model.id} value={model.id}>
                  {model.name} ({model.provider})
                </option>
              ))}
            </select>
            <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 pointer-events-none" />
          </div>

          {/* Model Info */}
          {currentModel && (
            <div className="hidden md:flex items-center gap-2 text-sm text-gray-500">
              <Zap className="w-4 h-4" />
              <span>
                {currentModel.context_window.toLocaleString()} tokens
              </span>
              {currentModel.cost.input_per_1m > 0 && (
                <span className="text-gray-600">
                  • ${currentModel.cost.input_per_1m}/${currentModel.cost.output_per_1m} per 1M
                </span>
              )}
            </div>
          )}
        </div>

        {/* Key Mode Badge */}
        <div className="flex items-center gap-2">
          <span
            className={`text-xs px-3 py-1 rounded-full font-medium ${
              keyMode === 'free'
                ? 'bg-green-500/10 text-green-500'
                : keyMode === 'byok'
                ? 'bg-blue-500/10 text-blue-500'
                : 'bg-yellow-500/10 text-yellow-500'
            }`}
          >
            {keyMode === 'free'
              ? 'FREE (Ollama)'
              : keyMode === 'byok'
              ? 'BYOK'
              : 'FREE+'}
          </span>
        </div>
      </div>
    </div>
  )
}
