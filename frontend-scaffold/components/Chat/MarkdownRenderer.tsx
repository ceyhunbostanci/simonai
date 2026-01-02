'use client'

import ReactMarkdown from 'react-markdown'
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter'
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism'
import { Copy, Check } from 'lucide-react'
import { useState } from 'react'

interface CodeBlockProps {
  node?: any
  inline?: boolean
  className?: string
  children?: React.ReactNode
}

function CodeBlock({ inline, className, children, ...props }: CodeBlockProps) {
  const [copied, setCopied] = useState(false)
  const match = /language-(\w+)/.exec(className || '')
  const language = match ? match[1] : ''
  const code = String(children).replace(/\n$/, '')

  const handleCopy = async () => {
    await navigator.clipboard.writeText(code)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  // Inline code
  if (inline) {
    return (
      <code className="bg-slate-800 px-1.5 py-0.5 rounded text-cyan-400 text-sm font-mono" {...props}>
        {children}
      </code>
    )
  }

  // Code block with syntax highlighting
  return (
    <div className="relative group my-4">
      {/* Language badge */}
      {language && (
        <div className="absolute top-3 left-3 text-xs text-slate-400 bg-slate-800/80 px-2 py-1 rounded font-mono">
          {language}
        </div>
      )}

      {/* Copy button */}
      <button
        onClick={handleCopy}
        className="absolute top-3 right-3 p-2 bg-slate-800/80 hover:bg-slate-700 rounded transition-colors opacity-0 group-hover:opacity-100"
        title="Copy code"
      >
        {copied ? (
          <Check className="w-4 h-4 text-green-400" />
        ) : (
          <Copy className="w-4 h-4 text-slate-400" />
        )}
      </button>

      {/* Code */}
      <SyntaxHighlighter
        language={language || 'text'}
        style={vscDarkPlus}
        customStyle={{
          margin: 0,
          borderRadius: '0.5rem',
          padding: '1.5rem',
          paddingTop: '2.5rem', // Space for language badge
          fontSize: '0.875rem',
        }}
        {...props}
      >
        {code}
      </SyntaxHighlighter>
    </div>
  )
}

interface MarkdownRendererProps {
  content: string
  className?: string
}

export default function MarkdownRenderer({ content, className = '' }: MarkdownRendererProps) {
  return (
    <div className={`prose prose-invert prose-slate max-w-none ${className}`}>
      <ReactMarkdown
        components={{
          code: CodeBlock,
          // Custom heading styles
          h1: ({ node, ...props }) => (
            <h1 className="text-2xl font-bold text-slate-100 mb-4 mt-6" {...props} />
          ),
          h2: ({ node, ...props }) => (
            <h2 className="text-xl font-bold text-slate-200 mb-3 mt-5" {...props} />
          ),
          h3: ({ node, ...props }) => (
            <h3 className="text-lg font-semibold text-slate-300 mb-2 mt-4" {...props} />
          ),
          // Custom list styles
          ul: ({ node, ...props }) => (
            <ul className="list-disc list-inside space-y-1 my-2 text-slate-300" {...props} />
          ),
          ol: ({ node, ...props }) => (
            <ol className="list-decimal list-inside space-y-1 my-2 text-slate-300" {...props} />
          ),
          // Custom link styles
          a: ({ node, ...props }) => (
            <a
              className="text-cyan-400 hover:text-cyan-300 underline transition-colors"
              target="_blank"
              rel="noopener noreferrer"
              {...props}
            />
          ),
          // Custom blockquote
          blockquote: ({ node, ...props }) => (
            <blockquote
              className="border-l-4 border-cyan-500 pl-4 py-2 my-4 bg-slate-800/30 text-slate-300 italic"
              {...props}
            />
          ),
          // Custom table
          table: ({ node, ...props }) => (
            <div className="overflow-x-auto my-4">
              <table className="min-w-full border border-slate-700 rounded-lg" {...props} />
            </div>
          ),
          thead: ({ node, ...props }) => (
            <thead className="bg-slate-800" {...props} />
          ),
          th: ({ node, ...props }) => (
            <th className="px-4 py-2 text-left text-slate-200 font-semibold border-b border-slate-700" {...props} />
          ),
          td: ({ node, ...props }) => (
            <td className="px-4 py-2 text-slate-300 border-b border-slate-800" {...props} />
          ),
          // Custom paragraph
          p: ({ node, ...props }) => (
            <p className="text-slate-300 leading-relaxed my-2" {...props} />
          ),
        }}
      >
        {content}
      </ReactMarkdown>
    </div>
  )
}
