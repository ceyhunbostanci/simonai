'use client'

export default function StreamingIndicator() {
  return (
    <div className="flex items-center gap-2 text-slate-400">
      <div className="flex gap-1">
        <div className="w-2 h-2 bg-cyan-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
        <div className="w-2 h-2 bg-cyan-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
        <div className="w-2 h-2 bg-cyan-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
      </div>
      <span className="text-xs">Simon AI is typing...</span>
    </div>
  )
}
