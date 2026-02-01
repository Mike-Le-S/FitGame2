import { create } from 'zustand'
import type { CalendarEvent } from '@/types'
import { generateId } from '@/lib/utils'
import { format, addDays } from 'date-fns'

interface EventsState {
  events: CalendarEvent[]
  addEvent: (event: Omit<CalendarEvent, 'id'>) => string
  updateEvent: (id: string, updates: Partial<CalendarEvent>) => void
  deleteEvent: (id: string) => void
  toggleComplete: (id: string) => void
  getEventsByDate: (date: string) => CalendarEvent[]
  getEventsByStudent: (studentId: string) => CalendarEvent[]
}

// Mock events
const mockEvents: CalendarEvent[] = [
  {
    id: 'event-1',
    studentId: 'student-1',
    title: 'Push A - Marie',
    type: 'workout',
    date: format(new Date(), 'yyyy-MM-dd'),
    time: '18:00',
    completed: false,
  },
  {
    id: 'event-2',
    studentId: 'student-2',
    title: 'Check-in Thomas',
    type: 'check-in',
    date: format(addDays(new Date(), 1), 'yyyy-MM-dd'),
    time: '10:00',
    completed: false,
  },
  {
    id: 'event-3',
    studentId: 'student-4',
    title: 'Pull A - Lucas',
    type: 'workout',
    date: format(addDays(new Date(), 2), 'yyyy-MM-dd'),
    time: '07:00',
    completed: false,
  },
  {
    id: 'event-4',
    studentId: 'student-1',
    title: 'Ajustement diète',
    type: 'nutrition',
    date: format(addDays(new Date(), 3), 'yyyy-MM-dd'),
    time: '14:00',
    completed: false,
  },
  {
    id: 'event-5',
    studentId: 'student-3',
    title: 'Legs - Sophie',
    type: 'workout',
    date: format(new Date(), 'yyyy-MM-dd'),
    time: '09:00',
    completed: true,
  },
]

export const useEventsStore = create<EventsState>((set, get) => ({
  events: mockEvents,

  addEvent: (eventData) => {
    const id = `event-${generateId()}`
    const newEvent: CalendarEvent = {
      ...eventData,
      id,
    }
    set((state) => ({ events: [...state.events, newEvent] }))
    return id
  },

  updateEvent: (id, updates) => {
    set((state) => ({
      events: state.events.map((e) =>
        e.id === id ? { ...e, ...updates } : e
      ),
    }))
  },

  deleteEvent: (id) => {
    set((state) => ({
      events: state.events.filter((e) => e.id !== id),
    }))
  },

  toggleComplete: (id) => {
    set((state) => ({
      events: state.events.map((e) =>
        e.id === id ? { ...e, completed: !e.completed } : e
      ),
    }))
  },

  getEventsByDate: (date) => {
    return get().events.filter((e) => e.date === date)
  },

  getEventsByStudent: (studentId) => {
    return get().events.filter((e) => e.studentId === studentId)
  },
}))
