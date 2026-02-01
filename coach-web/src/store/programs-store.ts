import { create } from 'zustand'
import type { Program, Exercise, WorkoutSet, MuscleGroup, ExerciseMode } from '@/types'
import { generateId } from '@/lib/utils'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth-store'

interface ProgramsState {
  programs: Program[]
  isLoading: boolean
  error: string | null
  fetchPrograms: () => Promise<void>
  addProgram: (program: Omit<Program, 'id' | 'createdAt' | 'updatedAt' | 'assignedStudentIds'>) => Promise<string>
  updateProgram: (id: string, updates: Partial<Program>) => Promise<void>
  deleteProgram: (id: string) => Promise<void>
  duplicateProgram: (id: string) => Promise<string | null>
  getProgramById: (id: string) => Program | undefined
  assignToStudent: (programId: string, studentId: string) => Promise<void>
  unassignFromStudent: (programId: string, studentId: string) => Promise<void>
}

// Exercise catalog for program creation
export const exerciseCatalog: Record<MuscleGroup, { id: string; name: string }[]> = {
  chest: [
    { id: 'bench-press', name: 'Développé couché' },
    { id: 'incline-bench', name: 'Développé incliné' },
    { id: 'decline-bench', name: 'Développé décliné' },
    { id: 'dumbbell-fly', name: 'Écarté haltères' },
    { id: 'cable-crossover', name: 'Cable crossover' },
    { id: 'dips-chest', name: 'Dips pectoraux' },
  ],
  back: [
    { id: 'deadlift', name: 'Soulevé de terre' },
    { id: 'barbell-row', name: 'Rowing barre' },
    { id: 'pull-up', name: 'Tractions' },
    { id: 'lat-pulldown', name: 'Tirage vertical' },
    { id: 'seated-row', name: 'Tirage horizontal' },
    { id: 'tbar-row', name: 'T-bar row' },
  ],
  shoulders: [
    { id: 'military-press', name: 'Développé militaire' },
    { id: 'lateral-raise', name: 'Élévations latérales' },
    { id: 'front-raise', name: 'Élévations frontales' },
    { id: 'rear-delt-fly', name: 'Oiseau' },
    { id: 'arnold-press', name: 'Arnold press' },
    { id: 'face-pull', name: 'Face pull' },
  ],
  biceps: [
    { id: 'barbell-curl', name: 'Curl barre' },
    { id: 'dumbbell-curl', name: 'Curl haltères' },
    { id: 'hammer-curl', name: 'Curl marteau' },
    { id: 'preacher-curl', name: 'Curl pupitre' },
    { id: 'concentration-curl', name: 'Curl concentration' },
  ],
  triceps: [
    { id: 'close-grip-bench', name: 'Développé serré' },
    { id: 'tricep-pushdown', name: 'Pushdown triceps' },
    { id: 'skull-crusher', name: 'Skull crusher' },
    { id: 'dips-triceps', name: 'Dips triceps' },
    { id: 'overhead-extension', name: 'Extension verticale' },
  ],
  forearms: [
    { id: 'wrist-curl', name: 'Curl poignets' },
    { id: 'reverse-curl', name: 'Curl inversé' },
    { id: 'farmer-walk', name: 'Farmer walk' },
  ],
  quads: [
    { id: 'squat', name: 'Squat' },
    { id: 'front-squat', name: 'Front squat' },
    { id: 'leg-press', name: 'Presse à cuisses' },
    { id: 'leg-extension', name: 'Leg extension' },
    { id: 'lunges', name: 'Fentes' },
    { id: 'hack-squat', name: 'Hack squat' },
  ],
  hamstrings: [
    { id: 'romanian-deadlift', name: 'Soulevé de terre roumain' },
    { id: 'leg-curl', name: 'Leg curl' },
    { id: 'good-morning', name: 'Good morning' },
    { id: 'nordic-curl', name: 'Nordic curl' },
  ],
  glutes: [
    { id: 'hip-thrust', name: 'Hip thrust' },
    { id: 'glute-bridge', name: 'Pont fessier' },
    { id: 'cable-kickback', name: 'Kickback câble' },
    { id: 'sumo-deadlift', name: 'Soulevé sumo' },
  ],
  calves: [
    { id: 'standing-calf-raise', name: 'Mollets debout' },
    { id: 'seated-calf-raise', name: 'Mollets assis' },
    { id: 'donkey-calf-raise', name: 'Donkey raise' },
  ],
  abs: [
    { id: 'crunch', name: 'Crunch' },
    { id: 'leg-raise', name: 'Relevé de jambes' },
    { id: 'plank', name: 'Planche' },
    { id: 'cable-crunch', name: 'Crunch câble' },
    { id: 'ab-wheel', name: 'Roue abdominale' },
  ],
  cardio: [
    { id: 'treadmill', name: 'Tapis de course' },
    { id: 'bike', name: 'Vélo' },
    { id: 'rowing', name: 'Rameur' },
    { id: 'stairmaster', name: 'Stairmaster' },
    { id: 'hiit', name: 'HIIT' },
  ],
}

