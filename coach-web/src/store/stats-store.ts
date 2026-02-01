import { create } from 'zustand'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth-store'

export interface DashboardStats {
  // Students
  totalStudents: number
  activeStudents: number // Had workout in last 7 days
  newStudentsThisMonth: number

  // Workouts
  totalSessionsThisWeek: number
  totalSessionsLastWeek: number
  sessionsGrowthPercent: number
  totalVolumeThisWeek: number // kg

  // Programs
  totalPrograms: number
  mostUsedProgram?: {
    id: string
    name: string
    studentCount: number
  }

  // Compliance
  averageCompliance: number
  studentsAtRisk: number // < 2 workouts this week
}

export interface StudentActivity {
  studentId: string
  studentName: string
  lastWorkout: string
  streak: number
}

export interface WeeklyTrend {
  week: string // ISO week start date
  sessions: number
  volume: number
}

interface StatsState {
  dashboardStats: DashboardStats | null
  recentActivity: StudentActivity[]
  weeklyTrends: WeeklyTrend[]
  isLoading: boolean
  error: string | null
  lastFetched: Date | null

  fetchDashboardStats: () => Promise<void>
  fetchRecentActivity: (limit?: number) => Promise<void>
  fetchWeeklyTrends: (weeks?: number) => Promise<void>
  refreshAll: () => Promise<void>
}

