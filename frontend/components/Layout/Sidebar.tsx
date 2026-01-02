'use client'

import { MessageSquare, Settings, Menu, X } from 'lucide-react'

interface SidebarProps {
  isOpen: boolean
  onToggle: () => void
}

export default function Sidebar({ isOpen, onToggle }: SidebarProps) {
  if (!isOpen) {
    return (
      <button
        onClick={onToggle}
        className="fixed top-4 left-4 z-50 p-2 bg-slate-800 rounded-lg hover:bg-slate-700 transition-colors md:hidden"
      >
        <Menu className="w-6 h-6" />
      </button>
    )
  }

  return (
    <>
      {/* Mobile Overlay */}
      <div
        className="fixed inset-0 bg-black/50 z-40 md:hidden"
        onClick={onToggle}
      />

      {/* Sidebar */}
      <aside className="fixed md:relative w-64 h-full bg-slate-900/50 backdrop-blur-xl border-r border-slate-800 z-50 flex flex-col">
        {/* Header */}
        <div className="p-4 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-gradient-to-br from-primary to-blue-600 rounded-lg" />
            <span className="font-bold text-lg">Simon AI</span>
          </div>
          <button
            onClick={onToggle}
            className="p-2 hover:bg-slate-800 rounded-lg transition-colors md:hidden"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Navigation (MVP: minimal) */}
        <nav className="flex-1 p-4 space-y-2">
          <button className="w-full flex items-center gap-3 p-3 rounded-lg bg-slate-800 text-white">
            <MessageSquare className="w-5 h-5" />
            <span>Chat</span>
          </button>
          
          <button className="w-full flex items-center gap-3 p-3 rounded-lg text-slate-400 hover:bg-slate-800 transition-colors">
            <Settings className="w-5 h-5" />
            <span>Settings</span>
          </button>
        </nav>

        {/* Footer */}
        <div className="p-4 border-t border-slate-800">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-slate-800 flex items-center justify-center">
              <span className="text-sm font-bold text-primary">CB</span>
            </div>
            <div className="flex-1">
              <p className="text-sm font-medium">User</p>
              <p className="text-xs text-slate-500">FREE Mode</p>
            </div>
          </div>
        </div>
      </aside>
    </>
  )
}
