'use client'

import { useChatStore } from '@/lib/store'
import { Clock, Hash, Zap } from 'lucide-react'

export default function UsageStats() {
  const { messages } = useChatStore()
  
  // Calculate total tokens
  const totalTokens = messages.reduce((sum, msg) => sum + (msg.tokens || 0), 0)
  
  // Calculate total messages
  const userMessages = messages.filter(m => m.role === 'user').length
  const assistantMessages = messages.filter(m => m.role === 'assistant').length
  
  // Calculate session duration (from first message)
  const firstMessage = messages[0]
  const sessionStart = firstMessage ? new Date(firstMessage.timestamp) : new Date()
  const sessionDuration = Math.floor((Date.now() - sessionStart.getTime()) / 1000 / 60) // minutes
  
  // Calculate average response time
  const responseTimes: number[] = []
  for (let i = 1; i < messages.length; i += 2) {
    if (messages[i - 1]?.role === 'user' && messages[i]?.role === 'assistant') {
      const userTime = new Date(messages[i - 1].timestamp).getTime()
      const assistantTime = new Date(messages[i].timestamp).getTime()
      responseTimes.push(assistantTime - userTime)
    }
  }
  const avgResponseTime = responseTimes.length > 0
    ? Math.floor(responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length / 1000)
    : 0

  if (messages.length === 0) {
    return null
  }

  return (
    <div className="flex items-center gap-4 text-xs text-slate-400">
      {/* Token Count */}
      <div className="flex items-center gap-1.5 px-2 py-1 rounded bg-slate-800/50 border border-slate-700/50">
        <Hash className="w-3 h-3 text-cyan-400" />
        <span className="font-mono">{totalTokens.toLocaleString()}</span>
        <span className="text-[10px] opacity-70">tokens</span>
      </div>
      
      {/* Message Count */}
      <div className="flex items-center gap-1.5 px-2 py-1 rounded bg-slate-800/50 border border-slate-700/50">
        <span className="font-mono">{userMessages}</span>
        <span className="text-[10px] opacity-70">/</span>
        <span className="font-mono">{assistantMessages}</span>
        <span className="text-[10px] opacity-70">msgs</span>
      </div>
      
      {/* Session Duration */}
      {sessionDuration > 0 && (
        <div className="flex items-center gap-1.5 px-2 py-1 rounded bg-slate-800/50 border border-slate-700/50">
          <Clock className="w-3 h-3 text-purple-400" />
          <span className="font-mono">{sessionDuration}</span>
          <span className="text-[10px] opacity-70">min</span>
        </div>
      )}
      
      {/* Avg Response Time */}
      {avgResponseTime > 0 && (
        <div className="flex items-center gap-1.5 px-2 py-1 rounded bg-slate-800/50 border border-slate-700/50">
          <Zap className="w-3 h-3 text-yellow-400" />
          <span className="font-mono">{avgResponseTime}s</span>
          <span className="text-[10px] opacity-70">avg</span>
        </div>
      )}
    </div>
  )
}
