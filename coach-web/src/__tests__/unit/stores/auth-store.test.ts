import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// Mock the supabase module - must be before any imports that use it
vi.mock('@/lib/supabase', () => {
  const mockGetSession = vi.fn()
  const mockSignInWithPassword = vi.fn()
  const mockSignUp = vi.fn()
  const mockSignOut = vi.fn()
  const mockOnAuthStateChange = vi.fn(() => ({
    data: { subscription: { unsubscribe: vi.fn() } },
  }))
  const mockFrom = vi.fn()

  return {
    supabase: {
      auth: {
        getSession: mockGetSession,
        signInWithPassword: mockSignInWithPassword,
        signUp: mockSignUp,
        signOut: mockSignOut,
        onAuthStateChange: mockOnAuthStateChange,
      },
      from: mockFrom,
    },
    __mocks: {
      mockGetSession,
      mockSignInWithPassword,
      mockSignUp,
      mockSignOut,
      mockOnAuthStateChange,
      mockFrom,
    },
  }
})

// Import after mocking
import { useAuthStore } from '@/store/auth-store'
import { supabase } from '@/lib/supabase'

// Get the mocks
const mocks = (await import('@/lib/supabase')) as any
const mockGetSession = mocks.__mocks.mockGetSession
const mockSignInWithPassword = mocks.__mocks.mockSignInWithPassword
const mockSignUp = mocks.__mocks.mockSignUp
const mockSignOut = mocks.__mocks.mockSignOut
const mockFrom = mocks.__mocks.mockFrom

// Helper to reset store state
function resetStore() {
  useAuthStore.setState({
    coach: null,
    token: null,
    isAuthenticated: false,
    isLoading: true,
  })
}

// Create chainable mock for Supabase queries
function createChainableMock(resolvedValue: any) {
  const mock: any = {
    select: vi.fn().mockReturnThis(),
    insert: vi.fn().mockReturnThis(),
    update: vi.fn().mockReturnThis(),
    delete: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    single: vi.fn().mockResolvedValue(resolvedValue),
    order: vi.fn().mockReturnThis(),
    limit: vi.fn().mockReturnThis(),
    in: vi.fn().mockReturnThis(),
    not: vi.fn().mockReturnThis(),
  }
  return mock
}

