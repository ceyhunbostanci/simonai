'use client'

import { useState } from 'react'
import { X, Maximize2, Minimize2, ExternalLink, RefreshCw } from 'lucide-react'
import { useChatStore } from '@/store/chatStore'

interface Widget {
  id: string
  title: string
  type: 'news' | 'weather' | 'calendar' | 'notes' | 'custom'
  content: any
}

export function RightPanel() {
  const { isRightPanelOpen, toggleRightPanel } = useChatStore()
  const [widgets, setWidgets] = useState<Widget[]>([
    {
      id: '1',
      title: 'AI Haberler',
      type: 'news',
      content: [
        { title: 'Claude 4 Sonnet Released', url: '#', time: '2 saat önce' },
        { title: 'GPT-5 Rumors Intensify', url: '#', time: '5 saat önce' },
        { title: 'Google Gemini Updates', url: '#', time: '1 gün önce' },
      ],
    },
    {
      id: '2',
      title: 'Hızlı Notlar',
      type: 'notes',
      content: {
        notes: [
          'React 19 yeni özelliklerini incele',
          'API endpoint dokumentasyonunu tamamla',
          'Test coverage %80\'e çıkar',
        ],
      },
    },
  ])
  
  const [expandedWidget, setExpandedWidget] = useState<string | null>(null)

  if (!isRightPanelOpen) {
    return (
      <button
        onClick={toggleRightPanel}
        className="fixed right-0 top-1/2 -translate-y-1/2 p-2 bg-dark-surface border border-dark-border rounded-l-lg hover:bg-dark-bg transition-colors z-30"
        title="Widget panelini aç"
      >
        <ExternalLink className="w-4 h-4" />
      </button>
    )
  }

  return (
    <div className="w-80 bg-dark-surface border-l border-dark-border flex flex-col">
      {/* Header */}
      <div className="p-4 border-b border-dark-border flex items-center justify-between">
        <h2 className="text-sm font-semibold">Widgets</h2>
        <button
          onClick={toggleRightPanel}
          className="p-1.5 rounded hover:bg-dark-bg transition-colors"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      {/* Widgets */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {widgets.map(widget => (
          <WidgetCard
            key={widget.id}
            widget={widget}
            isExpanded={expandedWidget === widget.id}
            onToggleExpand={() => 
              setExpandedWidget(expandedWidget === widget.id ? null : widget.id)
            }
          />
        ))}
        
        {/* Add Widget Button */}
        <button className="w-full py-8 border-2 border-dashed border-dark-border rounded-lg hover:border-primary-500 hover:bg-dark-bg/50 transition-colors text-gray-500 hover:text-gray-300">
          <div className="text-center">
            <ExternalLink className="w-6 h-6 mx-auto mb-2" />
            <p className="text-sm font-medium">Widget Ekle</p>
          </div>
        </button>
      </div>
    </div>
  )
}

function WidgetCard({ 
  widget, 
  isExpanded, 
  onToggleExpand 
}: { 
  widget: Widget
  isExpanded: boolean
  onToggleExpand: () => void
}) {
  return (
    <div className="bg-dark-bg border border-dark-border rounded-lg overflow-hidden">
      {/* Widget Header */}
      <div className="px-3 py-2.5 border-b border-dark-border flex items-center justify-between">
        <h3 className="text-sm font-medium">{widget.title}</h3>
        <div className="flex items-center gap-1">
          <button 
            className="p-1 rounded hover:bg-dark-surface transition-colors"
            title="Yenile"
          >
            <RefreshCw className="w-3.5 h-3.5" />
          </button>
          <button 
            onClick={onToggleExpand}
            className="p-1 rounded hover:bg-dark-surface transition-colors"
            title={isExpanded ? 'Küçült' : 'Genişlet'}
          >
            {isExpanded ? (
              <Minimize2 className="w-3.5 h-3.5" />
            ) : (
              <Maximize2 className="w-3.5 h-3.5" />
            )}
          </button>
        </div>
      </div>

      {/* Widget Content */}
      <div className={`p-3 ${isExpanded ? 'max-h-96' : 'max-h-48'} overflow-y-auto transition-all`}>
        {widget.type === 'news' && (
          <div className="space-y-3">
            {widget.content.map((item: any, idx: number) => (
              <a
                key={idx}
                href={item.url}
                className="block group"
              >
                <h4 className="text-sm font-medium group-hover:text-primary-400 transition-colors line-clamp-2">
                  {item.title}
                </h4>
                <p className="text-xs text-gray-500 mt-1">{item.time}</p>
              </a>
            ))}
          </div>
        )}
        
        {widget.type === 'notes' && (
          <div className="space-y-2">
            {widget.content.notes.map((note: string, idx: number) => (
              <div key={idx} className="flex items-start gap-2">
                <input
                  type="checkbox"
                  className="mt-1 rounded border-dark-border"
                />
                <p className="text-sm text-gray-300">{note}</p>
              </div>
            ))}
            
            <button className="w-full mt-3 py-2 text-sm text-primary-400 hover:text-primary-300 transition-colors">
              + Not ekle
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
