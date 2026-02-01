import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { useProgramsStore, exerciseCatalog, createDefaultSets, createExercise } from '@/store/programs-store'
import { useAuthStore } from '@/store/auth-store'

// Mock the supabase module
const mockFrom = vi.fn()

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: vi.fn().mockResolvedValue({ data: { session: null }, error: null }),
      signInWithPassword: vi.fn(),
      signUp: vi.fn(),
      signOut: vi.fn(),
      onAuthStateChange: vi.fn(() => ({
        data: { subscription: { unsubscribe: vi.fn() } },
      })),
    },
    from: (table: string) => mockFrom(table),
  },
}))

// Mock generateId for predictable tests
vi.mock('@/lib/utils', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/lib/utils')>()
  let counter = 0
  return {
    ...actual,
    generateId: vi.fn(() => `generated-id-${++counter}`),
  }
})

// Create chainable mock for Supabase queries
function createChainableMock(resolvedValue: any = { data: null, error: null }) {
  const createMock = (): any => {
    const mock: any = {}
    mock.select = vi.fn(() => mock)
    mock.insert = vi.fn(() => mock)
    mock.update = vi.fn(() => mock)
    mock.delete = vi.fn(() => mock)
    mock.eq = vi.fn(() => mock)
    mock.single = vi.fn().mockResolvedValue(resolvedValue)
    mock.order = vi.fn(() => mock)
    mock.limit = vi.fn(() => mock)
    mock.in = vi.fn(() => mock)
    mock.not = vi.fn(() => mock)
    // Make the mock itself a promise for terminal methods
    mock.then = (resolve: any) => resolve(resolvedValue)
    return mock
  }
  return createMock()
}

// Helper to reset store state
function resetStore() {
  useProgramsStore.setState({
    programs: [],
    isLoading: false,
    error: null,
  })
}

// Mock coach for authenticated operations
const mockCoach = {
  id: 'coach-123',
  name: 'Test Coach',
  email: 'coach@test.com',
}

