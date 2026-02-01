import React, { ReactElement } from 'react'
import { render, RenderOptions } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

// Create a fresh QueryClient for each test
const createTestQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
        staleTime: 0,
      },
      mutations: {
        retry: false,
      },
    },
  })

interface WrapperProps {
  children: React.ReactNode
}

// All providers wrapper
const AllProviders = ({ children }: WrapperProps) => {
  const queryClient = createTestQueryClient()
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>{children}</BrowserRouter>
    </QueryClientProvider>
  )
}

// Custom render function
const customRender = (
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) => render(ui, { wrapper: AllProviders, ...options })

// Re-export everything
export * from '@testing-library/react'
export { customRender as render }

// Test data factories
export const createTestStudent = (overrides = {}) => ({
  id: 'student-1',
  email: 'student@test.com',
  fullName: 'Test Student',
  avatarUrl: null,
  goal: 'strength' as const,
  assignedProgram: null,
  assignedDiet: null,
  lastActive: new Date().toISOString(),
  joinedAt: new Date().toISOString(),
  stats: {
    totalSessions: 10,
    currentStreak: 5,
    thisWeekSessions: 3,
    averageSessionDuration: 45,
    totalVolumeKg: 50000,
    personalRecords: 12,
  },
  ...overrides,
})

export const createTestProgram = (overrides = {}) => ({
  id: 'program-1',
  name: 'Test Program',
  description: 'A test program',
  goal: 'strength' as const,
  durationWeeks: 8,
  deloadFrequency: 4,
  days: [],
  createdBy: 'coach-1',
  createdAt: new Date().toISOString(),
  assignedCount: 0,
  ...overrides,
})

export const createTestDietPlan = (overrides = {}) => ({
  id: 'diet-1',
  name: 'Test Diet',
  goal: 'maintain' as const,
  trainingCalories: 2500,
  restCalories: 2000,
  trainingMacros: { protein: 180, carbs: 280, fat: 70 },
  restMacros: { protein: 180, carbs: 200, fat: 65 },
  meals: [],
  supplements: [],
  createdBy: 'coach-1',
  createdAt: new Date().toISOString(),
  assignedCount: 0,
  ...overrides,
})

export const createTestCoach = (overrides = {}) => ({
  id: 'coach-1',
  email: 'coach@test.com',
  fullName: 'Test Coach',
  avatarUrl: null,
  businessName: 'Test Coaching',
  specialization: 'Strength & Conditioning',
  credentials: 'Certified Trainer',
  twoFactorEnabled: false,
  theme: 'dark' as const,
  accentColor: 'orange',
  ...overrides,
})

// Mock Supabase client
export const createMockSupabaseClient = () => ({
  auth: {
    getSession: vi.fn().mockResolvedValue({ data: { session: null }, error: null }),
    signInWithPassword: vi.fn(),
    signUp: vi.fn(),
    signOut: vi.fn(),
    onAuthStateChange: vi.fn(() => ({ data: { subscription: { unsubscribe: vi.fn() } } })),
  },
  from: vi.fn(() => ({
    select: vi.fn().mockReturnThis(),
    insert: vi.fn().mockReturnThis(),
    update: vi.fn().mockReturnThis(),
    delete: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    single: vi.fn().mockResolvedValue({ data: null, error: null }),
    order: vi.fn().mockReturnThis(),
    limit: vi.fn().mockReturnThis(),
  })),
  channel: vi.fn(() => ({
    on: vi.fn().mockReturnThis(),
    subscribe: vi.fn(),
  })),
  removeChannel: vi.fn(),
})
