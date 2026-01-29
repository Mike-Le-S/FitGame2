// ============================================
// Core Types - Compatible with FitGame mobile app
// ============================================

export type MuscleGroup =
  | 'chest'
  | 'back'
  | 'shoulders'
  | 'biceps'
  | 'triceps'
  | 'forearms'
  | 'quads'
  | 'hamstrings'
  | 'glutes'
  | 'calves'
  | 'abs'
  | 'cardio'

export type Goal = 'bulk' | 'cut' | 'maintain'

export type ExerciseMode = 'classic' | 'rpt' | 'pyramidal' | 'dropset'

// ============================================
// Student Types
// ============================================

export interface Student {
  id: string
  name: string
  email: string
  avatarUrl?: string
  goal: Goal
  assignedProgramId?: string
  assignedDietId?: string
  currentStreak: number
  lastWorkout?: string
  joinedAt: string
  stats: StudentStats
}

export interface StudentStats {
  totalWorkouts: number
  thisWeekWorkouts: number
  averageSessionDuration: number
  complianceRate: number
}

// ============================================
// Workout Types
// ============================================

export interface WorkoutSet {
  id: string
  targetReps: number
  targetWeight: number
  isWarmup: boolean
  restSeconds: number
  actualReps?: number
  actualWeight?: number
  completedAt?: string
}

export interface Exercise {
  id: string
  name: string
  muscle: MuscleGroup
  sets: WorkoutSet[]
  mode: ExerciseMode
  notes?: string
}

export interface WorkoutDay {
  id: string
  name: string
  dayOfWeek: number // 0-6, 0 = dimanche
  exercises: Exercise[]
  isRestDay: boolean
}

export interface Program {
  id: string
  name: string
  description?: string
  goal: Goal
  durationWeeks: number
  days: WorkoutDay[]
  deloadFrequency?: number // every X weeks
  createdAt: string
  updatedAt: string
  assignedStudentIds: string[]
}

export interface WorkoutSession {
  id: string
  programId: string
  studentId: string
  dayId: string
  startedAt: string
  completedAt?: string
  exercises: Exercise[]
  notes?: string
}

// ============================================
// Nutrition Types
// ============================================

export interface Macros {
  protein: number
  carbs: number
  fat: number
}

export interface FoodEntry {
  id: string
  name: string
  calories: number
  macros: Macros
  quantity: number
  unit: string
}

export interface MealPlan {
  id: string
  name: string // breakfast, lunch, snack, dinner
  foods: FoodEntry[]
  targetTime?: string
}

export interface SupplementEntry {
  id: string
  name: string
  dosage: string
  timing: 'morning' | 'pre-workout' | 'post-workout' | 'evening' | 'with-meal'
  notes?: string
}

export interface DietPlan {
  id: string
  name: string
  goal: Goal
  trainingCalories: number
  restCalories: number
  trainingMacros: Macros
  restMacros: Macros
  meals: MealPlan[]
  supplements: SupplementEntry[]
  notes?: string
  createdAt: string
  updatedAt: string
  assignedStudentIds: string[]
}

// ============================================
// Health Types
// ============================================

export interface SleepData {
  date: string
  totalMinutes: number
  deepMinutes: number
  coreMinutes: number
  remMinutes: number
  score: number
}

export interface HeartData {
  date: string
  restingHR: number
  hrv: number
  maxHR?: number
}

export interface EnergyBalance {
  date: string
  consumed: number
  burned: number
  netBalance: number
}

// ============================================
// Calendar Types
// ============================================

export interface CalendarEvent {
  id: string
  studentId: string
  title: string
  type: 'workout' | 'nutrition' | 'check-in' | 'other'
  date: string
  time?: string
  duration?: number
  notes?: string
  completed: boolean
}

// ============================================
// Messaging Types
// ============================================

export interface Message {
  id: string
  conversationId: string
  senderId: string
  content: string
  sentAt: string
  readAt?: string
}

export interface Conversation {
  id: string
  studentId: string
  lastMessage?: Message
  unreadCount: number
  updatedAt: string
}

// ============================================
// Coach Types
// ============================================

export interface Coach {
  id: string
  name: string
  email: string
  avatarUrl?: string
}
