import { useState } from 'react'
import {
  Search,
  Send,
  Check,
  CheckCheck,
  MessageSquare,
  MoreVertical,
  Phone,
  Video,
  Paperclip,
  Smile,
  Image,
  Mic,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Avatar, Badge } from '@/components/ui'
import { useStudentsStore } from '@/store/students-store'
import { formatRelativeTime, cn } from '@/lib/utils'
import type { Conversation, Message } from '@/types'

// Mock conversations
const mockConversations: (Conversation & { messages: Message[] })[] = [
  {
    id: 'conv-1',
    studentId: 'student-1',
    unreadCount: 2,
    updatedAt: new Date().toISOString(),
    messages: [
      {
        id: 'm1',
        conversationId: 'conv-1',
        senderId: 'student-1',
        content: 'Coach, je peux remplacer le squat par du leg press cette semaine ?',
        sentAt: new Date(Date.now() - 3600000).toISOString(),
      },
      {
        id: 'm2',
        conversationId: 'conv-1',
        senderId: 'coach-1',
        content: 'Oui bien sûr, ça convient parfaitement. Fais 4 séries au lieu de 3.',
        sentAt: new Date(Date.now() - 1800000).toISOString(),
        readAt: new Date(Date.now() - 1700000).toISOString(),
      },
      {
        id: 'm3',
        conversationId: 'conv-1',
        senderId: 'student-1',
        content: 'Super merci ! Et pour les macros du weekend, je peux faire un cheat meal ?',
        sentAt: new Date(Date.now() - 600000).toISOString(),
      },
    ],
  },
  {
    id: 'conv-2',
    studentId: 'student-2',
    unreadCount: 0,
    updatedAt: new Date(Date.now() - 86400000).toISOString(),
    messages: [
      {
        id: 'm4',
        conversationId: 'conv-2',
        senderId: 'student-2',
        content: 'Ma séance était super ce matin, nouveau PR au deadlift !',
        sentAt: new Date(Date.now() - 86400000).toISOString(),
      },
      {
        id: 'm5',
        conversationId: 'conv-2',
        senderId: 'coach-1',
        content: 'Bravo Thomas ! Continue comme ça 💪',
        sentAt: new Date(Date.now() - 85000000).toISOString(),
        readAt: new Date(Date.now() - 84000000).toISOString(),
      },
    ],
  },
  {
    id: 'conv-3',
    studentId: 'student-4',
    unreadCount: 1,
    updatedAt: new Date(Date.now() - 172800000).toISOString(),
    messages: [
      {
        id: 'm6',
        conversationId: 'conv-3',
        senderId: 'student-4',
        content: 'Est-ce que je peux augmenter les calories le weekend ?',
        sentAt: new Date(Date.now() - 172800000).toISOString(),
      },
    ],
  },
]

const quickReplies = [
  'Super travail ! 💪',
  'On en parle demain ?',
  "Pas de souci, c'est noté.",
  "Envoie-moi ton journal.",
  'Parfait 👍',
]

