'use client'

import ModelDropdown from '../Model/ModelDropdown'
import KeyModeSelector from '../Model/KeyModeSelector'
import UsageStats from '../Stats/UsageStats'
import { Activity } from 'lucide-react'

export default function TopBar() {
  return (
    <div className="h-16 border-b border-slate-800 bg-slate-900/50 backdrop-blur-md flex items-center justify-between px-6 z-10">
      {/* Left: Model Selection */}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2">
          <Activity className="w-4 h-4 text-primary" />
          <span className="text-sm font-medium text-slate-300">Simon AI</span>
        </div>
        
        <div className="h-6 w-px bg-slate-700" />
        
        <KeyModeSelector />
        
        <ModelDropdown />
      </div>

      {/* Right: Usage Stats & Status */}
      <div className="flex items-center gap-6">
        <UsageStats />
        
        {/* Status Indicator */}
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-green-500/10 text-green-400 border border-green-500/20">
          <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
          <span className="text-xs font-medium">ONLINE</span>
        </div>
      </div>
    </div>
  )
}
