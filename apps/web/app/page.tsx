'use client'

import { ChatWindow } from '@/components/Chat/ChatWindow'
import { EnhancedSidebar } from '@/components/Sidebar/EnhancedSidebar'
import { EnhancedTopBar } from '@/components/TopBar/EnhancedTopBar'
import { RightPanel } from '@/components/RightPanel/RightPanel'

export default function Home() {
  return (
    <div className="flex h-screen bg-dark-bg text-dark-text">
      {/* Left Sidebar - Enhanced */}
      <EnhancedSidebar />
      
      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Top Bar - Enhanced */}
        <EnhancedTopBar />
        
        {/* Chat Window */}
        <ChatWindow />
      </div>
      
      {/* Right Panel - Widgets */}
      <RightPanel />
    </div>
  )
}
