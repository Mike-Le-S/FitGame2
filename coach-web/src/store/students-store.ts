import { create } from 'zustand'
import type { Student } from '@/types'

interface StudentsState {
  students: Student[]
  selectedStudentId: string | null
  setSelectedStudent: (id: string | null) => void
  getStudentById: (id: string) => Student | undefined
}

// Mock students data
const mockStudents: Student[] = [
  {
    id: 'student-1',
    name: 'Marie Laurent',
    email: 'marie@email.com',
    goal: 'cut',
    assignedProgramId: 'program-1',
    assignedDietId: 'diet-1',
    currentStreak: 12,
    lastWorkout: new Date(Date.now() - 86400000).toISOString(),
    joinedAt: '2025-06-15T00:00:00Z',
    stats: {
      totalWorkouts: 48,
      thisWeekWorkouts: 4,
      averageSessionDuration: 55,
      complianceRate: 92,
    },
  },
  {
    id: 'student-2',
    name: 'Thomas Bernard',
    email: 'thomas@email.com',
    goal: 'bulk',
    assignedProgramId: 'program-2',
    assignedDietId: 'diet-2',
    currentStreak: 28,
    lastWorkout: new Date(Date.now() - 172800000).toISOString(),
    joinedAt: '2025-03-20T00:00:00Z',
    stats: {
      totalWorkouts: 156,
      thisWeekWorkouts: 5,
      averageSessionDuration: 72,
      complianceRate: 98,
    },
  },
  {
    id: 'student-3',
    name: 'Sophie Martin',
    email: 'sophie@email.com',
    goal: 'maintain',
    assignedProgramId: 'program-1',
    currentStreak: 5,
    lastWorkout: new Date(Date.now() - 259200000).toISOString(),
    joinedAt: '2025-10-01T00:00:00Z',
    stats: {
      totalWorkouts: 22,
      thisWeekWorkouts: 2,
      averageSessionDuration: 45,
      complianceRate: 78,
    },
  },
  {
    id: 'student-4',
    name: 'Lucas Petit',
    email: 'lucas@email.com',
    goal: 'bulk',
    assignedProgramId: 'program-3',
    assignedDietId: 'diet-3',
    currentStreak: 45,
    lastWorkout: new Date().toISOString(),
    joinedAt: '2024-11-12T00:00:00Z',
    stats: {
      totalWorkouts: 234,
      thisWeekWorkouts: 6,
      averageSessionDuration: 68,
      complianceRate: 95,
    },
  },
  {
    id: 'student-5',
    name: 'Emma Dubois',
    email: 'emma@email.com',
    goal: 'cut',
    currentStreak: 0,
    lastWorkout: new Date(Date.now() - 604800000).toISOString(),
    joinedAt: '2025-12-01T00:00:00Z',
    stats: {
      totalWorkouts: 8,
      thisWeekWorkouts: 0,
      averageSessionDuration: 40,
      complianceRate: 45,
    },
  },
]

export const useStudentsStore = create<StudentsState>((set, get) => ({
  students: mockStudents,
  selectedStudentId: null,

  setSelectedStudent: (id) => set({ selectedStudentId: id }),

  getStudentById: (id) => get().students.find((s) => s.id === id),
}))