export const useStatsStore = create<StatsState>((set, get) => ({
  dashboardStats: null,
  recentActivity: [],
  weeklyTrends: [],
  isLoading: false,
  error: null,
  lastFetched: null,

  fetchDashboardStats: async () => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    set({ isLoading: true, error: null })

    try {
      const now = new Date()
      const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
      const twoWeeksAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000)
      const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)

      // Fetch all students of this coach
      const { data: students, error: studentsError } = await supabase
        .from('profiles')
        .select('id, full_name, created_at, current_streak')
        .eq('coach_id', coach.id)
        .eq('role', 'athlete')

      if (studentsError) throw studentsError

      const studentIds = students?.map(s => s.id) || []

      if (studentIds.length === 0) {
        set({
          dashboardStats: {
            totalStudents: 0,
            activeStudents: 0,
            newStudentsThisMonth: 0,
            totalSessionsThisWeek: 0,
            totalSessionsLastWeek: 0,
            sessionsGrowthPercent: 0,
            totalVolumeThisWeek: 0,
            totalPrograms: 0,
            averageCompliance: 0,
            studentsAtRisk: 0,
          },
          isLoading: false,
          lastFetched: new Date(),
        })
        return
      }

      // Fetch workout sessions for this week
      const { data: thisWeekSessions, error: thisWeekError } = await supabase
        .from('workout_sessions')
        .select('id, user_id, completed_at, duration_minutes, exercises')
        .in('user_id', studentIds)
        .gte('completed_at', weekAgo.toISOString())
        .not('completed_at', 'is', null)

      if (thisWeekError) throw thisWeekError

      // Fetch workout sessions for last week
      const { data: lastWeekSessions, error: lastWeekError } = await supabase
        .from('workout_sessions')
        .select('id, user_id')
        .in('user_id', studentIds)
        .gte('completed_at', twoWeeksAgo.toISOString())
        .lt('completed_at', weekAgo.toISOString())
        .not('completed_at', 'is', null)

      if (lastWeekError) throw lastWeekError

      // Fetch programs
      const { data: programs, error: programsError } = await supabase
        .from('programs')
        .select('id, name')
        .eq('created_by', coach.id)

      if (programsError) throw programsError

      // Fetch assignments to count program usage
      const { data: assignments, error: assignmentsError } = await supabase
        .from('assignments')
        .select('program_id, student_id')
        .eq('coach_id', coach.id)
        .eq('status', 'active')
        .not('program_id', 'is', null)

      if (assignmentsError) throw assignmentsError

      // Calculate stats
      const totalStudents = students?.length || 0
      const newStudentsThisMonth = students?.filter(
        s => new Date(s.created_at) >= monthAgo
      ).length || 0

      // Active students (had at least 1 workout this week)
      const activeStudentIds = new Set(thisWeekSessions?.map(s => s.user_id) || [])
      const activeStudents = activeStudentIds.size

      // Sessions count
      const totalSessionsThisWeek = thisWeekSessions?.length || 0
      const totalSessionsLastWeek = lastWeekSessions?.length || 0

      // Growth percentage
      const sessionsGrowthPercent = totalSessionsLastWeek > 0
        ? Math.round(((totalSessionsThisWeek - totalSessionsLastWeek) / totalSessionsLastWeek) * 100)
        : totalSessionsThisWeek > 0 ? 100 : 0

      // Total volume this week (sum of all sets * weight * reps)
      let totalVolumeThisWeek = 0
      for (const session of thisWeekSessions || []) {
        const exercises = session.exercises as any[]
        if (exercises) {
          for (const ex of exercises) {
            for (const set of ex.sets || []) {
              if (!set.isWarmup) {
                totalVolumeThisWeek += (set.weight || 0) * (set.reps || 0)
              }
            }
          }
        }
      }

      // Most used program
      const programUsage: Record<string, number> = {}
      for (const assignment of assignments || []) {
        if (assignment.program_id) {
          programUsage[assignment.program_id] = (programUsage[assignment.program_id] || 0) + 1
        }
      }

      let mostUsedProgram: DashboardStats['mostUsedProgram'] | undefined
      if (Object.keys(programUsage).length > 0) {
        const topProgramId = Object.entries(programUsage)
          .sort(([,a], [,b]) => b - a)[0][0]
        const program = programs?.find(p => p.id === topProgramId)
        if (program) {
          mostUsedProgram = {
            id: program.id,
            name: program.name,
            studentCount: programUsage[topProgramId],
          }
        }
      }

      // Students at risk (< 2 workouts this week)
      const workoutsPerStudent: Record<string, number> = {}
      for (const session of thisWeekSessions || []) {
        workoutsPerStudent[session.user_id] = (workoutsPerStudent[session.user_id] || 0) + 1
      }
      const studentsAtRisk = studentIds.filter(
        id => (workoutsPerStudent[id] || 0) < 2
      ).length

      // Average compliance (percentage of students with >= 3 workouts this week)
      const compliantStudents = studentIds.filter(
        id => (workoutsPerStudent[id] || 0) >= 3
      ).length
      const averageCompliance = totalStudents > 0
        ? Math.round((compliantStudents / totalStudents) * 100)
        : 0

      set({
        dashboardStats: {
          totalStudents,
          activeStudents,
          newStudentsThisMonth,
          totalSessionsThisWeek,
          totalSessionsLastWeek,
          sessionsGrowthPercent,
          totalVolumeThisWeek: Math.round(totalVolumeThisWeek),
          totalPrograms: programs?.length || 0,
          mostUsedProgram,
          averageCompliance,
          studentsAtRisk,
        },
        isLoading: false,
        lastFetched: new Date(),
      })
    } catch (error: any) {
      console.error('Error fetching dashboard stats:', error)
      set({ error: error.message, isLoading: false })
    }
  },

  fetchRecentActivity: async (limit = 10) => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    try {
      // Fetch recent workout sessions with student info
      const { data: students, error: studentsError } = await supabase
        .from('profiles')
        .select('id, full_name, current_streak')
        .eq('coach_id', coach.id)
        .eq('role', 'athlete')

      if (studentsError) throw studentsError

      const studentIds = students?.map(s => s.id) || []
      if (studentIds.length === 0) {
        set({ recentActivity: [] })
        return
      }

      const { data: sessions, error: sessionsError } = await supabase
        .from('workout_sessions')
        .select('user_id, completed_at')
        .in('user_id', studentIds)
        .not('completed_at', 'is', null)
        .order('completed_at', { ascending: false })
        .limit(limit)

      if (sessionsError) throw sessionsError

      const studentMap = new Map(students?.map(s => [s.id, s]) || [])
      const activity: StudentActivity[] = []
      const seenStudents = new Set<string>()

      for (const session of sessions || []) {
        if (seenStudents.has(session.user_id)) continue
        seenStudents.add(session.user_id)

        const student = studentMap.get(session.user_id)
        if (student) {
          activity.push({
            studentId: student.id,
            studentName: student.full_name,
            lastWorkout: session.completed_at,
            streak: student.current_streak || 0,
          })
        }
      }

      set({ recentActivity: activity })
    } catch (error: any) {
      console.error('Error fetching recent activity:', error)
    }
  },

  fetchWeeklyTrends: async (weeks = 8) => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    try {
      const { data: students, error: studentsError } = await supabase
        .from('profiles')
        .select('id')
        .eq('coach_id', coach.id)
        .eq('role', 'athlete')

      if (studentsError) throw studentsError

      const studentIds = students?.map(s => s.id) || []
      if (studentIds.length === 0) {
        set({ weeklyTrends: [] })
        return
      }

      const startDate = new Date()
      startDate.setDate(startDate.getDate() - (weeks * 7))

      const { data: sessions, error: sessionsError } = await supabase
        .from('workout_sessions')
        .select('completed_at, exercises')
        .in('user_id', studentIds)
        .gte('completed_at', startDate.toISOString())
        .not('completed_at', 'is', null)
        .order('completed_at', { ascending: true })

      if (sessionsError) throw sessionsError

      // Group by week
      const weekData: Record<string, { sessions: number; volume: number }> = {}

      for (const session of sessions || []) {
        const date = new Date(session.completed_at)
        // Get Monday of the week
        const day = date.getDay()
        const diff = date.getDate() - day + (day === 0 ? -6 : 1)
        const monday = new Date(date.setDate(diff))
        const weekKey = monday.toISOString().split('T')[0]

        if (!weekData[weekKey]) {
          weekData[weekKey] = { sessions: 0, volume: 0 }
        }

        weekData[weekKey].sessions++

        // Calculate volume
        const exercises = session.exercises as any[]
        if (exercises) {
          for (const ex of exercises) {
            for (const set of ex.sets || []) {
              if (!set.isWarmup) {
                weekData[weekKey].volume += (set.weight || 0) * (set.reps || 0)
              }
            }
          }
        }
      }

      const trends: WeeklyTrend[] = Object.entries(weekData)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([week, data]) => ({
          week,
          sessions: data.sessions,
          volume: Math.round(data.volume),
        }))

      set({ weeklyTrends: trends })
    } catch (error: any) {
      console.error('Error fetching weekly trends:', error)
    }
  },

  refreshAll: async () => {
    const { fetchDashboardStats, fetchRecentActivity, fetchWeeklyTrends } = get()
    await Promise.all([
      fetchDashboardStats(),
      fetchRecentActivity(),
      fetchWeeklyTrends(),
    ])
  },
}))
