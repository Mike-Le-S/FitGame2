import { create } from 'zustand'
import type { CalendarEvent } from '@/types'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth-store'

interface EventsState {
  events: CalendarEvent[]
  isLoading: boolean
  error: string | null
  fetchEvents: () => Promise<void>
  addEvent: (event: Omit<CalendarEvent, 'id' | 'coachId'>) => Promise<string>
  updateEvent: (id: string, updates: Partial<CalendarEvent>) => Promise<void>
  deleteEvent: (id: string) => Promise<void>
  toggleComplete: (id: string) => Promise<void>
  getEventsByDate: (date: string) => CalendarEvent[]
  getEventsByStudent: (studentId: string) => CalendarEvent[]
}

// Transform DB row (snake_case) to CalendarEvent (camelCase)
function dbToEvent(row: any): CalendarEvent {
  return {
    id: row.id,
    coachId: row.coach_id,
    studentId: row.student_id || undefined,
    title: row.title,
    description: row.description || undefined,
    type: row.type,
    date: row.date,
    time: row.time || undefined,
    durationMinutes: row.duration_minutes || undefined,
    completed: row.completed,
    recurring: row.recurring || undefined,
    recurrenceRule: row.recurrence_rule || undefined,
  }
}

// Transform CalendarEvent fields (camelCase) to DB columns (snake_case)
function eventToDb(event: Partial<CalendarEvent>): Record<string, any> {
  const db: Record<string, any> = {}
  if (event.coachId !== undefined) db.coach_id = event.coachId
  if (event.studentId !== undefined) db.student_id = event.studentId || null
  if (event.title !== undefined) db.title = event.title
  if (event.description !== undefined) db.description = event.description || null
  if (event.type !== undefined) db.type = event.type
  if (event.date !== undefined) db.date = event.date
  if (event.time !== undefined) db.time = event.time || null
  if (event.durationMinutes !== undefined) db.duration_minutes = event.durationMinutes || null
  if (event.completed !== undefined) db.completed = event.completed
  if (event.recurring !== undefined) db.recurring = event.recurring || false
  if (event.recurrenceRule !== undefined) db.recurrence_rule = event.recurrenceRule || null
  return db
}

export const useEventsStore = create<EventsState>((set, get) => ({
  events: [],
  isLoading: false,
  error: null,

  fetchEvents: async () => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    set({ isLoading: true, error: null })

    try {
      const { data, error } = await supabase
        .from('calendar_events')
        .select('*')
        .eq('coach_id', coach.id)
        .order('date')

      if (error) throw error

      const events = (data || []).map(dbToEvent)
      set({ events, isLoading: false })
    } catch (error: any) {
      console.error('Error fetching events:', error)
      set({ error: error.message, isLoading: false })
    }
  },

  addEvent: async (eventData) => {
    const coach = useAuthStore.getState().coach
    if (!coach) throw new Error('Non authentifié')

    try {
      const dbData = eventToDb({ ...eventData, coachId: coach.id })

      const { data, error } = await supabase
        .from('calendar_events')
        .insert(dbData)
        .select()
        .single()

      if (error) throw error

      const newEvent = dbToEvent(data)
      set((state) => ({ events: [...state.events, newEvent] }))
      return newEvent.id
    } catch (error: any) {
      console.error('Error adding event:', error)
      throw error
    }
  },

  updateEvent: async (id, updates) => {
    try {
      const dbUpdates = eventToDb(updates)

      const { data, error } = await supabase
        .from('calendar_events')
        .update(dbUpdates)
        .eq('id', id)
        .select()
        .single()

      if (error) throw error

      const updatedEvent = dbToEvent(data)
      set((state) => ({
        events: state.events.map((e) =>
          e.id === id ? updatedEvent : e
        ),
      }))
    } catch (error: any) {
      console.error('Error updating event:', error)
      throw error
    }
  },

  deleteEvent: async (id) => {
    try {
      const { error } = await supabase
        .from('calendar_events')
        .delete()
        .eq('id', id)

      if (error) throw error

      set((state) => ({
        events: state.events.filter((e) => e.id !== id),
      }))
    } catch (error: any) {
      console.error('Error deleting event:', error)
      throw error
    }
  },

  toggleComplete: async (id) => {
    const event = get().events.find((e) => e.id === id)
    if (!event) return

    const newCompleted = !event.completed

    try {
      const { error } = await supabase
        .from('calendar_events')
        .update({ completed: newCompleted })
        .eq('id', id)

      if (error) throw error

      set((state) => ({
        events: state.events.map((e) =>
          e.id === id ? { ...e, completed: newCompleted } : e
        ),
      }))
    } catch (error: any) {
      console.error('Error toggling event:', error)
      throw error
    }
  },

  getEventsByDate: (date) => {
    return get().events.filter((e) => e.date === date)
  },

  getEventsByStudent: (studentId) => {
    return get().events.filter((e) => e.studentId === studentId)
  },
}))
