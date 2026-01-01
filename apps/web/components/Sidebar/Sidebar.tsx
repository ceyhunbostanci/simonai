'use client'

import { MessageSquare, Settings, User, Menu, X } from 'lucide-react'
import { useChatStore } from '@/store/chatStore'

export function Sidebar() {
  const { isSidebarOpen, toggleSidebar, clearMessages } = useChatStore()

  return (
    <>
      {/* Mobile toggle button */}
      <button
        onClick={toggleSidebar}
        className="lg:hidden fixed top-4 left-4 z-50 p-2 rounded-lg bg-dark-surface border border-dark-border"
      >
        {isSidebarOpen ? (
          <X className="w-5 h-5" />
        ) : (
          <Menu className="w-5 h-5" />
        )}
      </button>

      {/* Sidebar */}
      <div
        className={`
          ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}
          lg:translate-x-0
          fixed lg:relative
          inset-y-0 left-0
          z-40
          w-64
          bg-dark-surface border-r border-dark-border
          transition-transform duration-200
          flex flex-col
        `}
      >
        {/* Logo */}
        <div className="p-4 border-b border-dark-border">
          <h1 className="text-xl font-bold bg-gradient-to-r from-primary-400 to-primary-600 bg-clip-text text-transparent">
            Simon AI
          </h1>
          <p className="text-xs text-gray-500 mt-1">Agent Studio v3.1</p>
        </div>

        {/* New Chat Button */}
        <div className="p-4">
          <button
            onClick={clearMessages}
            className="w-full flex items-center gap-2 px-4 py-2 rounded-lg bg-primary-600 hover:bg-primary-700 text-white transition-colors"
          >
            <MessageSquare className="w-4 h-4" />
            <span>Yeni Sohbet</span>
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-4 py-2 space-y-1">
          <button className="w-full flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-dark-bg transition-colors text-left">
            <MessageSquare className="w-4 h-4" />
            <span>Sohbetler</span>
          </button>
          
          <button className="w-full flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-dark-bg transition-colors text-left">
            <Settings className="w-4 h-4" />
            <span>Ayarlar</span>
          </button>
        </nav>

        {/* User */}
        <div className="p-4 border-t border-dark-border">
          <button className="w-full flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-dark-bg transition-colors text-left">
            <User className="w-4 h-4" />
            <span>Profil</span>
          </button>
        </div>
      </div>

      {/* Overlay for mobile */}
      {isSidebarOpen && (
        <div
          className="lg:hidden fixed inset-0 bg-black/50 z-30"
          onClick={toggleSidebar}
        />
      )}
    </>
  )
}
