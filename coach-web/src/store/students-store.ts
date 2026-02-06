import { create } from 'zustand'
import type { Student } from '@/types'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth-store'

export interface WorkoutSession {
  id: string
  userId: string
  programId?: string
  dayName: string
  startedAt: string
  completedAt?: string
  durationMinutes: number
  totalVolumeKg: number
  totalSets: number
  exercises: Array<{
    exerciseName: string
    muscleGroup?: string
    sets: Array<{
      weight: number
      reps: number
      isWarmup?: boolean
    }>
  }>
  personalRecords?: Array<{
    exerciseName: string
    type: string
    value: number
  }>
  notes?: string
}

interface StudentsState {
  students: Student[]
  isLoading: boolean
  error: string | null
  selectedStudentId: string | null
  studentSessions: Record<string, WorkoutSession[]>
  fetchStudents: () => Promise<void>
  setSelectedStudent: (id: string | null) => void
  getStudentById: (id: string) => Student | undefined
  addStudent: (student: Omit<Student, 'id' | 'currentStreak' | 'joinedAt' | 'stats'>) => Promise<string>
  updateStudent: (id: string, updates: Partial<Student>) => Promise<void>
  deleteStudent: (id: string) => Promise<void>
  assignProgram: (studentId: string, programId: string | undefined) => Promise<void>
  assignDiet: (studentId: string, dietId: string | undefined) => Promise<void>
  fetchStudentSessions: (studentId: string, limit?: number) => Promise<WorkoutSession[]>
}

// Transform database row to Student type
function dbToStudent(profile: any, assignments: any[], workoutSessions: any[]): Student {
  // Find active assignments for this student
  const programAssignment = assignments.find(a => a.student_id === profile.id && a.program_id)
  const dietAssignment = assignments.find(a => a.student_id === profile.id && a.diet_plan_id)

  // Calculate stats from workout sessions
  const studentSessions = workoutSessions.filter(s => s.user_id === profile.id)
  const now = new Date()
  const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
  const thisWeekSessions = studentSessions.filter(s => new Date(s.completed_at) >= weekAgo)

  const totalDuration = studentSessions.reduce((sum, s) => sum + (s.duration_minutes || 0), 0)
  const avgDuration = studentSessions.length > 0 ? Math.round(totalDuration / studentSessions.length) : 0

  return {
    id: profile.id,
    name: profile.full_name,
    email: profile.email,
    avatarUrl: profile.avatar_url || undefined,
    goal: profile.goal || 'maintain',
    assignedProgramId: programAssignment?.program_id || undefined,
    assignedDietId: dietAssignment?.diet_plan_id || undefined,
    currentStreak: profile.current_streak || 0,
    lastWorkout: studentSessions.length > 0
      ? studentSessions.sort((a, b) => new Date(b.completed_at).getTime() - new Date(a.completed_at).getTime())[0].completed_at
      : undefined,
    joinedAt: profile.created_at,
    stats: {
      totalWorkouts: profile.total_sessions || studentSessions.length,
      thisWeekWorkouts: thisWeekSessions.length,
      averageSessionDuration: avgDuration,
      complianceRate: Math.min(100, Math.round((thisWeekSessions.length / 4) * 100)),
    },
  }
}

