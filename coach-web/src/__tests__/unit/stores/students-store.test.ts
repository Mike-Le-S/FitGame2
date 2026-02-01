import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { useStudentsStore } from '@/store/students-store'
import { useAuthStore } from '@/store/auth-store'

// Mock the supabase module
const mockFrom = vi.fn()
const mockSignUp = vi.fn()

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      signUp: (params: any) => mockSignUp(params),
      getSession: vi.fn().mockResolvedValue({ data: { session: null }, error: null }),
      signInWithPassword: vi.fn(),
      signOut: vi.fn(),
      onAuthStateChange: vi.fn(() => ({
        data: { subscription: { unsubscribe: vi.fn() } },
      })),
    },
    from: (table: string) => mockFrom(table),
  },
}))

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
  useStudentsStore.setState({
    students: [],
    isLoading: false,
    error: null,
    selectedStudentId: null,
    studentSessions: {},
  })
}

// Mock coach for authenticated operations
const mockCoach = {
  id: 'coach-123',
  name: 'Test Coach',
  email: 'coach@test.com',
}

describe('useStudentsStore', () => {
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
      const state = useStudentsStore.getState()
      expect(state.students).toEqual([])
      expect(state.isLoading).toBe(false)
      expect(state.error).toBeNull()
      expect(state.selectedStudentId).toBeNull()
      expect(state.studentSessions).toEqual({})
    })
  })

  describe('fetchStudents', () => {
    it('should fetch students successfully', async () => {
      const mockProfiles = [
        {
          id: 'student-1',
          full_name: 'Student One',
          email: 'student1@test.com',
          avatar_url: null,
          goal: 'strength',
          current_streak: 5,
          total_sessions: 20,
          created_at: '2024-01-01T00:00:00Z',
        },
        {
          id: 'student-2',
          full_name: 'Student Two',
          email: 'student2@test.com',
          avatar_url: 'https://example.com/avatar.jpg',
          goal: 'bulk',
          current_streak: 3,
          total_sessions: 15,
          created_at: '2024-02-01T00:00:00Z',
        },
      ]

      const mockAssignments: any[] = []
      const mockSessions: any[] = []

      mockFrom.mockImplementation((table) => {
        if (table === 'profiles') {
          const mock = createChainableMock({ data: mockProfiles, error: null })
          mock.order = vi.fn().mockResolvedValue({ data: mockProfiles, error: null })
          return mock
        }
        if (table === 'assignments') {
          return createChainableMock({ data: mockAssignments, error: null })
        }
        if (table === 'workout_sessions') {
          const mock = createChainableMock({ data: mockSessions, error: null })
          mock.limit = vi.fn().mockResolvedValue({ data: mockSessions, error: null })
          return mock
        }
        return createChainableMock({ data: null, error: null })
      })

      await useStudentsStore.getState().fetchStudents()

      const state = useStudentsStore.getState()
      expect(state.isLoading).toBe(false)
      expect(state.error).toBeNull()
      expect(state.students).toHaveLength(2)
      expect(state.students[0].id).toBe('student-1')
      expect(state.students[0].name).toBe('Student One')
      expect(state.students[1].id).toBe('student-2')
      expect(state.students[1].name).toBe('Student Two')
    })

    it('should not fetch if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await useStudentsStore.getState().fetchStudents()

      expect(mockFrom).not.toHaveBeenCalled()
      const state = useStudentsStore.getState()
      expect(state.students).toEqual([])
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

      await useStudentsStore.getState().fetchStudents()

      const state = useStudentsStore.getState()
      expect(state.isLoading).toBe(false)
      expect(state.error).toBe('Database error')
    })

    it('should handle empty student list', async () => {
      mockFrom.mockImplementation((table) => {
        if (table === 'profiles') {
          const mock = createChainableMock()
          mock.order = vi.fn().mockResolvedValue({ data: [], error: null })
          return mock
        }
        return createChainableMock({ data: [], error: null })
      })

      await useStudentsStore.getState().fetchStudents()

      const state = useStudentsStore.getState()
      expect(state.students).toEqual([])
      expect(state.isLoading).toBe(false)
      expect(state.error).toBeNull()
    })
  })

  describe('setSelectedStudent', () => {
    it('should set selected student id', () => {
      useStudentsStore.getState().setSelectedStudent('student-1')
      expect(useStudentsStore.getState().selectedStudentId).toBe('student-1')
    })

    it('should clear selected student id when null', () => {
      useStudentsStore.getState().setSelectedStudent('student-1')
      useStudentsStore.getState().setSelectedStudent(null)
      expect(useStudentsStore.getState().selectedStudentId).toBeNull()
    })
  })

  describe('getStudentById', () => {
    beforeEach(() => {
      useStudentsStore.setState({
        students: [
          {
            id: 'student-1',
            name: 'Student One',
            email: 'student1@test.com',
            goal: 'strength',
            currentStreak: 5,
            joinedAt: '2024-01-01T00:00:00Z',
            stats: {
              totalWorkouts: 20,
              thisWeekWorkouts: 3,
              averageSessionDuration: 45,
              complianceRate: 85,
            },
          },
        ],
        isLoading: false,
        error: null,
        selectedStudentId: null,
        studentSessions: {},
      })
    })

    it('should return student by id', () => {
      const student = useStudentsStore.getState().getStudentById('student-1')
      expect(student).toBeDefined()
      expect(student?.name).toBe('Student One')
    })

    it('should return undefined for non-existent id', () => {
      const student = useStudentsStore.getState().getStudentById('non-existent')
      expect(student).toBeUndefined()
    })
  })

  describe('addStudent', () => {
    it('should add student successfully', async () => {
      const mockAuthData = {
        user: { id: 'new-student-123' },
        session: { access_token: 'token' },
      }

      mockSignUp.mockResolvedValue({
        data: mockAuthData,
        error: null,
      })

      const insertMock = vi.fn().mockResolvedValue({ data: null, error: null })
      mockFrom.mockImplementation(() => ({
        insert: insertMock,
      }))

      const newStudentData = {
        name: 'New Student',
        email: 'newstudent@test.com',
        goal: 'bulk' as const,
        assignedProgramId: 'program-1',
      }

      const newId = await useStudentsStore.getState().addStudent(newStudentData)

      expect(newId).toBe('new-student-123')

      const state = useStudentsStore.getState()
      expect(state.students).toHaveLength(1)
      expect(state.students[0].name).toBe('New Student')
      expect(state.students[0].email).toBe('newstudent@test.com')
      expect(state.students[0].goal).toBe('bulk')
      expect(state.students[0].assignedProgramId).toBe('program-1')
      expect(state.students[0].stats.totalWorkouts).toBe(0)
    })

    it('should throw error if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await expect(
        useStudentsStore.getState().addStudent({
          name: 'Test',
          email: 'test@test.com',
          goal: 'maintain',
        })
      ).rejects.toThrow('Non authentifié')
    })

    it('should throw error if email already exists', async () => {
      mockSignUp.mockResolvedValue({
        data: { user: null, session: null },
        error: { message: 'User already registered' },
      })

      await expect(
        useStudentsStore.getState().addStudent({
          name: 'Test',
          email: 'existing@test.com',
          goal: 'maintain',
        })
      ).rejects.toThrow('Cet email est déjà utilisé')
    })

    it('should throw error if user creation fails', async () => {
      mockSignUp.mockResolvedValue({
        data: { user: null, session: null },
        error: null,
      })

      await expect(
        useStudentsStore.getState().addStudent({
          name: 'Test',
          email: 'test@test.com',
          goal: 'maintain',
        })
      ).rejects.toThrow('Erreur lors de la création du compte')
    })
  })

  describe('updateStudent', () => {
    beforeEach(() => {
      useStudentsStore.setState({
        students: [
          {
            id: 'student-1',
            name: 'Original Name',
            email: 'original@test.com',
            goal: 'strength',
            currentStreak: 5,
            joinedAt: '2024-01-01T00:00:00Z',
            stats: {
              totalWorkouts: 20,
              thisWeekWorkouts: 3,
              averageSessionDuration: 45,
              complianceRate: 85,
            },
          },
        ],
        isLoading: false,
        error: null,
        selectedStudentId: null,
        studentSessions: {},
      })
    })

    it('should update student successfully', async () => {
      const updateMock = vi.fn().mockReturnThis()
      const eqMock = vi.fn().mockResolvedValue({ data: null, error: null })
      mockFrom.mockImplementation(() => ({
        update: updateMock,
        eq: eqMock,
      }))

      await useStudentsStore.getState().updateStudent('student-1', { name: 'Updated Name' })

      const state = useStudentsStore.getState()
      expect(state.students[0].name).toBe('Updated Name')
    })

    it('should update multiple fields', async () => {
      const updateMock = vi.fn().mockReturnThis()
      const eqMock = vi.fn().mockResolvedValue({ data: null, error: null })
      mockFrom.mockImplementation(() => ({
        update: updateMock,
        eq: eqMock,
      }))

      await useStudentsStore.getState().updateStudent('student-1', {
        name: 'New Name',
        email: 'newemail@test.com',
        avatarUrl: 'https://example.com/new.jpg',
      })

      const state = useStudentsStore.getState()
      expect(state.students[0].name).toBe('New Name')
      expect(state.students[0].email).toBe('newemail@test.com')
      expect(state.students[0].avatarUrl).toBe('https://example.com/new.jpg')
    })

    it('should throw error if update fails', async () => {
      const updateMock = vi.fn().mockReturnThis()
      const eqMock = vi.fn().mockResolvedValue({ data: null, error: { message: 'Update failed' } })
      mockFrom.mockImplementation(() => ({
        update: updateMock,
        eq: eqMock,
      }))

      await expect(
        useStudentsStore.getState().updateStudent('student-1', { name: 'New Name' })
      ).rejects.toThrow()
    })
  })

  describe('deleteStudent', () => {
    beforeEach(() => {
      useStudentsStore.setState({
        students: [
          {
            id: 'student-1',
            name: 'Student One',
            email: 'student1@test.com',
            goal: 'strength',
            currentStreak: 5,
            joinedAt: '2024-01-01T00:00:00Z',
            stats: {
              totalWorkouts: 20,
              thisWeekWorkouts: 3,
              averageSessionDuration: 45,
              complianceRate: 85,
            },
          },
          {
            id: 'student-2',
            name: 'Student Two',
            email: 'student2@test.com',
            goal: 'bulk',
            currentStreak: 3,
            joinedAt: '2024-02-01T00:00:00Z',
            stats: {
              totalWorkouts: 15,
              thisWeekWorkouts: 2,
              averageSessionDuration: 50,
              complianceRate: 80,
            },
          },
        ],
        isLoading: false,
        error: null,
        selectedStudentId: null,
        studentSessions: {},
      })
    })

    it('should delete student successfully', async () => {
      const updateMock = vi.fn().mockReturnThis()
      const eqMock = vi.fn().mockReturnThis()
      const finalEq = vi.fn().mockResolvedValue({ data: null, error: null })

      mockFrom.mockImplementation((table) => {
        if (table === 'profiles') {
          return {
            update: updateMock,
            eq: finalEq,
          }
        }
        if (table === 'assignments') {
          return {
            update: updateMock,
            eq: eqMock,
          }
        }
        return createChainableMock()
      })

      await useStudentsStore.getState().deleteStudent('student-1')

      const state = useStudentsStore.getState()
      expect(state.students).toHaveLength(1)
      expect(state.students[0].id).toBe('student-2')
    })

    it('should not delete if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await useStudentsStore.getState().deleteStudent('student-1')

      const state = useStudentsStore.getState()
      expect(state.students).toHaveLength(2)
      expect(mockFrom).not.toHaveBeenCalled()
    })

    it('should throw error if delete fails', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: { message: 'Delete failed' } }),
      }))

      await expect(
        useStudentsStore.getState().deleteStudent('student-1')
      ).rejects.toThrow()
    })
  })

  describe('assignProgram', () => {
    beforeEach(() => {
      useStudentsStore.setState({
        students: [
          {
            id: 'student-1',
            name: 'Student One',
            email: 'student1@test.com',
            goal: 'strength',
            currentStreak: 5,
            joinedAt: '2024-01-01T00:00:00Z',
            stats: {
              totalWorkouts: 20,
              thisWeekWorkouts: 3,
              averageSessionDuration: 45,
              complianceRate: 85,
            },
          },
        ],
        isLoading: false,
        error: null,
        selectedStudentId: null,
        studentSessions: {},
      })
    })

    it('should assign program to student with existing assignment', async () => {
      const existingAssignment = { id: 'assignment-1' }

      mockFrom.mockImplementation((table) => {
        if (table === 'assignments') {
          return {
            select: vi.fn().mockReturnThis(),
            update: vi.fn().mockReturnThis(),
            eq: vi.fn().mockReturnThis(),
            single: vi.fn().mockResolvedValue({ data: existingAssignment, error: null }),
          }
        }
        return createChainableMock()
      })

      await useStudentsStore.getState().assignProgram('student-1', 'program-1')

      const state = useStudentsStore.getState()
      expect(state.students[0].assignedProgramId).toBe('program-1')
    })

    it('should create new assignment if none exists', async () => {
      const insertMock = vi.fn().mockResolvedValue({ data: null, error: null })

      mockFrom.mockImplementation((table) => {
        if (table === 'assignments') {
          return {
            select: vi.fn().mockReturnThis(),
            insert: insertMock,
            eq: vi.fn().mockReturnThis(),
            single: vi.fn().mockResolvedValue({ data: null, error: null }),
          }
        }
        return createChainableMock()
      })

      await useStudentsStore.getState().assignProgram('student-1', 'program-1')

      const state = useStudentsStore.getState()
      expect(state.students[0].assignedProgramId).toBe('program-1')
    })

    it('should remove program assignment when programId is undefined', async () => {
      useStudentsStore.setState({
        students: [
          {
            id: 'student-1',
            name: 'Student One',
            email: 'student1@test.com',
            goal: 'strength',
            assignedProgramId: 'program-1',
            currentStreak: 5,
            joinedAt: '2024-01-01T00:00:00Z',
            stats: {
              totalWorkouts: 20,
              thisWeekWorkouts: 3,
              averageSessionDuration: 45,
              complianceRate: 85,
            },
          },
        ],
        isLoading: false,
        error: null,
        selectedStudentId: null,
        studentSessions: {},
      })

      mockFrom.mockImplementation(() => createChainableMock({ data: null, error: null }))

      await useStudentsStore.getState().assignProgram('student-1', undefined)

      const state = useStudentsStore.getState()
      expect(state.students[0].assignedProgramId).toBeUndefined()
    })

    it('should not assign if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await useStudentsStore.getState().assignProgram('student-1', 'program-1')

      expect(mockFrom).not.toHaveBeenCalled()
    })
  })

  describe('assignDiet', () => {
    beforeEach(() => {
      useStudentsStore.setState({
        students: [
          {
            id: 'student-1',
            name: 'Student One',
            email: 'student1@test.com',
            goal: 'strength',
            currentStreak: 5,
            joinedAt: '2024-01-01T00:00:00Z',
            stats: {
              totalWorkouts: 20,
              thisWeekWorkouts: 3,
              averageSessionDuration: 45,
              complianceRate: 85,
            },
          },
        ],
        isLoading: false,
        error: null,
        selectedStudentId: null,
        studentSessions: {},
      })
    })

    it('should assign diet to student', async () => {
      const existingAssignment = { id: 'assignment-1' }

      mockFrom.mockImplementation((table) => {
        if (table === 'assignments') {
          return {
            select: vi.fn().mockReturnThis(),
            update: vi.fn().mockReturnThis(),
            eq: vi.fn().mockReturnThis(),
            single: vi.fn().mockResolvedValue({ data: existingAssignment, error: null }),
          }
        }
        return createChainableMock()
      })

      await useStudentsStore.getState().assignDiet('student-1', 'diet-1')

      const state = useStudentsStore.getState()
      expect(state.students[0].assignedDietId).toBe('diet-1')
    })

    it('should remove diet assignment when dietId is undefined', async () => {
      useStudentsStore.setState({
        students: [
          {
            id: 'student-1',
            name: 'Student One',
            email: 'student1@test.com',
            goal: 'strength',
            assignedDietId: 'diet-1',
            currentStreak: 5,
            joinedAt: '2024-01-01T00:00:00Z',
            stats: {
              totalWorkouts: 20,
              thisWeekWorkouts: 3,
              averageSessionDuration: 45,
              complianceRate: 85,
            },
          },
        ],
        isLoading: false,
        error: null,
        selectedStudentId: null,
        studentSessions: {},
      })

      mockFrom.mockImplementation(() => createChainableMock({ data: null, error: null }))

      await useStudentsStore.getState().assignDiet('student-1', undefined)

      const state = useStudentsStore.getState()
      expect(state.students[0].assignedDietId).toBeUndefined()
    })
  })

  describe('fetchStudentSessions', () => {
    it('should fetch student sessions successfully', async () => {
      const mockSessions = [
        {
          id: 'session-1',
          user_id: 'student-1',
          program_id: 'program-1',
          day_name: 'Jour A',
          started_at: '2024-12-20T09:00:00Z',
          completed_at: '2024-12-20T10:00:00Z',
          duration_minutes: 60,
          total_volume_kg: 5000,
          total_sets: 20,
          exercises: [],
          personal_records: [],
          notes: 'Great session',
        },
        {
          id: 'session-2',
          user_id: 'student-1',
          program_id: 'program-1',
          day_name: 'Jour B',
          started_at: '2024-12-19T09:00:00Z',
          completed_at: '2024-12-19T10:00:00Z',
          duration_minutes: 55,
          total_volume_kg: 4500,
          total_sets: 18,
          exercises: [],
          personal_records: [],
          notes: null,
        },
      ]

      mockFrom.mockImplementation(() => ({
        select: vi.fn().mockReturnThis(),
        eq: vi.fn().mockReturnThis(),
        not: vi.fn().mockReturnThis(),
        order: vi.fn().mockReturnThis(),
        limit: vi.fn().mockResolvedValue({ data: mockSessions, error: null }),
      }))

      const sessions = await useStudentsStore.getState().fetchStudentSessions('student-1')

      expect(sessions).toHaveLength(2)
      expect(sessions[0].id).toBe('session-1')
      expect(sessions[0].dayName).toBe('Jour A')
      expect(sessions[0].durationMinutes).toBe(60)

      const state = useStudentsStore.getState()
      expect(state.studentSessions['student-1']).toHaveLength(2)
    })

    it('should return empty array on error', async () => {
      mockFrom.mockImplementation(() => ({
        select: vi.fn().mockReturnThis(),
        eq: vi.fn().mockReturnThis(),
        not: vi.fn().mockReturnThis(),
        order: vi.fn().mockReturnThis(),
        limit: vi.fn().mockResolvedValue({ data: null, error: { message: 'Error' } }),
      }))

      const sessions = await useStudentsStore.getState().fetchStudentSessions('student-1')

      expect(sessions).toEqual([])
    })

    it('should use custom limit', async () => {
      const limitMock = vi.fn().mockResolvedValue({ data: [], error: null })

      mockFrom.mockImplementation(() => ({
        select: vi.fn().mockReturnThis(),
        eq: vi.fn().mockReturnThis(),
        not: vi.fn().mockReturnThis(),
        order: vi.fn().mockReturnThis(),
        limit: limitMock,
      }))

      await useStudentsStore.getState().fetchStudentSessions('student-1', 50)

      expect(limitMock).toHaveBeenCalledWith(50)
    })
  })
})