describe('useAuthStore', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    resetStore()
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  describe('initial state', () => {
    it('should have correct initial state', () => {
      const state = useAuthStore.getState()
      expect(state.coach).toBeNull()
      expect(state.token).toBeNull()
      expect(state.isAuthenticated).toBe(false)
      expect(state.isLoading).toBe(true)
    })
  })

  describe('checkSession', () => {
    it('should set authenticated state when session exists with coach role', async () => {
      const mockSession = {
        user: { id: 'coach-123' },
        access_token: 'mock-token',
      }
      const mockProfile = {
        id: 'coach-123',
        full_name: 'Coach Test',
        email: 'coach@test.com',
        avatar_url: 'https://example.com/avatar.jpg',
        role: 'coach',
      }

      mockGetSession.mockResolvedValue({
        data: { session: mockSession },
        error: null,
      })

      mockFrom.mockImplementation((table: string) => {
        if (table === 'profiles') {
          return createChainableMock({ data: mockProfile, error: null })
        }
        return createChainableMock({ data: null, error: null })
      })

      await useAuthStore.getState().checkSession()

      const state = useAuthStore.getState()
      expect(state.isAuthenticated).toBe(true)
      expect(state.isLoading).toBe(false)
      expect(state.token).toBe('mock-token')
      expect(state.coach).toEqual({
        id: 'coach-123',
        name: 'Coach Test',
        email: 'coach@test.com',
        avatarUrl: 'https://example.com/avatar.jpg',
      })
    })

    it('should not authenticate if profile is not a coach', async () => {
      const mockSession = {
        user: { id: 'user-123' },
        access_token: 'mock-token',
      }
      const mockProfile = {
        id: 'user-123',
        full_name: 'Athlete Test',
        email: 'athlete@test.com',
        avatar_url: null,
        role: 'athlete',
      }

      mockGetSession.mockResolvedValue({
        data: { session: mockSession },
        error: null,
      })

      mockFrom.mockImplementation((table: string) => {
        if (table === 'profiles') {
          return createChainableMock({ data: mockProfile, error: null })
        }
        return createChainableMock({ data: null, error: null })
      })

      await useAuthStore.getState().checkSession()

      const state = useAuthStore.getState()
      expect(state.isAuthenticated).toBe(false)
      expect(state.isLoading).toBe(false)
      expect(state.coach).toBeNull()
    })

    it('should handle no session', async () => {
      mockGetSession.mockResolvedValue({
        data: { session: null },
        error: null,
      })

      await useAuthStore.getState().checkSession()

      const state = useAuthStore.getState()
      expect(state.isAuthenticated).toBe(false)
      expect(state.isLoading).toBe(false)
      expect(state.coach).toBeNull()
    })

    it('should handle error gracefully', async () => {
      mockGetSession.mockRejectedValue(new Error('Network error'))

      await useAuthStore.getState().checkSession()

      const state = useAuthStore.getState()
      expect(state.isAuthenticated).toBe(false)
      expect(state.isLoading).toBe(false)
      expect(state.coach).toBeNull()
    })
  })

  describe('login', () => {
    it('should login successfully with valid coach credentials', async () => {
      const mockAuthData = {
        user: { id: 'coach-123' },
        session: { access_token: 'mock-token' },
      }
      const mockProfile = {
        id: 'coach-123',
        full_name: 'Coach Test',
        email: 'coach@test.com',
        avatar_url: null,
        role: 'coach',
      }

      mockSignInWithPassword.mockResolvedValue({
        data: mockAuthData,
        error: null,
      })

      mockFrom.mockImplementation((table: string) => {
        if (table === 'profiles') {
          return createChainableMock({ data: mockProfile, error: null })
        }
        return createChainableMock({ data: null, error: null })
      })

      await useAuthStore.getState().login('coach@test.com', 'password123')

      const state = useAuthStore.getState()
      expect(state.isAuthenticated).toBe(true)
      expect(state.token).toBe('mock-token')
      expect(state.coach).toEqual({
        id: 'coach-123',
        name: 'Coach Test',
        email: 'coach@test.com',
        avatarUrl: undefined,
      })
    })

    it('should throw error for invalid credentials', async () => {
      mockSignInWithPassword.mockResolvedValue({
        data: { user: null, session: null },
        error: { message: 'Invalid login credentials' },
      })

      await expect(
        useAuthStore.getState().login('wrong@test.com', 'wrongpassword')
      ).rejects.toThrow('Email ou mot de passe incorrect')
    })

    it('should throw error when no user is returned', async () => {
      mockSignInWithPassword.mockResolvedValue({
        data: { user: null, session: null },
        error: null,
      })

      await expect(
        useAuthStore.getState().login('coach@test.com', 'password')
      ).rejects.toThrow('Connexion échouée')
    })

    it('should throw error if profile is not found', async () => {
      const mockAuthData = {
        user: { id: 'coach-123' },
        session: { access_token: 'mock-token' },
      }

      mockSignInWithPassword.mockResolvedValue({
        data: mockAuthData,
        error: null,
      })

      mockFrom.mockImplementation((table: string) => {
        if (table === 'profiles') {
          return createChainableMock({ data: null, error: { message: 'Not found' } })
        }
        return createChainableMock({ data: null, error: null })
      })
      mockSignOut.mockResolvedValue({ error: null })

      await expect(
        useAuthStore.getState().login('coach@test.com', 'password')
      ).rejects.toThrow('Profil non trouvé')

      expect(mockSignOut).toHaveBeenCalled()
    })

    it('should throw error if user is not a coach', async () => {
      const mockAuthData = {
        user: { id: 'athlete-123' },
        session: { access_token: 'mock-token' },
      }
      const mockProfile = {
        id: 'athlete-123',
        full_name: 'Athlete Test',
        email: 'athlete@test.com',
        avatar_url: null,
        role: 'athlete',
      }

      mockSignInWithPassword.mockResolvedValue({
        data: mockAuthData,
        error: null,
      })

      mockFrom.mockImplementation((table: string) => {
        if (table === 'profiles') {
          return createChainableMock({ data: mockProfile, error: null })
        }
        return createChainableMock({ data: null, error: null })
      })
      mockSignOut.mockResolvedValue({ error: null })

      await expect(
        useAuthStore.getState().login('athlete@test.com', 'password')
      ).rejects.toThrow("Ce compte n'est pas un compte coach. Utilisez l'application mobile.")

      expect(mockSignOut).toHaveBeenCalled()
    })
  })

  describe('signUp', () => {
    it('should sign up successfully and create profile', async () => {
      const mockAuthData = {
        user: { id: 'new-coach-123' },
        session: { access_token: 'mock-token' },
      }

      mockSignUp.mockResolvedValue({
        data: mockAuthData,
        error: null,
      })

      mockFrom.mockImplementation(() => {
        return createChainableMock({ data: null, error: null })
      })

      await useAuthStore.getState().signUp('newcoach@test.com', 'password123', 'New Coach')

      const state = useAuthStore.getState()
      expect(state.isAuthenticated).toBe(true)
      expect(state.token).toBe('mock-token')
      expect(state.coach).toEqual({
        id: 'new-coach-123',
        name: 'New Coach',
        email: 'newcoach@test.com',
        avatarUrl: undefined,
      })

      expect(mockSignUp).toHaveBeenCalledWith({
        email: 'newcoach@test.com',
        password: 'password123',
        options: {
          data: {
            full_name: 'New Coach',
            role: 'coach',
          },
        },
      })
    })

    it('should throw error if email is already registered', async () => {
      mockSignUp.mockResolvedValue({
        data: { user: null, session: null },
        error: { message: 'User already registered' },
      })

      await expect(
        useAuthStore.getState().signUp('existing@test.com', 'password', 'Name')
      ).rejects.toThrow('Cet email est déjà utilisé')
    })

    it('should throw error if signup fails', async () => {
      mockSignUp.mockResolvedValue({
        data: { user: null, session: null },
        error: null,
      })

      await expect(
        useAuthStore.getState().signUp('test@test.com', 'password', 'Name')
      ).rejects.toThrow('Inscription échouée')
    })

    it('should throw generic error for other signup errors', async () => {
      mockSignUp.mockResolvedValue({
        data: { user: null, session: null },
        error: { message: 'Some other error' },
      })

      await expect(
        useAuthStore.getState().signUp('test@test.com', 'password', 'Name')
      ).rejects.toThrow('Some other error')
    })
  })

  describe('logout', () => {
    it('should clear state on logout', async () => {
      // Set up authenticated state first
      useAuthStore.setState({
        coach: {
          id: 'coach-123',
          name: 'Coach Test',
          email: 'coach@test.com',
        },
        token: 'mock-token',
        isAuthenticated: true,
        isLoading: false,
      })

      mockSignOut.mockResolvedValue({ error: null })

      await useAuthStore.getState().logout()

      const state = useAuthStore.getState()
      expect(state.coach).toBeNull()
      expect(state.token).toBeNull()
      expect(state.isAuthenticated).toBe(false)
      expect(mockSignOut).toHaveBeenCalled()
    })
  })

  describe('updateProfile', () => {
    it('should update profile successfully', async () => {
      // Set up authenticated state
      useAuthStore.setState({
        coach: {
          id: 'coach-123',
          name: 'Old Name',
          email: 'old@test.com',
          avatarUrl: 'https://example.com/avatar.jpg',
        },
        token: 'mock-token',
        isAuthenticated: true,
        isLoading: false,
      })

      const chainMock = createChainableMock({ data: null, error: null })
      chainMock.eq = vi.fn().mockResolvedValue({ data: null, error: null })
      mockFrom.mockImplementation(() => chainMock)

      await useAuthStore.getState().updateProfile('New Name', 'new@test.com')

      const state = useAuthStore.getState()
      expect(state.coach?.name).toBe('New Name')
      expect(state.coach?.email).toBe('new@test.com')
      expect(state.coach?.avatarUrl).toBe('https://example.com/avatar.jpg')
    })

    it('should not update if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await useAuthStore.getState().updateProfile('New Name', 'new@test.com')

      // Should not throw, just return early
      expect(mockFrom).not.toHaveBeenCalled()
    })

    it('should throw error if update fails', async () => {
      useAuthStore.setState({
        coach: {
          id: 'coach-123',
          name: 'Old Name',
          email: 'old@test.com',
        },
        token: 'mock-token',
        isAuthenticated: true,
        isLoading: false,
      })

      const chainMock = createChainableMock({ data: null, error: null })
      chainMock.eq = vi.fn().mockResolvedValue({ data: null, error: { message: 'Update failed' } })
      mockFrom.mockImplementation(() => chainMock)

      await expect(
        useAuthStore.getState().updateProfile('New Name', 'new@test.com')
      ).rejects.toThrow('Erreur lors de la mise à jour')
    })
  })

  describe('persistence', () => {
    it('should persist coach, token, and isAuthenticated to localStorage', () => {
      useAuthStore.setState({
        coach: {
          id: 'coach-123',
          name: 'Coach Test',
          email: 'coach@test.com',
        },
        token: 'mock-token',
        isAuthenticated: true,
        isLoading: false,
      })

      // Trigger persist by getting the persisted state
      const persisted = localStorage.getItem('fitgame-coach-auth')
      expect(persisted).not.toBeNull()

      if (persisted) {
        const parsed = JSON.parse(persisted)
        expect(parsed.state.coach).toBeDefined()
        expect(parsed.state.token).toBe('mock-token')
        expect(parsed.state.isAuthenticated).toBe(true)
        // isLoading should not be persisted
        expect(parsed.state.isLoading).toBeUndefined()
      }
    })
  })
})
