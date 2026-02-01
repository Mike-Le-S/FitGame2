import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { supabase, type Profile } from '@/lib/supabase'
import type { Coach } from '@/types'

interface AuthState {
  coach: Coach | null
  token: string | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (email: string, password: string) => Promise<void>
  loginWithGoogle: () => Promise<void>
  signUp: (email: string, password: string, fullName: string) => Promise<void>
  logout: () => Promise<void>
  updateProfile: (name: string, email: string) => Promise<void>
  checkSession: () => Promise<void>
}

// Transform database profile to Coach type
function profileToCoach(profile: Profile): Coach {
  return {
    id: profile.id,
    name: profile.full_name,
    email: profile.email,
    avatarUrl: profile.avatar_url || undefined,
  }
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      coach: null,
      token: null,
      isAuthenticated: false,
      isLoading: true,

      checkSession: async () => {
        try {
          const { data: { session } } = await supabase.auth.getSession()

          if (session?.user) {
            // Fetch profile
            const { data: profile } = await supabase
              .from('profiles')
              .select('*')
              .eq('id', session.user.id)
              .single()

            if (profile && profile.role === 'coach') {
              set({
                coach: profileToCoach(profile),
                token: session.access_token,
                isAuthenticated: true,
                isLoading: false,
              })
              return
            }
          }

          set({
            coach: null,
            token: null,
            isAuthenticated: false,
            isLoading: false,
          })
        } catch {
          set({
            coach: null,
            token: null,
            isAuthenticated: false,
            isLoading: false,
          })
        }
      },

      login: async (email: string, password: string) => {
        const { data, error } = await supabase.auth.signInWithPassword({
          email,
          password,
        })

        if (error) {
          throw new Error(error.message === 'Invalid login credentials'
            ? 'Email ou mot de passe incorrect'
            : error.message
          )
        }

        if (!data.user) {
          throw new Error('Connexion échouée')
        }

        // Fetch profile to verify it's a coach
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', data.user.id)
          .single()

        if (profileError || !profile) {
          await supabase.auth.signOut()
          throw new Error('Profil non trouvé')
        }

        if (profile.role !== 'coach') {
          await supabase.auth.signOut()
          throw new Error('Ce compte n\'est pas un compte coach. Utilisez l\'application mobile.')
        }

        set({
          coach: profileToCoach(profile),
          token: data.session?.access_token || null,
          isAuthenticated: true,
        })
      },

      loginWithGoogle: async () => {
        const { error } = await supabase.auth.signInWithOAuth({
          provider: 'google',
          options: {
            redirectTo: window.location.origin,
          },
        })

        if (error) {
          throw new Error('Erreur de connexion Google')
        }
        // After OAuth redirect, checkSession will be called by onAuthStateChange
      },

      signUp: async (email: string, password: string, fullName: string) => {
        const { data, error } = await supabase.auth.signUp({
          email,
          password,
          options: {
            data: {
              full_name: fullName,
              role: 'coach',
            },
          },
        })

        if (error) {
          if (error.message.includes('already registered')) {
            throw new Error('Cet email est déjà utilisé')
          }
          throw new Error(error.message)
        }

        if (!data.user) {
          throw new Error('Inscription échouée')
        }

        // Create profile
        const { error: profileError } = await supabase
          .from('profiles')
          .insert({
            id: data.user.id,
            email,
            full_name: fullName,
            role: 'coach',
          })

        if (profileError) {
          console.error('Profile creation error:', profileError)
        }

        // Create coach details
        const { error: coachError } = await supabase
          .from('coaches')
          .insert({
            id: data.user.id,
          })

        if (coachError) {
          console.error('Coach details creation error:', coachError)
        }

        // Auto login after signup
        set({
          coach: {
            id: data.user.id,
            name: fullName,
            email,
            avatarUrl: undefined,
          },
          token: data.session?.access_token || null,
          isAuthenticated: true,
        })
      },

      logout: async () => {
        await supabase.auth.signOut()
        set({
          coach: null,
          token: null,
          isAuthenticated: false,
        })
      },

      updateProfile: async (name: string, email: string) => {
        const { coach } = get()
        if (!coach) return

        // Update profile in database
        const { error } = await supabase
          .from('profiles')
          .update({
            full_name: name,
            email,
          })
          .eq('id', coach.id)

        if (error) {
          throw new Error('Erreur lors de la mise à jour')
        }

        set({
          coach: { ...coach, name, email },
        })
      },
    }),
    {
      name: 'fitgame-coach-auth',
      partialize: (state) => ({
        // Only persist these fields
        coach: state.coach,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
)

// Initialize auth state on app load
supabase.auth.onAuthStateChange(async (event, session) => {
  if (event === 'SIGNED_OUT') {
    useAuthStore.getState().logout()
  } else if (event === 'SIGNED_IN' && session) {
    useAuthStore.getState().checkSession()
  }
})
