'use client'

import { ChatWindow } from '@/components/Chat/ChatWindow'
import { Sidebar } from '@/components/Sidebar/Sidebar'
import { TopBar } from '@/components/TopBar/TopBar'

export default function Home() {
  return (
    <div className="flex h-screen bg-dark-bg text-dark-text">
      {/* Sidebar */}
      <Sidebar />
      
      {/* Main Content */}
      <div className="flex-1 flex flex-col">
        {/* Top Bar */}
        <TopBar />
        
        {/* Chat Window */}
        <ChatWindow />
      </div>
    </div>
  )
}
