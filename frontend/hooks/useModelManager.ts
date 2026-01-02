'use client'

import { useCallback, useEffect } from 'react'
import { useChatStore } from '@/lib/store'
import { MODELS, getModelsByKeyMode } from '@/lib/models'
import type { KeyMode } from '@/lib/types'

export function useModelManager() {
  const { selectedModel, keyMode, setModel, setKeyMode } = useChatStore()

  // Handle key mode change
  const handleKeyModeChange = useCallback((newKeyMode: KeyMode) => {
    const availableModels = getModelsByKeyMode(newKeyMode)
    
    // Check if current model is available in new key mode
    const currentModelAvailable = availableModels.some(m => m.id === selectedModel)
    
    if (!currentModelAvailable && availableModels.length > 0) {
      // Auto-select first available model
      const newModel = availableModels[0].id
      setModel(newModel)
      
      // Optional: Show toast notification
      console.log(`[Model Manager] Key mode changed to ${newKeyMode}, auto-selected ${newModel}`)
    }
    
    setKeyMode(newKeyMode)
  }, [selectedModel, setModel, setKeyMode])

  // Handle model change
  const handleModelChange = useCallback((modelId: string) => {
    const model = MODELS.find(m => m.id === modelId)
    
    if (!model) {
      console.error(`[Model Manager] Model not found: ${modelId}`)
      return
    }
    
    // Check if model is compatible with current key mode
    if (model.keyMode !== keyMode && model.keyMode !== 'ALL') {
      console.warn(`[Model Manager] Model ${modelId} not available in ${keyMode} mode`)
      return
    }
    
    setModel(modelId)
    console.log(`[Model Manager] Model changed to ${modelId}`)
  }, [keyMode, setModel])

  // Auto-adjust model on mount if incompatible
  useEffect(() => {
    const availableModels = getModelsByKeyMode(keyMode)
    const isCurrentModelValid = availableModels.some(m => m.id === selectedModel)
    
    if (!isCurrentModelValid && availableModels.length > 0) {
      const fallbackModel = availableModels[0].id
      setModel(fallbackModel)
      console.log(`[Model Manager] Auto-corrected to ${fallbackModel}`)
    }
  }, [keyMode, selectedModel, setModel])

  return {
    selectedModel,
    keyMode,
    handleKeyModeChange,
    handleModelChange,
  }
}