describe('useProgramsStore', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    resetStore()
    // Set up authenticated coach
    useAuthStore.setState({
      coach: mockCoach,
      token: 'mock-token',
      isAuthenticated: true,
      isLoading: false,
    })
  })

  afterEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({
      coach: null,
      token: null,
      isAuthenticated: false,
      isLoading: true,
    })
  })

  describe('initial state', () => {
    it('should have correct initial state', () => {
      resetStore()
      const state = useProgramsStore.getState()
      expect(state.programs).toEqual([])
      expect(state.isLoading).toBe(false)
      expect(state.error).toBeNull()
    })
  })

  describe('exerciseCatalog', () => {
    it('should have all muscle groups', () => {
      const expectedGroups = [
        'chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms',
        'quads', 'hamstrings', 'glutes', 'calves', 'abs', 'cardio',
      ]
      expect(Object.keys(exerciseCatalog)).toEqual(expectedGroups)
    })

    it('should have exercises for each muscle group', () => {
      Object.keys(exerciseCatalog).forEach(group => {
        expect(exerciseCatalog[group as keyof typeof exerciseCatalog].length).toBeGreaterThan(0)
      })
    })

    it('should have valid exercise structure', () => {
      const chestExercises = exerciseCatalog.chest
      expect(chestExercises[0]).toHaveProperty('id')
      expect(chestExercises[0]).toHaveProperty('name')
    })
  })

  describe('createDefaultSets', () => {
    it('should create classic mode sets with default reps', () => {
      const sets = createDefaultSets('classic', 3)
      expect(sets).toHaveLength(3)
      sets.forEach(set => {
        expect(set.targetReps).toBe(10)
        expect(set.restSeconds).toBe(90)
        expect(set.isWarmup).toBe(false)
      })
    })

    it('should create RPT mode sets with progressive reps', () => {
      const sets = createDefaultSets('rpt', 3)
      expect(sets).toHaveLength(3)
      expect(sets[0].targetReps).toBe(6)
      expect(sets[1].targetReps).toBe(8)
      expect(sets[2].targetReps).toBe(10)
      sets.forEach(set => {
        expect(set.restSeconds).toBe(180)
      })
    })

    it('should default to 3 sets if count not specified', () => {
      const sets = createDefaultSets('classic')
      expect(sets).toHaveLength(3)
    })
  })

  describe('createExercise', () => {
    it('should create exercise with correct structure', () => {
      const exercise = createExercise('Bench Press', 'chest', 'classic')
      expect(exercise).toHaveProperty('id')
      expect(exercise.name).toBe('Bench Press')
      expect(exercise.muscle).toBe('chest')
      expect(exercise.mode).toBe('classic')
      expect(exercise.sets).toHaveLength(3)
    })

    it('should use classic mode as default', () => {
      const exercise = createExercise('Squat', 'quads')
      expect(exercise.mode).toBe('classic')
    })
  })

  describe('fetchPrograms', () => {
    it('should fetch programs successfully', async () => {
      const mockPrograms = [
        {
          id: 'program-1',
          name: 'Push Pull Legs',
          description: 'Classic PPL split',
          goal: 'strength',
          duration_weeks: 8,
          deload_frequency: 4,
          days: [],
          created_at: '2024-01-01T00:00:00Z',
          updated_at: '2024-01-15T00:00:00Z',
        },
        {
          id: 'program-2',
          name: 'Upper Lower',
          description: 'Upper/Lower split',
          goal: 'bulk',
          duration_weeks: 12,
          deload_frequency: null,
          days: [],
          created_at: '2024-02-01T00:00:00Z',
          updated_at: '2024-02-10T00:00:00Z',
        },
      ]

      const mockAssignments: any[] = []

      mockFrom.mockImplementation((table) => {
        if (table === 'programs') {
          const mock = createChainableMock()
          mock.order = vi.fn().mockResolvedValue({ data: mockPrograms, error: null })
          return mock
        }
        if (table === 'assignments') {
          return createChainableMock({ data: mockAssignments, error: null })
        }
        return createChainableMock()
      })

      await useProgramsStore.getState().fetchPrograms()

      const state = useProgramsStore.getState()
      expect(state.isLoading).toBe(false)
      expect(state.error).toBeNull()
      expect(state.programs).toHaveLength(2)
      expect(state.programs[0].name).toBe('Push Pull Legs')
      expect(state.programs[0].goal).toBe('strength')
      expect(state.programs[0].durationWeeks).toBe(8)
      expect(state.programs[1].name).toBe('Upper Lower')
    })

    it('should not fetch if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await useProgramsStore.getState().fetchPrograms()

      expect(mockFrom).not.toHaveBeenCalled()
    })

    it('should handle fetch error', async () => {
      mockFrom.mockImplementation(() => {
        const mock = createChainableMock()
        mock.order = vi.fn().mockResolvedValue({
          data: null,
          error: { message: 'Database error' },
        })
        return mock
      })

      await useProgramsStore.getState().fetchPrograms()

      const state = useProgramsStore.getState()
      expect(state.isLoading).toBe(false)
      expect(state.error).toBe('Database error')
    })

    it('should set loading state while fetching', async () => {
      mockFrom.mockImplementation(() => {
        const mock = createChainableMock()
        mock.order = vi.fn().mockResolvedValue({ data: [], error: null })
        return mock
      })

      const fetchPromise = useProgramsStore.getState().fetchPrograms()

      // Check loading state is set
      expect(useProgramsStore.getState().isLoading).toBe(true)

      await fetchPromise

      expect(useProgramsStore.getState().isLoading).toBe(false)
    })
  })

  describe('addProgram', () => {
    it('should add program successfully', async () => {
      const mockInsertedData = {
        id: 'new-program-123',
        name: 'New Program',
        description: 'Test description',
        goal: 'strength',
        duration_weeks: 8,
        deload_frequency: 4,
        days: [],
        created_at: '2024-12-20T00:00:00Z',
        updated_at: '2024-12-20T00:00:00Z',
      }

      mockFrom.mockImplementation(() => ({
        insert: vi.fn().mockReturnThis(),
        select: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: mockInsertedData, error: null }),
      }))

      const newProgramData = {
        name: 'New Program',
        description: 'Test description',
        goal: 'strength' as const,
        durationWeeks: 8,
        deloadFrequency: 4,
        days: [],
      }

      const newId = await useProgramsStore.getState().addProgram(newProgramData)

      expect(newId).toBe('new-program-123')

      const state = useProgramsStore.getState()
      expect(state.programs).toHaveLength(1)
      expect(state.programs[0].name).toBe('New Program')
      expect(state.programs[0].assignedStudentIds).toEqual([])
    })

    it('should throw error if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await expect(
        useProgramsStore.getState().addProgram({
          name: 'Test',
          goal: 'strength',
          durationWeeks: 8,
          days: [],
        })
      ).rejects.toThrow('Non authentifié')
    })

    it('should throw error if insert fails', async () => {
      mockFrom.mockImplementation(() => ({
        insert: vi.fn().mockReturnThis(),
        select: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: null, error: { message: 'Insert failed' } }),
      }))

      await expect(
        useProgramsStore.getState().addProgram({
          name: 'Test',
          goal: 'strength',
          durationWeeks: 8,
          days: [],
        })
      ).rejects.toThrow()
    })
  })

  describe('updateProgram', () => {
    beforeEach(() => {
      useProgramsStore.setState({
        programs: [
          {
            id: 'program-1',
            name: 'Original Name',
            description: 'Original description',
            goal: 'strength',
            durationWeeks: 8,
            days: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: [],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should update program successfully', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: null }),
      }))

      await useProgramsStore.getState().updateProgram('program-1', { name: 'Updated Name' })

      const state = useProgramsStore.getState()
      expect(state.programs[0].name).toBe('Updated Name')
      expect(state.programs[0].updatedAt).not.toBe('2024-01-15T00:00:00Z')
    })

    it('should update multiple fields', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: null }),
      }))

      await useProgramsStore.getState().updateProgram('program-1', {
        name: 'New Name',
        description: 'New description',
        durationWeeks: 12,
        deloadFrequency: 5,
      })

      const state = useProgramsStore.getState()
      expect(state.programs[0].name).toBe('New Name')
      expect(state.programs[0].description).toBe('New description')
      expect(state.programs[0].durationWeeks).toBe(12)
      expect(state.programs[0].deloadFrequency).toBe(5)
    })

    it('should update days array', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: null }),
      }))

      const newDays = [
        {
          id: 'day-1',
          name: 'Day A',
          dayOfWeek: 1,
          exercises: [],
          isRestDay: false,
        },
      ]

      await useProgramsStore.getState().updateProgram('program-1', { days: newDays })

      const state = useProgramsStore.getState()
      expect(state.programs[0].days).toHaveLength(1)
      expect(state.programs[0].days[0].name).toBe('Day A')
    })

    it('should throw error if update fails', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: { message: 'Update failed' } }),
      }))

      await expect(
        useProgramsStore.getState().updateProgram('program-1', { name: 'New Name' })
      ).rejects.toThrow()
    })
  })

  describe('deleteProgram', () => {
    beforeEach(() => {
      useProgramsStore.setState({
        programs: [
          {
            id: 'program-1',
            name: 'Program 1',
            goal: 'strength',
            durationWeeks: 8,
            days: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: [],
          },
          {
            id: 'program-2',
            name: 'Program 2',
            goal: 'bulk',
            durationWeeks: 12,
            days: [],
            createdAt: '2024-02-01T00:00:00Z',
            updatedAt: '2024-02-10T00:00:00Z',
            assignedStudentIds: [],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should delete program successfully', async () => {
      mockFrom.mockImplementation(() => ({
        delete: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: null }),
      }))

      await useProgramsStore.getState().deleteProgram('program-1')

      const state = useProgramsStore.getState()
      expect(state.programs).toHaveLength(1)
      expect(state.programs[0].id).toBe('program-2')
    })

    it('should throw error if delete fails', async () => {
      mockFrom.mockImplementation(() => ({
        delete: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: { message: 'Delete failed' } }),
      }))

      await expect(
        useProgramsStore.getState().deleteProgram('program-1')
      ).rejects.toThrow()
    })
  })

  describe('duplicateProgram', () => {
    beforeEach(() => {
      useProgramsStore.setState({
        programs: [
          {
            id: 'program-1',
            name: 'Original Program',
            description: 'Original description',
            goal: 'strength',
            durationWeeks: 8,
            deloadFrequency: 4,
            days: [
              {
                id: 'day-1',
                name: 'Day A',
                dayOfWeek: 1,
                exercises: [
                  {
                    id: 'exercise-1',
                    name: 'Bench Press',
                    muscle: 'chest',
                    mode: 'classic',
                    sets: [
                      { id: 'set-1', targetReps: 10, targetWeight: 60, isWarmup: false, restSeconds: 90 },
                    ],
                  },
                ],
                isRestDay: false,
              },
            ],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: ['student-1'],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should duplicate program with new IDs', async () => {
      const mockInsertedData = {
        id: 'new-program-123',
        name: 'Original Program (copie)',
        description: 'Original description',
        goal: 'strength',
        duration_weeks: 8,
        deload_frequency: 4,
        days: [],
        created_at: '2024-12-20T00:00:00Z',
        updated_at: '2024-12-20T00:00:00Z',
      }

      mockFrom.mockImplementation(() => ({
        insert: vi.fn().mockReturnThis(),
        select: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: mockInsertedData, error: null }),
      }))

      const newId = await useProgramsStore.getState().duplicateProgram('program-1')

      expect(newId).toBe('new-program-123')

      const state = useProgramsStore.getState()
      expect(state.programs).toHaveLength(2)
      expect(state.programs[0].name).toBe('Original Program (copie)')
      // Original should still exist
      expect(state.programs.some(p => p.id === 'program-1')).toBe(true)
    })

    it('should return null if program not found', async () => {
      const newId = await useProgramsStore.getState().duplicateProgram('non-existent')
      expect(newId).toBeNull()
    })

    it('should return null if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      const newId = await useProgramsStore.getState().duplicateProgram('program-1')
      expect(newId).toBeNull()
    })
  })

  describe('getProgramById', () => {
    beforeEach(() => {
      useProgramsStore.setState({
        programs: [
          {
            id: 'program-1',
            name: 'Program 1',
            goal: 'strength',
            durationWeeks: 8,
            days: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: [],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should return program by id', () => {
      const program = useProgramsStore.getState().getProgramById('program-1')
      expect(program).toBeDefined()
      expect(program?.name).toBe('Program 1')
    })

    it('should return undefined for non-existent id', () => {
      const program = useProgramsStore.getState().getProgramById('non-existent')
      expect(program).toBeUndefined()
    })
  })

  describe('assignToStudent', () => {
    beforeEach(() => {
      useProgramsStore.setState({
        programs: [
          {
            id: 'program-1',
            name: 'Program 1',
            goal: 'strength',
            durationWeeks: 8,
            days: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: [],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should assign program to new student', async () => {
      const insertMock = vi.fn().mockResolvedValue({ data: null, error: null })

      mockFrom.mockImplementation(() => ({
        select: vi.fn().mockReturnThis(),
        insert: insertMock,
        eq: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: null, error: null }),
      }))

      await useProgramsStore.getState().assignToStudent('program-1', 'student-1')

      const state = useProgramsStore.getState()
      expect(state.programs[0].assignedStudentIds).toContain('student-1')
    })

    it('should update existing assignment', async () => {
      const updateMock = vi.fn().mockReturnThis()
      const existingAssignment = { id: 'assignment-1' }

      mockFrom.mockImplementation(() => ({
        select: vi.fn().mockReturnThis(),
        update: updateMock,
        eq: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: existingAssignment, error: null }),
      }))

      await useProgramsStore.getState().assignToStudent('program-1', 'student-1')

      const state = useProgramsStore.getState()
      expect(state.programs[0].assignedStudentIds).toContain('student-1')
    })

    it('should not duplicate student id', async () => {
      useProgramsStore.setState({
        programs: [
          {
            id: 'program-1',
            name: 'Program 1',
            goal: 'strength',
            durationWeeks: 8,
            days: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: ['student-1'],
          },
        ],
        isLoading: false,
        error: null,
      })

      const existingAssignment = { id: 'assignment-1' }

      mockFrom.mockImplementation(() => ({
        select: vi.fn().mockReturnThis(),
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: existingAssignment, error: null }),
      }))

      await useProgramsStore.getState().assignToStudent('program-1', 'student-1')

      const state = useProgramsStore.getState()
      expect(state.programs[0].assignedStudentIds.filter(id => id === 'student-1')).toHaveLength(1)
    })

    it('should not assign if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await useProgramsStore.getState().assignToStudent('program-1', 'student-1')

      expect(mockFrom).not.toHaveBeenCalled()
    })
  })

  describe('unassignFromStudent', () => {
    beforeEach(() => {
      useProgramsStore.setState({
        programs: [
          {
            id: 'program-1',
            name: 'Program 1',
            goal: 'strength',
            durationWeeks: 8,
            days: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: ['student-1', 'student-2'],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should unassign student from program', async () => {
      mockFrom.mockImplementation(() => createChainableMock({ data: null, error: null }))

      await useProgramsStore.getState().unassignFromStudent('program-1', 'student-1')

      const state = useProgramsStore.getState()
      expect(state.programs[0].assignedStudentIds).toEqual(['student-2'])
      expect(state.programs[0].assignedStudentIds).not.toContain('student-1')
    })

    it('should throw error if unassign fails', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: { message: 'Unassign failed' } }),
      }))

      await expect(
        useProgramsStore.getState().unassignFromStudent('program-1', 'student-1')
      ).rejects.toThrow()
    })

    it('should not unassign if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await useProgramsStore.getState().unassignFromStudent('program-1', 'student-1')

      expect(mockFrom).not.toHaveBeenCalled()
      // State should remain unchanged
      const state = useProgramsStore.getState()
      expect(state.programs[0].assignedStudentIds).toEqual(['student-1', 'student-2'])
    })
  })
})
