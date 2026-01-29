import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { Coach } from '@/types'

interface AuthState {
  coach: Coach | null
  token: string | null
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

// Mock coach data
const mockCoach: Coach = {
  id: 'coach-1',
  name: 'Jean Dupont',
  email: 'coach@fitgame.app',
  avatarUrl: undefined,
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      coach: null,
      token: null,
      isAuthenticated: false,

      login: async (email: string, _password: string) => {
        // Simulate API call
        await new Promise((resolve) => setTimeout(resolve, 500))

        if (email === 'coach@fitgame.app') {
          set({
            coach: mockCoach,
            token: 'mock-jwt-token',
            isAuthenticated: true,
          })
        } else {
          throw new Error('Email ou mot de passe incorrect')
        }
      },

      logout: () => {
        set({
          coach: null,
          token: null,
          isAuthenticated: false,
        })
      },
    }),
    {
      name: 'fitgame-coach-auth',
    }
  )
)
