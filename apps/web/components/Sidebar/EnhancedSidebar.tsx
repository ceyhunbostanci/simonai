'use client'

import { useState } from 'react'
import { 
  MessageSquare, Settings, User, Menu, X, Search, 
  FolderOpen, Plus, Trash2, Pin, MoreVertical, Moon, Sun 
} from 'lucide-react'
import { useChatStore } from '@/store/chatStore'

interface Chat {
  id: string
  title: string
  lastMessage: string
  timestamp: Date
  pinned: boolean
  projectId?: string
}

interface Project {
  id: string
  name: string
  color: string
  chatCount: number
}

export function EnhancedSidebar() {
  const { 
    isSidebarOpen, 
    toggleSidebar, 
    clearMessages,
    theme,
    toggleTheme 
  } = useChatStore()
  
  const [searchQuery, setSearchQuery] = useState('')
  const [activeTab, setActiveTab] = useState<'chats' | 'projects'>('chats')
  
  // Mock data (Faz 3'te database'den gelecek)
  const [chats] = useState<Chat[]>([
    {
      id: '1',
      title: 'React Component Tasarımı',
      lastMessage: 'Button component nasıl yapılır?',
      timestamp: new Date(),
      pinned: true,
    },
    {
      id: '2',
      title: 'API Entegrasyonu',
      lastMessage: 'FastAPI ile streaming...',
      timestamp: new Date(Date.now() - 3600000),
      pinned: false,
    },
    {
      id: '3',
      title: 'Database Optimizasyonu',
      lastMessage: 'PostgreSQL index stratejileri',
      timestamp: new Date(Date.now() - 7200000),
      pinned: false,
    },
  ])
  
  const [projects] = useState<Project[]>([
    { id: '1', name: 'Simon AI', color: 'bg-blue-500', chatCount: 15 },
    { id: '2', name: 'E-commerce', color: 'bg-green-500', chatCount: 8 },
    { id: '3', name: 'Marketing', color: 'bg-purple-500', chatCount: 5 },
  ])
  
  // Filter chats by search
  const filteredChats = chats.filter(chat => 
    chat.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    chat.lastMessage.toLowerCase().includes(searchQuery.toLowerCase())
  )
  
  // Separate pinned and unpinned
  const pinnedChats = filteredChats.filter(c => c.pinned)
  const unpinnedChats = filteredChats.filter(c => !c.pinned)

  return (
    <>
      {/* Mobile toggle */}
      <button
        onClick={toggleSidebar}
        className="lg:hidden fixed top-4 left-4 z-50 p-2 rounded-lg bg-dark-surface border border-dark-border"
      >
        {isSidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
      </button>

      {/* Sidebar */}
      <div
        className={`
          ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}
          lg:translate-x-0
          fixed lg:relative
          inset-y-0 left-0
          z-40
          w-80
          bg-dark-surface border-r border-dark-border
          transition-transform duration-200
          flex flex-col
        `}
      >
        {/* Header */}
        <div className="p-4 border-b border-dark-border">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-xl font-bold bg-gradient-to-r from-primary-400 to-primary-600 bg-clip-text text-transparent">
                Simon AI
              </h1>
              <p className="text-xs text-gray-500 mt-1">Agent Studio v3.1</p>
            </div>
            
            {/* Theme toggle */}
            <button
              onClick={toggleTheme}
              className="p-2 rounded-lg hover:bg-dark-bg transition-colors"
              title="Tema değiştir"
            >
              {theme === 'dark' ? (
                <Sun className="w-4 h-4" />
              ) : (
                <Moon className="w-4 h-4" />
              )}
            </button>
          </div>

          {/* New Chat Button */}
          <button
            onClick={clearMessages}
            className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg bg-primary-600 hover:bg-primary-700 text-white transition-colors font-medium"
          >
            <Plus className="w-4 h-4" />
            <span>Yeni Sohbet</span>
          </button>
        </div>

        {/* Search */}
        <div className="p-4 border-b border-dark-border">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Sohbet ara..."
              className="w-full pl-10 pr-4 py-2 bg-dark-bg border border-dark-border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-dark-border">
          <button
            onClick={() => setActiveTab('chats')}
            className={`flex-1 px-4 py-3 text-sm font-medium transition-colors ${
              activeTab === 'chats'
                ? 'text-primary-400 border-b-2 border-primary-400'
                : 'text-gray-500 hover:text-gray-300'
            }`}
          >
            Sohbetler
          </button>
          <button
            onClick={() => setActiveTab('projects')}
            className={`flex-1 px-4 py-3 text-sm font-medium transition-colors ${
              activeTab === 'projects'
                ? 'text-primary-400 border-b-2 border-primary-400'
                : 'text-gray-500 hover:text-gray-300'
            }`}
          >
            Projeler
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto">
          {activeTab === 'chats' ? (
            <div className="p-2 space-y-1">
              {/* Pinned Chats */}
              {pinnedChats.length > 0 && (
                <>
                  <div className="px-3 py-2 text-xs font-semibold text-gray-500 uppercase">
                    Sabitlenmiş
                  </div>
                  {pinnedChats.map(chat => (
                    <ChatItem key={chat.id} chat={chat} />
                  ))}
                  <div className="my-2 border-t border-dark-border" />
                </>
              )}
              
              {/* Recent Chats */}
              {unpinnedChats.length > 0 && (
                <>
                  <div className="px-3 py-2 text-xs font-semibold text-gray-500 uppercase">
                    Son Sohbetler
                  </div>
                  {unpinnedChats.map(chat => (
                    <ChatItem key={chat.id} chat={chat} />
                  ))}
                </>
              )}
              
              {/* Empty State */}
              {filteredChats.length === 0 && (
                <div className="p-8 text-center text-gray-500">
                  <MessageSquare className="w-12 h-12 mx-auto mb-3 opacity-50" />
                  <p className="text-sm">
                    {searchQuery ? 'Sohbet bulunamadı' : 'Henüz sohbet yok'}
                  </p>
                </div>
              )}
            </div>
          ) : (
            <div className="p-2 space-y-1">
              {projects.map(project => (
                <ProjectItem key={project.id} project={project} />
              ))}
              
              {/* New Project Button */}
              <button className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg hover:bg-dark-bg transition-colors text-left text-gray-400 hover:text-gray-300">
                <div className="w-8 h-8 rounded-lg border-2 border-dashed border-gray-600 flex items-center justify-center">
                  <Plus className="w-4 h-4" />
                </div>
                <span className="text-sm font-medium">Yeni Proje</span>
              </button>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-dark-border space-y-1">
          <button className="w-full flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-dark-bg transition-colors text-left">
            <Settings className="w-4 h-4" />
            <span className="text-sm">Ayarlar</span>
          </button>
          
          <button className="w-full flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-dark-bg transition-colors text-left">
            <User className="w-4 h-4" />
            <span className="text-sm">Profil</span>
          </button>
        </div>
      </div>

      {/* Overlay */}
      {isSidebarOpen && (
        <div
          className="lg:hidden fixed inset-0 bg-black/50 z-30"
          onClick={toggleSidebar}
        />
      )}
    </>
  )
}

// Chat Item Component
function ChatItem({ chat }: { chat: Chat }) {
  const [showMenu, setShowMenu] = useState(false)
  
  return (
    <div className="group relative">
      <button className="w-full flex items-start gap-3 px-3 py-2.5 rounded-lg hover:bg-dark-bg transition-colors text-left">
        <MessageSquare className="w-4 h-4 mt-0.5 flex-shrink-0 text-gray-500" />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-sm font-medium truncate">{chat.title}</h3>
            {chat.pinned && <Pin className="w-3 h-3 text-primary-400 flex-shrink-0" />}
          </div>
          <p className="text-xs text-gray-500 truncate">{chat.lastMessage}</p>
          <p className="text-xs text-gray-600 mt-1">
            {formatTimestamp(chat.timestamp)}
          </p>
        </div>
      </button>
      
      {/* Context Menu */}
      <button
        onClick={() => setShowMenu(!showMenu)}
        className="absolute right-2 top-2 p-1.5 rounded opacity-0 group-hover:opacity-100 hover:bg-dark-surface transition-opacity"
      >
        <MoreVertical className="w-4 h-4" />
      </button>
      
      {showMenu && (
        <div className="absolute right-2 top-10 w-48 bg-dark-surface border border-dark-border rounded-lg shadow-xl z-50 py-1">
          <button className="w-full px-4 py-2 text-sm text-left hover:bg-dark-bg flex items-center gap-2">
            <Pin className="w-3 h-3" />
            {chat.pinned ? 'Sabitlemeyi Kaldır' : 'Sabitle'}
          </button>
          <button className="w-full px-4 py-2 text-sm text-left hover:bg-dark-bg flex items-center gap-2 text-red-400">
            <Trash2 className="w-3 h-3" />
            Sil
          </button>
        </div>
      )}
    </div>
  )
}

// Project Item Component
function ProjectItem({ project }: { project: Project }) {
  return (
    <button className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg hover:bg-dark-bg transition-colors text-left">
      <div className={`w-8 h-8 rounded-lg ${project.color} flex-shrink-0`} />
      <div className="flex-1 min-w-0">
        <h3 className="text-sm font-medium truncate">{project.name}</h3>
        <p className="text-xs text-gray-500">{project.chatCount} sohbet</p>
      </div>
      <FolderOpen className="w-4 h-4 text-gray-500 flex-shrink-0" />
    </button>
  )
}

// Helper
function formatTimestamp(date: Date): string {
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)
  
  if (minutes < 1) return 'Şimdi'
  if (minutes < 60) return `${minutes} dakika önce`
  if (hours < 24) return `${hours} saat önce`
  if (days < 7) return `${days} gün önce`
  return date.toLocaleDateString('tr-TR')
}
