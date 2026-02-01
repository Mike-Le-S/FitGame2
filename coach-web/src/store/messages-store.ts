import { create } from 'zustand'
import type { Conversation, Message } from '@/types'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth-store'
import { useSettingsStore } from './settings-store'
import { useStudentsStore } from './students-store'
import { notificationService } from '@/lib/notifications'
import type { RealtimeChannel } from '@supabase/supabase-js'

interface MessagesState {
  conversations: (Conversation & { messages: Message[] })[]
  isLoading: boolean
  error: string | null
  realtimeChannel: RealtimeChannel | null
  fetchMessages: () => Promise<void>
  sendMessage: (studentId: string, content: string) => Promise<void>
  markAsRead: (studentId: string) => Promise<void>
  getConversationByStudentId: (studentId: string) => (Conversation & { messages: Message[] }) | undefined
  subscribeToRealtime: () => void
  unsubscribeFromRealtime: () => void
  getTotalUnread: () => number
}

// Transform database messages to grouped conversations
function groupMessagesByStudent(
  messages: any[],
  coachId: string
): (Conversation & { messages: Message[] })[] {
  const conversationMap = new Map<string, Message[]>()

  // Group messages by the other participant (student)
  for (const msg of messages) {
    const studentId = msg.sender_id === coachId ? msg.receiver_id : msg.sender_id
    const existing = conversationMap.get(studentId) || []
    existing.push({
      id: msg.id,
      conversationId: studentId, // Use studentId as conversationId
      senderId: msg.sender_id,
      content: msg.content,
      sentAt: msg.created_at,
      readAt: msg.read_at || undefined,
    })
    conversationMap.set(studentId, existing)
  }

  // Convert to conversations array
  const conversations: (Conversation & { messages: Message[] })[] = []

  for (const [studentId, msgs] of conversationMap.entries()) {
    // Sort messages by date (oldest first)
    msgs.sort((a, b) => new Date(a.sentAt).getTime() - new Date(b.sentAt).getTime())

    // Count unread (messages from student that coach hasn't read)
    const unreadCount = msgs.filter(
      (m) => m.senderId === studentId && !m.readAt
    ).length

    // Get last message
    const lastMessage = msgs[msgs.length - 1]

    conversations.push({
      id: studentId, // Use studentId as conversation id
      studentId,
      messages: msgs,
      unreadCount,
      lastMessage,
      updatedAt: lastMessage?.sentAt || new Date().toISOString(),
    })
  }

  // Sort by most recent
  conversations.sort(
    (a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()
  )

  return conversations
}

export const useMessagesStore = create<MessagesState>((set, get) => ({
  conversations: [],
  isLoading: false,
  error: null,
  realtimeChannel: null,

  fetchMessages: async () => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    set({ isLoading: true, error: null })

    try {
      // Fetch all messages where coach is sender or receiver
      const { data, error } = await supabase
        .from('messages')
        .select('*')
        .or(`sender_id.eq.${coach.id},receiver_id.eq.${coach.id}`)
        .order('created_at', { ascending: false })
        .limit(500)

      if (error) throw error

      const conversations = groupMessagesByStudent(data || [], coach.id)
      set({ conversations, isLoading: false })
    } catch (error: any) {
      console.error('Error fetching messages:', error)
      set({ error: error.message, isLoading: false })
    }
  },

  sendMessage: async (studentId, content) => {
    const coach = useAuthStore.getState().coach
    if (!coach) throw new Error('Non authentifié')

    try {
      const { data, error } = await supabase
        .from('messages')
        .insert({
          sender_id: coach.id,
          receiver_id: studentId,
          content,
        })
        .select()
        .single()

      if (error) throw error

      // Optimistic update - add message to local state
      const newMessage: Message = {
        id: data.id,
        conversationId: studentId,
        senderId: coach.id,
        content,
        sentAt: data.created_at,
      }

      set((state) => {
        const existingConv = state.conversations.find((c) => c.studentId === studentId)

        if (existingConv) {
          return {
            conversations: state.conversations.map((conv) =>
              conv.studentId === studentId
                ? {
                    ...conv,
                    messages: [...conv.messages, newMessage],
                    lastMessage: newMessage,
                    updatedAt: newMessage.sentAt,
                  }
                : conv
            ),
          }
        } else {
          // Create new conversation
          return {
            conversations: [
              {
                id: studentId,
                studentId,
                messages: [newMessage],
                unreadCount: 0,
                lastMessage: newMessage,
                updatedAt: newMessage.sentAt,
              },
              ...state.conversations,
            ],
          }
        }
      })
    } catch (error: any) {
      console.error('Error sending message:', error)
      throw error
    }
  },

  markAsRead: async (studentId) => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    try {
      // Mark all unread messages from this student as read
      const { error } = await supabase
        .from('messages')
        .update({ read_at: new Date().toISOString() })
        .eq('sender_id', studentId)
        .eq('receiver_id', coach.id)
        .is('read_at', null)

      if (error) throw error

      // Update local state
      set((state) => ({
        conversations: state.conversations.map((conv) =>
          conv.studentId === studentId
            ? {
                ...conv,
                unreadCount: 0,
                messages: conv.messages.map((msg) =>
                  msg.senderId === studentId && !msg.readAt
                    ? { ...msg, readAt: new Date().toISOString() }
                    : msg
                ),
              }
            : conv
        ),
      }))
    } catch (error: any) {
      console.error('Error marking messages as read:', error)
    }
  },

  getConversationByStudentId: (studentId) => {
    return get().conversations.find((c) => c.studentId === studentId)
  },

  subscribeToRealtime: () => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    // Unsubscribe from any existing channel
    get().unsubscribeFromRealtime()

    const channel = supabase
      .channel('messages-realtime')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `receiver_id=eq.${coach.id}`,
        },
        (payload) => {
          // New message received
          const msg = payload.new as any
          const newMessage: Message = {
            id: msg.id,
            conversationId: msg.sender_id,
            senderId: msg.sender_id,
            content: msg.content,
            sentAt: msg.created_at,
          }

          set((state) => {
            const existingConv = state.conversations.find(
              (c) => c.studentId === msg.sender_id
            )

            if (existingConv) {
              return {
                conversations: state.conversations.map((conv) =>
                  conv.studentId === msg.sender_id
                    ? {
                        ...conv,
                        messages: [...conv.messages, newMessage],
                        lastMessage: newMessage,
                        unreadCount: conv.unreadCount + 1,
                        updatedAt: newMessage.sentAt,
                      }
                    : conv
                ),
              }
            } else {
              // New conversation
              return {
                conversations: [
                  {
                    id: msg.sender_id,
                    studentId: msg.sender_id,
                    messages: [newMessage],
                    unreadCount: 1,
                    lastMessage: newMessage,
                    updatedAt: newMessage.sentAt,
                  },
                  ...state.conversations,
                ],
              }
            }
          })

          // Show browser notification if enabled
          const { notifications } = useSettingsStore.getState()
          if (notifications.messages) {
            const students = useStudentsStore.getState().students
            const sender = students.find((s) => s.id === msg.sender_id)
            const senderName = sender?.name || 'Un élève'
            notificationService.showMessageNotification(senderName, msg.content)
          }
        }
      )
      .subscribe()

    set({ realtimeChannel: channel })
  },

  unsubscribeFromRealtime: () => {
    const channel = get().realtimeChannel
    if (channel) {
      supabase.removeChannel(channel)
      set({ realtimeChannel: null })
    }
  },

  getTotalUnread: () => {
    return get().conversations.reduce((acc, c) => acc + c.unreadCount, 0)
  },
}))
