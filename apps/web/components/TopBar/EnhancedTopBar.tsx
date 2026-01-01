'use client'

import { useEffect, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { 
  ChevronDown, Zap, DollarSign, MessageSquare, 
  Clock, TrendingUp, Settings as SettingsIcon 
} from 'lucide-react'
import { api } from '@/lib/api'
import { useChatStore } from '@/store/chatStore'

export function EnhancedTopBar() {
  const { 
    selectedModel, 
    setSelectedModel, 
    keyMode, 
    setKeyMode,
    setAvailableModels,
    messages 
  } = useChatStore()
  
  const [showModelDropdown, setShowModelDropdown] = useState(false)
  const [showKeyModeDropdown, setShowKeyModeDropdown] = useState(false)
  const [stats, setStats] = useState({
    totalTokens: 0,
    totalCost: 0,
    messageCount: 0,
    avgResponseTime: 0,
  })

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

  // Calculate stats from messages
  useEffect(() => {
    const messageCount = messages.length
    // Mock calculations (Faz 3'te gerçek data)
    setStats({
      totalTokens: messageCount * 150,
      totalCost: messageCount * 0.002,
      messageCount,
      avgResponseTime: 1.2,
    })
  }, [messages])

  // Filter models by key mode
  const availableModels = modelsData?.models.filter(
    (m) => m.key_mode === keyMode
  ) || []

  const currentModel = availableModels.find((m) => m.id === selectedModel)

  // Key mode options
  const keyModes = [
    { id: 'free', name: 'FREE (Ollama)', description: 'Lokal, ücretsiz modeller', color: 'text-green-500' },
    { id: 'byok', name: 'BYOK', description: 'Kendi API anahtarınız', color: 'text-blue-500' },
    { id: 'free_plus', name: 'FREE+', description: 'Sponsorlu, sınırlı', color: 'text-yellow-500' },
  ]
  
  const currentKeyMode = keyModes.find(k => k.id === keyMode)

  return (
    <div className="border-b border-dark-border bg-dark-surface">
      <div className="px-4 py-3">
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-4">
          {/* Left: Model Selection */}
          <div className="flex items-center gap-4">
            {/* Key Mode Selector */}
            <div className="relative">
              <button
                onClick={() => setShowKeyModeDropdown(!showKeyModeDropdown)}
                className="flex items-center gap-2 px-3 py-2 bg-dark-bg border border-dark-border rounded-lg text-sm hover:border-primary-500 transition-colors"
              >
                <div className={`w-2 h-2 rounded-full ${currentKeyMode?.color.replace('text', 'bg')}`} />
                <span className="font-medium">{currentKeyMode?.name}</span>
                <ChevronDown className="w-4 h-4" />
              </button>
              
              {showKeyModeDropdown && (
                <div className="absolute top-full left-0 mt-2 w-64 bg-dark-surface border border-dark-border rounded-lg shadow-xl z-50 py-2">
                  {keyModes.map(mode => (
                    <button
                      key={mode.id}
                      onClick={() => {
                        setKeyMode(mode.id as any)
                        setShowKeyModeDropdown(false)
                      }}
                      className="w-full px-4 py-2.5 text-left hover:bg-dark-bg transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        <div className={`w-2 h-2 rounded-full ${mode.color.replace('text', 'bg')}`} />
                        <div>
                          <div className="text-sm font-medium">{mode.name}</div>
                          <div className="text-xs text-gray-500">{mode.description}</div>
                        </div>
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Model Selector */}
            <div className="relative">
              <button
                onClick={() => setShowModelDropdown(!showModelDropdown)}
                className="flex items-center gap-2 px-4 py-2 bg-dark-bg border border-dark-border rounded-lg text-sm hover:border-primary-500 transition-colors min-w-[200px]"
              >
                <Zap className="w-4 h-4 text-primary-400" />
                <span className="flex-1 text-left font-medium">
                  {currentModel?.name || 'Model Seç'}
                </span>
                <ChevronDown className="w-4 h-4" />
              </button>
              
              {showModelDropdown && (
                <div className="absolute top-full left-0 mt-2 w-80 bg-dark-surface border border-dark-border rounded-lg shadow-xl z-50 py-2 max-h-96 overflow-y-auto">
                  {availableModels.map(model => (
                    <button
                      key={model.id}
                      onClick={() => {
                        setSelectedModel(model.id)
                        setShowModelDropdown(false)
                      }}
                      className={`w-full px-4 py-3 text-left hover:bg-dark-bg transition-colors ${
                        model.id === selectedModel ? 'bg-dark-bg' : ''
                      }`}
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div className="flex-1">
                          <div className="text-sm font-medium">{model.name}</div>
                          <div className="text-xs text-gray-500 mt-0.5">{model.description}</div>
                          <div className="flex items-center gap-3 mt-2 text-xs text-gray-600">
                            <span>{model.context_window.toLocaleString()} tokens</span>
                            {model.cost.input_per_1m > 0 && (
                              <span>
                                ${model.cost.input_per_1m}/${model.cost.output_per_1m} per 1M
                              </span>
                            )}
                          </div>
                        </div>
                        <span className="text-xs px-2 py-1 bg-dark-bg rounded">
                          {model.provider}
                        </span>
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Model Info */}
            {currentModel && (
              <div className="hidden xl:flex items-center gap-4 text-sm text-gray-500">
                <div className="flex items-center gap-1.5">
                  <Zap className="w-3.5 h-3.5" />
                  <span>{currentModel.context_window.toLocaleString()}</span>
                </div>
                {currentModel.cost.input_per_1m > 0 && (
                  <div className="flex items-center gap-1.5">
                    <DollarSign className="w-3.5 h-3.5" />
                    <span>${currentModel.cost.input_per_1m}/${currentModel.cost.output_per_1m}</span>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Right: Stats & Controls */}
          <div className="flex items-center gap-3">
            {/* Session Stats */}
            <div className="hidden md:flex items-center gap-4 px-4 py-2 bg-dark-bg rounded-lg text-xs">
              <div className="flex items-center gap-1.5 text-gray-400">
                <MessageSquare className="w-3.5 h-3.5" />
                <span>{stats.messageCount}</span>
              </div>
              
              <div className="w-px h-4 bg-dark-border" />
              
              <div className="flex items-center gap-1.5 text-gray-400">
                <TrendingUp className="w-3.5 h-3.5" />
                <span>{stats.totalTokens.toLocaleString()}</span>
              </div>
              
              {stats.totalCost > 0 && (
                <>
                  <div className="w-px h-4 bg-dark-border" />
                  <div className="flex items-center gap-1.5 text-primary-400">
                    <DollarSign className="w-3.5 h-3.5" />
                    <span>${stats.totalCost.toFixed(4)}</span>
                  </div>
                </>
              )}
              
              <div className="w-px h-4 bg-dark-border" />
              
              <div className="flex items-center gap-1.5 text-gray-400">
                <Clock className="w-3.5 h-3.5" />
                <span>{stats.avgResponseTime}s</span>
              </div>
            </div>

            {/* Settings Button */}
            <button className="p-2 rounded-lg hover:bg-dark-bg transition-colors">
              <SettingsIcon className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
      
      {/* Quick Info Bar (optional, for important messages) */}
      {keyMode === 'free_plus' && (
        <div className="px-4 py-2 bg-yellow-500/10 border-t border-yellow-500/20">
          <p className="text-xs text-yellow-500 text-center">
            <strong>FREE+:</strong> Günlük kota: 100 request. Kalan: 87
          </p>
        </div>
      )}
    </div>
  )
}