// Helper to create default sets
export function createDefaultSets(mode: ExerciseMode, count: number = 3): WorkoutSet[] {
  return Array.from({ length: count }, (_, i) => ({
    id: generateId(),
    targetReps: mode === 'rpt' ? 6 + i * 2 : 10,
    targetWeight: 0,
    isWarmup: false,
    restSeconds: mode === 'rpt' ? 180 : 90,
  }))
}

// Helper to create an exercise
export function createExercise(
  name: string,
  muscle: MuscleGroup,
  mode: ExerciseMode = 'classic'
): Exercise {
  return {
    id: generateId(),
    name,
    muscle,
    mode,
    sets: createDefaultSets(mode),
  }
}

// Transform database row to Program type
function dbToProgram(row: any): Program {
  return {
    id: row.id,
    name: row.name,
    description: row.description || undefined,
    goal: row.goal,
    durationWeeks: row.duration_weeks,
    deloadFrequency: row.deload_frequency || undefined,
    days: row.days || [],
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    assignedStudentIds: [], // Will be populated from assignments table
  }
}

// Transform Program to database row
function programToDb(program: Omit<Program, 'id' | 'createdAt' | 'updatedAt' | 'assignedStudentIds'>, createdBy: string) {
  return {
    created_by: createdBy,
    name: program.name,
    description: program.description || null,
    goal: program.goal,
    duration_weeks: program.durationWeeks,
    deload_frequency: program.deloadFrequency || null,
    days: program.days,
  }
}