export const useStudentsStore = create<StudentsState>((set, get) => ({
  students: [],
  isLoading: false,
  error: null,
  selectedStudentId: null,
  studentSessions: {},

  fetchStudents: async () => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    set({ isLoading: true, error: null })

    try {
      // Fetch students (athletes) assigned to this coach
      const { data: profiles, error: profilesError } = await supabase
        .from('profiles')
        .select('*')
        .eq('coach_id', coach.id)
        .eq('role', 'athlete')
        .order('full_name')

      if (profilesError) throw profilesError

      // Fetch assignments for these students
      const studentIds = (profiles || []).map(p => p.id)
      let assignments: any[] = []
      if (studentIds.length > 0) {
        const { data: assignmentsData, error: assignmentsError } = await supabase
          .from('assignments')
          .select('student_id, program_id, diet_plan_id')
          .eq('coach_id', coach.id)
          .in('student_id', studentIds)
          .eq('status', 'active')

        if (assignmentsError) throw assignmentsError
        assignments = assignmentsData || []
      }

      // Fetch recent workout sessions for stats
      let workoutSessions: any[] = []
      if (studentIds.length > 0) {
        const { data: sessionsData, error: sessionsError } = await supabase
          .from('workout_sessions')
          .select('user_id, completed_at, duration_minutes')
          .in('user_id', studentIds)
          .not('completed_at', 'is', null)
          .order('completed_at', { ascending: false })
          .limit(500)

        if (sessionsError) throw sessionsError
        workoutSessions = sessionsData || []
      }

      // Transform data
      const transformedStudents = (profiles || []).map(profile =>
        dbToStudent(profile, assignments, workoutSessions)
      )

      set({ students: transformedStudents, isLoading: false })
    } catch (error: any) {
      console.error('Error fetching students:', error)
      set({ error: error.message, isLoading: false })
    }
  },

  setSelectedStudent: (id) => set({ selectedStudentId: id }),

  getStudentById: (id) => get().students.find((s) => s.id === id),

  addStudent: async (studentData) => {
    const coach = useAuthStore.getState().coach
    if (!coach) throw new Error('Non authentifié')

    // Create a new user account for the student
    // Note: In production, you'd send an invite email instead
    const tempPassword = Math.random().toString(36).slice(-12)

    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: studentData.email,
      password: tempPassword,
      options: {
        data: {
          full_name: studentData.name,
          role: 'athlete',
        },
      },
    })

    if (authError) {
      if (authError.message.includes('already registered')) {
        throw new Error('Cet email est déjà utilisé')
      }
      throw authError
    }

    if (!authData.user) {
      throw new Error('Erreur lors de la création du compte')
    }

    // Create profile for the student
    const { error: profileError } = await supabase
      .from('profiles')
      .insert({
        id: authData.user.id,
        email: studentData.email,
        full_name: studentData.name,
        role: 'athlete',
        coach_id: coach.id,
      })

    if (profileError) {
      console.error('Profile creation error:', profileError)
    }

    // Create assignment if program or diet is specified
    if (studentData.assignedProgramId || studentData.assignedDietId) {
      await supabase.from('assignments').insert({
        coach_id: coach.id,
        student_id: authData.user.id,
        program_id: studentData.assignedProgramId || null,
        diet_plan_id: studentData.assignedDietId || null,
        status: 'active',
      })
    }

    const newStudent: Student = {
      id: authData.user.id,
      name: studentData.name,
      email: studentData.email,
      goal: studentData.goal,
      assignedProgramId: studentData.assignedProgramId,
      assignedDietId: studentData.assignedDietId,
      currentStreak: 0,
      joinedAt: new Date().toISOString(),
      stats: {
        totalWorkouts: 0,
        thisWeekWorkouts: 0,
        averageSessionDuration: 0,
        complianceRate: 0,
      },
    }

    set((state) => ({ students: [...state.students, newStudent] }))
    return authData.user.id
  },

  updateStudent: async (id, updates) => {
    const dbUpdates: any = {}
    if (updates.name !== undefined) dbUpdates.full_name = updates.name
    if (updates.email !== undefined) dbUpdates.email = updates.email
    if (updates.avatarUrl !== undefined) dbUpdates.avatar_url = updates.avatarUrl

    if (Object.keys(dbUpdates).length > 0) {
      const { error } = await supabase
        .from('profiles')
        .update(dbUpdates)
        .eq('id', id)

      if (error) throw error
    }

    set((state) => ({
      students: state.students.map((s) =>
        s.id === id ? { ...s, ...updates } : s
      ),
    }))
  },

  deleteStudent: async (id) => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    // Remove coach assignment (don't delete the profile, just unlink)
    const { error } = await supabase
      .from('profiles')
      .update({ coach_id: null })
      .eq('id', id)

    if (error) throw error

    // Deactivate all assignments
    await supabase
      .from('assignments')
      .update({ status: 'paused' })
      .eq('coach_id', coach.id)
      .eq('student_id', id)

    set((state) => ({
      students: state.students.filter((s) => s.id !== id),
    }))
  },

  assignProgram: async (studentId, programId) => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    if (programId) {
      // Check if assignment exists
      const { data: existing } = await supabase
        .from('assignments')
        .select('id')
        .eq('coach_id', coach.id)
        .eq('student_id', studentId)
        .single()

      if (existing) {
        await supabase
          .from('assignments')
          .update({ program_id: programId, status: 'active' })
          .eq('id', existing.id)
      } else {
        await supabase.from('assignments').insert({
          coach_id: coach.id,
          student_id: studentId,
          program_id: programId,
          status: 'active',
        })
      }
    } else {
      // Remove program assignment
      await supabase
        .from('assignments')
        .update({ program_id: null })
        .eq('coach_id', coach.id)
        .eq('student_id', studentId)
    }

    set((state) => ({
      students: state.students.map((s) =>
        s.id === studentId ? { ...s, assignedProgramId: programId } : s
      ),
    }))
  },

  assignDiet: async (studentId, dietId) => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    if (dietId) {
      // Check if assignment exists
      const { data: existing } = await supabase
        .from('assignments')
        .select('id')
        .eq('coach_id', coach.id)
        .eq('student_id', studentId)
        .single()

      if (existing) {
        await supabase
          .from('assignments')
          .update({ diet_plan_id: dietId, status: 'active' })
          .eq('id', existing.id)
      } else {
        await supabase.from('assignments').insert({
          coach_id: coach.id,
          student_id: studentId,
          diet_plan_id: dietId,
          status: 'active',
        })
      }
    } else {
      // Remove diet assignment
      await supabase
        .from('assignments')
        .update({ diet_plan_id: null })
        .eq('coach_id', coach.id)
        .eq('student_id', studentId)
    }

    set((state) => ({
      students: state.students.map((s) =>
        s.id === studentId ? { ...s, assignedDietId: dietId } : s
      ),
    }))
  },

  fetchStudentSessions: async (studentId, limit = 20) => {
    try {
      const { data, error } = await supabase
        .from('workout_sessions')
        .select('*')
        .eq('user_id', studentId)
        .not('completed_at', 'is', null)
        .order('completed_at', { ascending: false })
        .limit(limit)

      if (error) throw error

      const sessions: WorkoutSession[] = (data || []).map((row: any) => ({
        id: row.id,
        userId: row.user_id,
        programId: row.program_id,
        dayName: row.day_name,
        startedAt: row.started_at,
        completedAt: row.completed_at,
        durationMinutes: row.duration_minutes || 0,
        totalVolumeKg: row.total_volume_kg || 0,
        totalSets: row.total_sets || 0,
        exercises: row.exercises || [],
        personalRecords: row.personal_records || [],
        notes: row.notes,
      }))

      set((state) => ({
        studentSessions: {
          ...state.studentSessions,
          [studentId]: sessions,
        },
      }))

      return sessions
    } catch (error: any) {
      console.error('Error fetching student sessions:', error)
      return []
    }
  },
}))