export function MessagesPage() {
  const { students } = useStudentsStore()
  const [selectedConversationId, setSelectedConversationId] = useState<string | null>(
    mockConversations[0]?.id || null
  )
  const [newMessage, setNewMessage] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
  const [focusedInput, setFocusedInput] = useState(false)

  const selectedConversation = mockConversations.find(
    (c) => c.id === selectedConversationId
  )
  const selectedStudent = selectedConversation
    ? students.find((s) => s.id === selectedConversation.studentId)
    : null

  const filteredConversations = mockConversations.filter((conv) => {
    const student = students.find((s) => s.id === conv.studentId)
    return student?.name.toLowerCase().includes(searchQuery.toLowerCase())
  })

  const totalUnread = mockConversations.reduce((acc, c) => acc + c.unreadCount, 0)

  const handleSend = () => {
    if (!newMessage.trim()) return
    // In real app, would send message
    setNewMessage('')
  }

  return (
    <div className="min-h-screen">
      <Header
        title="Messages"
        subtitle={totalUnread > 0 ? `${totalUnread} non lu${totalUnread > 1 ? 's' : ''}` : 'Toutes les conversations'}
      />

      <div className="p-8">
        <div className="grid grid-cols-3 gap-6 h-[calc(100vh-180px)]">
          {/* Conversations List */}
          <div className={cn(
            'rounded-2xl overflow-hidden flex flex-col',
            'bg-surface border border-border',
            'animate-[fadeIn_0.4s_ease-out]'
          )}>
            {/* Search header */}
            <div className="p-4 border-b border-border">
              <div className="relative group">
                <Search className="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-text-muted group-focus-within:text-accent transition-colors" />
                <input
                  type="text"
                  placeholder="Rechercher une conversation..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className={cn(
                    'w-full h-11 pl-11 pr-4 rounded-xl',
                    'bg-surface-elevated border border-border',
                    'text-text-primary placeholder:text-text-muted text-sm',
                    'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                    'transition-all duration-200'
                  )}
                />
              </div>
            </div>

            {/* Conversations */}
            <div className="flex-1 overflow-y-auto p-2">
              {filteredConversations.map((conv, index) => {
                const student = students.find((s) => s.id === conv.studentId)
                if (!student) return null

                const lastMessage = conv.messages[conv.messages.length - 1]
                const isSelected = conv.id === selectedConversationId

                return (
                  <button
                    key={conv.id}
                    onClick={() => setSelectedConversationId(conv.id)}
                    className={cn(
                      'w-full flex items-start gap-3 p-3 rounded-xl text-left transition-all duration-200',
                      'animate-[fadeIn_0.3s_ease-out]',
                      isSelected
                        ? 'bg-accent/10 border border-accent/30'
                        : 'hover:bg-surface-elevated border border-transparent'
                    )}
                    style={{ animationDelay: `${index * 50}ms` }}
                  >
                    <div className="relative flex-shrink-0">
                      <Avatar name={student.name} size="md" />
                      {conv.unreadCount > 0 && (
                        <span className={cn(
                          'absolute -top-1 -right-1 w-5 h-5 rounded-full flex items-center justify-center',
                          'bg-accent text-white text-xs font-semibold',
                          'animate-pulse'
                        )}>
                          {conv.unreadCount}
                        </span>
                      )}
                      {/* Online indicator */}
                      <span className="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-success border-2 border-surface" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-1">
                        <p className={cn(
                          'font-semibold truncate',
                          isSelected ? 'text-accent' : 'text-text-primary'
                        )}>
                          {student.name}
                        </p>
                        <span className="text-xs text-text-muted flex-shrink-0 ml-2">
                          {formatRelativeTime(conv.updatedAt)}
                        </span>
                      </div>
                      <p className={cn(
                        'text-sm truncate',
                        conv.unreadCount > 0 ? 'text-text-secondary font-medium' : 'text-text-muted'
                      )}>
                        {lastMessage?.content}
                      </p>
                    </div>
                  </button>
                )
              })}

              {filteredConversations.length === 0 && (
                <div className="flex flex-col items-center justify-center py-12">
                  <div className="w-12 h-12 rounded-xl bg-surface-elevated flex items-center justify-center mb-3">
                    <MessageSquare className="w-6 h-6 text-text-muted" />
                  </div>
                  <p className="text-sm text-text-muted">Aucune conversation</p>
                </div>
              )}
            </div>
          </div>

          {/* Conversation */}
          <div className={cn(
            'col-span-2 rounded-2xl overflow-hidden flex flex-col',
            'bg-surface border border-border',
            'animate-[fadeIn_0.4s_ease-out]'
          )}>
            {selectedConversation && selectedStudent ? (
              <>
                {/* Header */}
                <div className={cn(
                  'px-6 py-4 border-b border-border',
                  'flex items-center justify-between'
                )}>
                  <div className="flex items-center gap-4">
                    <div className="relative">
                      <Avatar name={selectedStudent.name} size="lg" />
                      <span className="absolute bottom-0 right-0 w-3.5 h-3.5 rounded-full bg-success border-2 border-surface" />
                    </div>
                    <div>
                      <p className="font-semibold text-text-primary">
                        {selectedStudent.name}
                      </p>
                      <p className="text-sm text-success">En ligne</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <button className={cn(
                      'p-2.5 rounded-lg transition-all duration-200',
                      'text-text-muted hover:text-text-primary hover:bg-surface-elevated'
                    )}>
                      <Phone className="w-5 h-5" />
                    </button>
                    <button className={cn(
                      'p-2.5 rounded-lg transition-all duration-200',
                      'text-text-muted hover:text-text-primary hover:bg-surface-elevated'
                    )}>
                      <Video className="w-5 h-5" />
                    </button>
                    <button className={cn(
                      'p-2.5 rounded-lg transition-all duration-200',
                      'text-text-muted hover:text-text-primary hover:bg-surface-elevated'
                    )}>
                      <MoreVertical className="w-5 h-5" />
                    </button>
                  </div>
                </div>

                {/* Messages */}
                <div className="flex-1 overflow-y-auto p-6 space-y-4">
                  {selectedConversation.messages.map((message, index) => {
                    const isCoach = message.senderId === 'coach-1'

                    return (
                      <div
                        key={message.id}
                        className={cn(
                          'flex animate-[fadeIn_0.3s_ease-out]',
                          isCoach ? 'justify-end' : 'justify-start'
                        )}
                        style={{ animationDelay: `${index * 50}ms` }}
                      >
                        {!isCoach && (
                          <Avatar
                            name={selectedStudent.name}
                            size="sm"
                            className="mr-2 flex-shrink-0"
                          />
                        )}
                        <div
                          className={cn(
                            'max-w-[70%] px-4 py-3 rounded-2xl',
                            isCoach
                              ? 'bg-gradient-to-br from-accent to-[#ff8f5c] text-white rounded-br-md'
                              : 'bg-surface-elevated text-text-primary rounded-bl-md border border-border'
                          )}
                        >
                          <p className="text-sm leading-relaxed">{message.content}</p>
                          <div
                            className={cn(
                              'flex items-center gap-1.5 mt-2',
                              isCoach ? 'justify-end' : 'justify-start'
                            )}
                          >
                            <span
                              className={cn(
                                'text-xs',
                                isCoach ? 'text-white/70' : 'text-text-muted'
                              )}
                            >
                              {formatRelativeTime(message.sentAt)}
                            </span>
                            {isCoach && (
                              message.readAt ? (
                                <CheckCheck className="w-3.5 h-3.5 text-white/70" />
                              ) : (
                                <Check className="w-3.5 h-3.5 text-white/70" />
                              )
                            )}
                          </div>
                        </div>
                      </div>
                    )
                  })}
                </div>

                {/* Quick replies */}
                <div className="px-6 py-3 border-t border-border">
                  <div className="flex items-center gap-2 overflow-x-auto pb-1">
                    {quickReplies.map((reply, i) => (
                      <button
                        key={i}
                        onClick={() => setNewMessage(reply)}
                        className={cn(
                          'px-3 py-1.5 rounded-full whitespace-nowrap',
                          'bg-surface-elevated border border-border',
                          'text-sm text-text-secondary',
                          'hover:text-accent hover:border-accent/30',
                          'transition-all duration-200'
                        )}
                      >
                        {reply}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Input */}
                <div className="px-6 py-4 border-t border-border">
                  <div className={cn(
                    'flex items-center gap-3 p-2 rounded-xl transition-all duration-300',
                    'bg-surface-elevated border',
                    focusedInput
                      ? 'border-accent shadow-[0_0_20px_rgba(255,107,53,0.1)]'
                      : 'border-border'
                  )}>
                    <div className="flex items-center gap-1">
                      <button className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface transition-colors">
                        <Paperclip className="w-5 h-5" />
                      </button>
                      <button className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface transition-colors">
                        <Image className="w-5 h-5" />
                      </button>
                    </div>
                    <input
                      type="text"
                      placeholder="Écrire un message..."
                      value={newMessage}
                      onChange={(e) => setNewMessage(e.target.value)}
                      onFocus={() => setFocusedInput(true)}
                      onBlur={() => setFocusedInput(false)}
                      onKeyDown={(e) => e.key === 'Enter' && handleSend()}
                      className={cn(
                        'flex-1 bg-transparent text-text-primary placeholder:text-text-muted',
                        'text-sm outline-none'
                      )}
                    />
                    <div className="flex items-center gap-1">
                      <button className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface transition-colors">
                        <Smile className="w-5 h-5" />
                      </button>
                      <button className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface transition-colors">
                        <Mic className="w-5 h-5" />
                      </button>
                      <button
                        onClick={handleSend}
                        disabled={!newMessage.trim()}
                        className={cn(
                          'p-2.5 rounded-xl transition-all duration-300',
                          newMessage.trim()
                            ? 'bg-gradient-to-r from-accent to-[#ff8f5c] text-white shadow-md shadow-accent/30 hover:shadow-lg hover:shadow-accent/40'
                            : 'bg-surface text-text-muted cursor-not-allowed'
                        )}
                      >
                        <Send className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </div>
              </>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center">
                <div className="w-20 h-20 rounded-2xl bg-surface-elevated flex items-center justify-center mb-5">
                  <MessageSquare className="w-10 h-10 text-text-muted" />
                </div>
                <h3 className="text-lg font-semibold text-text-primary mb-2">
                  Vos messages
                </h3>
                <p className="text-sm text-text-muted text-center max-w-xs">
                  Sélectionnez une conversation pour commencer à discuter avec vos élèves
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