export const useProgramsStore = create<ProgramsState>((set, get) => ({
  programs: [],
  isLoading: false,
  error: null,

  fetchPrograms: async () => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    set({ isLoading: true, error: null })

    try {
      // Fetch programs created by this coach
      const { data: programs, error: programsError } = await supabase
        .from('programs')
        .select('*')
        .eq('created_by', coach.id)
        .order('created_at', { ascending: false })

      if (programsError) throw programsError

      // Fetch assignments to get assigned students
      const { data: assignments, error: assignmentsError } = await supabase
        .from('assignments')
        .select('program_id, student_id')
        .eq('coach_id', coach.id)
        .not('program_id', 'is', null)
        .eq('status', 'active')

      if (assignmentsError) throw assignmentsError

      // Transform and merge data
      const transformedPrograms = (programs || []).map(row => {
        const program = dbToProgram(row)
        program.assignedStudentIds = (assignments || [])
          .filter(a => a.program_id === program.id)
          .map(a => a.student_id)
        return program
      })

      set({ programs: transformedPrograms, isLoading: false })
    } catch (error: any) {
      console.error('Error fetching programs:', error)
      set({ error: error.message, isLoading: false })
    }
  },

  addProgram: async (programData) => {
    const coach = useAuthStore.getState().coach
    if (!coach) throw new Error('Non authentifié')

    const dbData = programToDb(programData, coach.id)

    const { data, error } = await supabase
      .from('programs')
      .insert(dbData)
      .select()
      .single()

    if (error) throw error

    const newProgram = dbToProgram(data)
    newProgram.assignedStudentIds = []

    set((state) => ({ programs: [newProgram, ...state.programs] }))
    return newProgram.id
  },

  updateProgram: async (id, updates) => {
    const dbUpdates: any = {}
    if (updates.name !== undefined) dbUpdates.name = updates.name
    if (updates.description !== undefined) dbUpdates.description = updates.description
    if (updates.goal !== undefined) dbUpdates.goal = updates.goal
    if (updates.durationWeeks !== undefined) dbUpdates.duration_weeks = updates.durationWeeks
    if (updates.deloadFrequency !== undefined) dbUpdates.deload_frequency = updates.deloadFrequency
    if (updates.days !== undefined) dbUpdates.days = updates.days

    const { error } = await supabase
      .from('programs')
      .update(dbUpdates)
      .eq('id', id)

    if (error) throw error

    set((state) => ({
      programs: state.programs.map((p) =>
        p.id === id ? { ...p, ...updates, updatedAt: new Date().toISOString() } : p
      ),
    }))
  },

  deleteProgram: async (id) => {
    const { error } = await supabase
      .from('programs')
      .delete()
      .eq('id', id)

    if (error) throw error

    set((state) => ({
      programs: state.programs.filter((p) => p.id !== id),
    }))
  },

  duplicateProgram: async (id) => {
    const program = get().programs.find((p) => p.id === id)
    if (!program) return null

    const coach = useAuthStore.getState().coach
    if (!coach) return null

    // Create new program with copied data
    const duplicateData = {
      name: `${program.name} (copie)`,
      description: program.description,
      goal: program.goal,
      durationWeeks: program.durationWeeks,
      deloadFrequency: program.deloadFrequency,
      days: program.days.map((day) => ({
        ...day,
        id: generateId(),
        exercises: day.exercises.map((ex) => ({
          ...ex,
          id: generateId(),
          sets: ex.sets.map((set) => ({
            ...set,
            id: generateId(),
          })),
        })),
      })),
    }

    const newId = await get().addProgram(duplicateData)
    return newId
  },

  getProgramById: (id) => get().programs.find((p) => p.id === id),

  assignToStudent: async (programId, studentId) => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    // Check if assignment already exists
    const { data: existing } = await supabase
      .from('assignments')
      .select('id')
      .eq('coach_id', coach.id)
      .eq('student_id', studentId)
      .eq('program_id', programId)
      .single()

    if (existing) {
      // Update existing assignment to active
      await supabase
        .from('assignments')
        .update({ status: 'active' })
        .eq('id', existing.id)
    } else {
      // Create new assignment
      const { error } = await supabase
        .from('assignments')
        .insert({
          coach_id: coach.id,
          student_id: studentId,
          program_id: programId,
          status: 'active',
        })

      if (error) throw error
    }

    set((state) => ({
      programs: state.programs.map((p) =>
        p.id === programId
          ? {
              ...p,
              assignedStudentIds: [...new Set([...p.assignedStudentIds, studentId])],
              updatedAt: new Date().toISOString(),
            }
          : p
      ),
    }))
  },

  unassignFromStudent: async (programId, studentId) => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    // Set assignment status to paused instead of deleting
    const { error } = await supabase
      .from('assignments')
      .update({ status: 'paused' })
      .eq('coach_id', coach.id)
      .eq('student_id', studentId)
      .eq('program_id', programId)

    if (error) throw error

    set((state) => ({
      programs: state.programs.map((p) =>
        p.id === programId
          ? {
              ...p,
              assignedStudentIds: p.assignedStudentIds.filter((id) => id !== studentId),
              updatedAt: new Date().toISOString(),
            }
          : p
      ),
    }))
  },
}))
