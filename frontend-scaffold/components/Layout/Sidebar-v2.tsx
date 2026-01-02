'use client'

import { useState } from 'react'
import { MessageSquare, Menu, X, Trash2, Settings, User as UserIcon } from 'lucide-react'
import { useChatStore } from '@/lib/store'

interface SidebarProps {
  isOpen: boolean
  onToggle: () => void
}

export default function Sidebar({ isOpen, onToggle }: SidebarProps) {
  const { messages, clearMessages } = useChatStore()
  const messageCount = messages.length

  const handleClearChat = () => {
    if (messageCount === 0) return
    
    if (confirm(`Delete all ${messageCount} messages? This cannot be undone.`)) {
      clearMessages()
    }
  }

  return (
    <>
      {/* Mobile Overlay */}
      {isOpen && (
        <div 
          className="md:hidden fixed inset-0 bg-black/50 z-40"
          onClick={onToggle}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`
          fixed md:relative z-50
          h-full w-64 bg-slate-900 border-r border-slate-800
          transform transition-transform duration-300 ease-in-out
          ${isOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0 md:w-0'}
        `}
      >
        <div className="flex flex-col h-full">
          {/* Header */}
          <div className="flex items-center justify-between p-4 border-b border-slate-800">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-gradient-to-br from-cyan-500 to-blue-600 rounded-lg flex items-center justify-center">
                <MessageSquare className="w-5 h-5 text-white" />
              </div>
              <span className="font-semibold text-slate-200">Simon AI</span>
            </div>
            
            {/* Mobile close button */}
            <button 
              onClick={onToggle}
              className="md:hidden p-1 hover:bg-slate-800 rounded"
            >
              <X className="w-5 h-5 text-slate-400" />
            </button>
          </div>

          {/* Navigation */}
          <nav className="flex-1 p-3 space-y-1">
            <button className="w-full flex items-center gap-3 px-3 py-2 text-sm text-slate-300 hover:bg-slate-800 rounded-lg transition-colors">
              <MessageSquare className="w-4 h-4" />
              <span>New Chat</span>
            </button>
            
            {/* Message count indicator */}
            {messageCount > 0 && (
              <div className="px-3 py-2 text-xs text-slate-500">
                <span>{messageCount} message{messageCount !== 1 ? 's' : ''} in current chat</span>
              </div>
            )}
          </nav>

          {/* Bottom Actions */}
          <div className="p-3 border-t border-slate-800 space-y-1">
            {/* Clear Chat Button */}
            <button
              onClick={handleClearChat}
              disabled={messageCount === 0}
              className={`
                w-full flex items-center gap-3 px-3 py-2 text-sm rounded-lg transition-colors
                ${messageCount > 0
                  ? 'text-red-400 hover:bg-red-900/20'
                  : 'text-slate-600 cursor-not-allowed'
                }
              `}
              title={messageCount === 0 ? 'No messages to clear' : `Clear ${messageCount} messages`}
            >
              <Trash2 className="w-4 h-4" />
              <span>Clear Chat</span>
            </button>

            {/* Settings */}
            <button className="w-full flex items-center gap-3 px-3 py-2 text-sm text-slate-300 hover:bg-slate-800 rounded-lg transition-colors">
              <Settings className="w-4 h-4" />
              <span>Settings</span>
            </button>

            {/* Profile */}
            <div className="flex items-center gap-3 px-3 py-2 mt-2 border-t border-slate-800">
              <div className="w-8 h-8 rounded-full bg-slate-800 flex items-center justify-center">
                <UserIcon className="w-4 h-4 text-slate-400" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-sm font-medium text-slate-300 truncate">User</div>
                <div className="text-xs text-slate-500">Free Mode</div>
              </div>
            </div>
          </div>
        </div>
      </aside>

      {/* Mobile Toggle Button */}
      {!isOpen && (
        <button
          onClick={onToggle}
          className="md:hidden fixed top-4 left-4 z-40 p-2 bg-slate-900 border border-slate-800 rounded-lg shadow-lg"
        >
          <Menu className="w-5 h-5 text-slate-300" />
        </button>
      )}
    </>
  )
}
