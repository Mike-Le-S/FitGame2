import { useState, useRef, useEffect } from 'react'
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
  Plus,
  Loader2,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Avatar } from '@/components/ui'
import { useStudentsStore } from '@/store/students-store'
import { useMessagesStore } from '@/store/messages-store'
import { useAuthStore } from '@/store/auth-store'
import { formatRelativeTime, cn } from '@/lib/utils'

const quickReplies = [
  'Super travail ! 💪',
  'On en parle demain ?',
  "Pas de souci, c'est noté.",
  "Envoie-moi ton journal.",
  'Parfait 👍',
]

export function MessagesPage() {
  const { students } = useStudentsStore()
  const { coach } = useAuthStore()
  const {
    conversations,
    isLoading,
    sendMessage,
    markAsRead,
    getConversationByStudentId,
    getTotalUnread
  } = useMessagesStore()

  // Selected student ID (conversations are keyed by studentId)
  const [selectedStudentId, setSelectedStudentId] = useState<string | null>(
    conversations[0]?.studentId || null
  )
  const [newMessage, setNewMessage] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
  const [focusedInput, setFocusedInput] = useState(false)
  const [showNewConversation, setShowNewConversation] = useState(false)
  const [isSending, setIsSending] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)

  const selectedConversation = selectedStudentId
    ? getConversationByStudentId(selectedStudentId)
    : null
  const selectedStudent = selectedStudentId
    ? students.find((s) => s.id === selectedStudentId)
    : null

  const filteredConversations = conversations.filter((conv) => {
    const student = students.find((s) => s.id === conv.studentId)
    return student?.name.toLowerCase().includes(searchQuery.toLowerCase())
  })

  const totalUnread = getTotalUnread()

  // Students without a conversation (for starting new conversations)
  const studentsWithoutConversation = students.filter(
    (s) => !conversations.some((c) => c.studentId === s.id)
  )

  // Scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [selectedConversation?.messages])

  // Mark conversation as read when selected
  useEffect(() => {
    if (selectedStudentId && (selectedConversation?.unreadCount ?? 0) > 0) {
      markAsRead(selectedStudentId)
    }
  }, [selectedStudentId, selectedConversation?.unreadCount, markAsRead])

  // Auto-select first conversation when loaded
  useEffect(() => {
    if (!selectedStudentId && conversations.length > 0) {
      setSelectedStudentId(conversations[0].studentId)
    }
  }, [conversations, selectedStudentId])

  const handleSend = async () => {
    if (!newMessage.trim() || !selectedStudentId || isSending) return

    setIsSending(true)
    try {
      await sendMessage(selectedStudentId, newMessage.trim())
      setNewMessage('')
    } catch (error) {
      console.error('Error sending message:', error)
    } finally {
      setIsSending(false)
    }
  }

  const handleStartConversation = async (studentId: string) => {
    // Just select the student - conversation will be created on first message
    setSelectedStudentId(studentId)
    setShowNewConversation(false)
  }

  return (
    <div className="min-h-screen">
      <Header
        title="Messages"
        subtitle={totalUnread > 0 ? `${totalUnread} non lu${totalUnread > 1 ? 's' : ''}` : 'Toutes les conversations'}
        showSearch={false}
        action={
          <button
            onClick={() => setShowNewConversation(true)}
            className={cn(
              'flex items-center gap-2 h-11 px-5 rounded-xl font-semibold text-white',
              'bg-gradient-to-r from-accent to-[#ff8f5c]',
              'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
              'transition-all duration-300'
            )}
          >
            <Plus className="w-5 h-5" />
            Nouvelle conversation
          </button>
        }
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
              {isLoading ? (
                <div className="flex items-center justify-center py-12">
                  <Loader2 className="w-6 h-6 text-accent animate-spin" />
                </div>
              ) : filteredConversations.map((conv, index) => {
                const student = students.find((s) => s.id === conv.studentId)
                if (!student) return null

                const lastMessage = conv.messages[conv.messages.length - 1]
                const isSelected = conv.studentId === selectedStudentId

                return (
                  <button
                    key={conv.studentId}
                    onClick={() => setSelectedStudentId(conv.studentId)}
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
                        <span className="text-xs text-text-muted shrink-0 ml-2">
                          {formatRelativeTime(conv.updatedAt)}
                        </span>
                      </div>
                      <p className={cn(
                        'text-sm truncate',
                        conv.unreadCount > 0 ? 'text-text-secondary font-medium' : 'text-text-muted'
                      )}>
                        {lastMessage?.content || 'Aucun message'}
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
                    <button
                      className={cn(
                        'p-2.5 rounded-lg transition-all duration-200',
                        'text-text-muted hover:text-text-primary hover:bg-surface-elevated'
                      )}
                    >
                      <MoreVertical className="w-5 h-5" />
                    </button>
                  </div>
                </div>

                {/* Messages */}
                <div className="flex-1 overflow-y-auto p-6 space-y-4">
                  {selectedConversation.messages.length === 0 ? (
                    <div className="flex flex-col items-center justify-center h-full">
                      <div className="w-16 h-16 rounded-2xl bg-surface-elevated flex items-center justify-center mb-4">
                        <MessageSquare className="w-8 h-8 text-text-muted" />
                      </div>
                      <p className="text-text-secondary font-medium mb-1">
                        Nouvelle conversation
                      </p>
                      <p className="text-sm text-text-muted text-center">
                        Envoyez un message pour commencer
                      </p>
                    </div>
                  ) : (
                    selectedConversation.messages.map((message, index) => {
                      const isCoach = message.senderId === coach?.id

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
                            <p className="text-sm leading-relaxed break-words">{message.content}</p>
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
                    })
                  )}
                  <div ref={messagesEndRef} />
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
                        disabled={!newMessage.trim() || isSending}
                        className={cn(
                          'p-2.5 rounded-xl transition-all duration-300',
                          newMessage.trim() && !isSending
                            ? 'bg-gradient-to-r from-accent to-[#ff8f5c] text-white shadow-md shadow-accent/30 hover:shadow-lg hover:shadow-accent/40'
                            : 'bg-surface text-text-muted cursor-not-allowed'
                        )}
                      >
                        {isSending ? (
                          <Loader2 className="w-5 h-5 animate-spin" />
                        ) : (
                          <Send className="w-5 h-5" />
                        )}
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

      {/* New Conversation Modal */}
      {showNewConversation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setShowNewConversation(false)}
          />

          <div className={cn(
            'relative w-full max-w-md mx-4',
            'bg-surface border border-border rounded-2xl',
            'shadow-2xl animate-[fadeIn_0.2s_ease-out]'
          )}>
            <div className="flex items-center justify-between p-6 border-b border-border">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-accent/10 flex items-center justify-center">
                  <MessageSquare className="w-5 h-5 text-accent" />
                </div>
                <div>
                  <h2 className="text-lg font-semibold text-text-primary">Nouvelle conversation</h2>
                  <p className="text-sm text-text-muted">Choisissez un élève</p>
                </div>
              </div>
              <button
                onClick={() => setShowNewConversation(false)}
                className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface-elevated transition-colors"
              >
                <Plus className="w-5 h-5 rotate-45" />
              </button>
            </div>

            <div className="p-6 max-h-[400px] overflow-y-auto space-y-2">
              {studentsWithoutConversation.length > 0 ? (
                studentsWithoutConversation.map((student) => (
                  <button
                    key={student.id}
                    onClick={() => handleStartConversation(student.id)}
                    className={cn(
                      'w-full flex items-center gap-4 p-4 rounded-xl text-left',
                      'bg-surface-elevated border border-border',
                      'hover:border-accent/30 hover:shadow-md',
                      'transition-all duration-200'
                    )}
                  >
                    <Avatar name={student.name} size="md" />
                    <div>
                      <p className="font-semibold text-text-primary">{student.name}</p>
                      <p className="text-sm text-text-muted">{student.email}</p>
                    </div>
                  </button>
                ))
              ) : (
                <div className="text-center py-8">
                  <p className="text-text-muted">
                    Tous vos élèves ont déjà une conversation
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
