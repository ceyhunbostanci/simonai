'use client'

import { Cpu, Activity } from 'lucide-react'
import ModelDropdown from '../ModelSelector/ModelDropdown'
import KeyModeSelector from '../ModelSelector/KeyModeSelector'

export default function TopBar() {
  return (
    <header className="h-16 border-b border-slate-800 bg-slate-900/50 backdrop-blur-md flex items-center justify-between px-6 z-10">
      {/* Left: Title */}
      <div className="flex items-center gap-4">
        <h1 className="text-lg font-semibold tracking-wide hidden sm:block text-slate-200">
          Chat
        </h1>
      </div>

      {/* Center: Model & Key Mode */}
      <div className="flex items-center gap-4">
        <KeyModeSelector />
        <ModelDropdown />
      </div>

      {/* Right: Status */}
      <div className="flex items-center gap-6 text-xs font-mono text-slate-400">
        <div className="hidden sm:flex items-center gap-2">
          <Cpu className="w-4 h-4 text-cyan-500" />
          <span>0 tokens</span>
        </div>
        <div className="hidden sm:flex items-center gap-2">
          <Activity className="w-4 h-4 text-purple-500" />
          <span>0ms</span>
        </div>
        <div className="px-3 py-1 rounded-full bg-green-500/10 text-green-400 border border-green-500/20 flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
          <span className="hidden sm:inline">ONLINE</span>
        </div>
      </div>
    </header>
  )
}
