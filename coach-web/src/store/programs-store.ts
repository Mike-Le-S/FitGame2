import { create } from 'zustand'
import type { Program, Exercise, WorkoutSet, MuscleGroup, ExerciseMode } from '@/types'
import { generateId } from '@/lib/utils'

interface ProgramsState {
  programs: Program[]
  addProgram: (program: Omit<Program, 'id' | 'createdAt' | 'updatedAt' | 'assignedStudentIds'>) => string
  updateProgram: (id: string, updates: Partial<Program>) => void
  deleteProgram: (id: string) => void
  assignToStudent: (programId: string, studentId: string) => void
  unassignFromStudent: (programId: string, studentId: string) => void
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

// Mock programs
const mockPrograms: Program[] = [
  {
    id: 'program-1',
    name: 'Push Pull Legs',
    description: 'Programme classique PPL sur 6 jours',
    goal: 'bulk',
    durationWeeks: 12,
    deloadFrequency: 4,
    days: [
      {
        id: 'day-1',
        name: 'Push A',
        dayOfWeek: 1,
        isRestDay: false,
        exercises: [
          createExercise('Développé couché', 'chest', 'rpt'),
          createExercise('Développé incliné', 'chest'),
          createExercise('Développé militaire', 'shoulders'),
          createExercise('Élévations latérales', 'shoulders'),
          createExercise('Pushdown triceps', 'triceps'),
        ],
      },
      {
        id: 'day-2',
        name: 'Pull A',
        dayOfWeek: 2,
        isRestDay: false,
        exercises: [
          createExercise('Soulevé de terre', 'back', 'rpt'),
          createExercise('Tractions', 'back'),
          createExercise('Rowing barre', 'back'),
          createExercise('Face pull', 'shoulders'),
          createExercise('Curl barre', 'biceps'),
        ],
      },
      {
        id: 'day-3',
        name: 'Legs A',
        dayOfWeek: 3,
        isRestDay: false,
        exercises: [
          createExercise('Squat', 'quads', 'rpt'),
          createExercise('Presse à cuisses', 'quads'),
          createExercise('Soulevé de terre roumain', 'hamstrings'),
          createExercise('Leg curl', 'hamstrings'),
          createExercise('Mollets debout', 'calves'),
        ],
      },
    ],
    createdAt: '2025-01-15T00:00:00Z',
    updatedAt: '2025-01-20T00:00:00Z',
    assignedStudentIds: ['student-1', 'student-3'],
  },
  {
    id: 'program-2',
    name: 'Upper Lower',
    description: 'Programme Upper/Lower 4 jours pour prise de masse',
    goal: 'bulk',
    durationWeeks: 8,
    days: [],
    createdAt: '2025-01-10T00:00:00Z',
    updatedAt: '2025-01-10T00:00:00Z',
    assignedStudentIds: ['student-2'],
  },
  {
    id: 'program-3',
    name: 'Full Body Débutant',
    description: 'Programme full body 3x/semaine',
    goal: 'maintain',
    durationWeeks: 6,
    days: [],
    createdAt: '2025-01-05T00:00:00Z',
    updatedAt: '2025-01-05T00:00:00Z',
    assignedStudentIds: ['student-4'],
  },
]

export const useProgramsStore = create<ProgramsState>((set) => ({
  programs: mockPrograms,

  addProgram: (programData) => {
    const id = generateId()
    const now = new Date().toISOString()
    const newProgram: Program = {
      ...programData,
      id,
      createdAt: now,
      updatedAt: now,
      assignedStudentIds: [],
    }
    set((state) => ({ programs: [...state.programs, newProgram] }))
    return id
  },

  updateProgram: (id, updates) => {
    set((state) => ({
      programs: state.programs.map((p) =>
        p.id === id ? { ...p, ...updates, updatedAt: new Date().toISOString() } : p
      ),
    }))
  },

  deleteProgram: (id) => {
    set((state) => ({
      programs: state.programs.filter((p) => p.id !== id),
    }))
  },

  assignToStudent: (programId, studentId) => {
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

  unassignFromStudent: (programId, studentId) => {
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
