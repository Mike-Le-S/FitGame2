import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth-store'

interface NotificationSettings {
  messages: boolean
  sessions: boolean
  alerts: boolean
  checkins: boolean
  weekly: boolean
}

interface SettingsState {
  notifications: NotificationSettings
  theme: 'dark' | 'light' | 'system'
  accentColor: string
  twoFactorEnabled: boolean
  updateNotifications: (settings: Partial<NotificationSettings>) => void
  setTheme: (theme: 'dark' | 'light' | 'system') => void
  setAccentColor: (color: string) => void
  setTwoFactorEnabled: (enabled: boolean) => void
  loadFromDB: () => Promise<void>
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      notifications: {
        messages: true,
        sessions: true,
        alerts: true,
        checkins: false,
        weekly: true,
      },
      theme: 'dark',
      accentColor: 'orange',
      twoFactorEnabled: false,

      updateNotifications: (settings) => {
        set((state) => ({
          notifications: { ...state.notifications, ...settings },
        }))
        // Sync the main toggle to profiles table
        if ('messages' in settings || 'sessions' in settings || 'alerts' in settings) {
          const coach = useAuthStore.getState().coach
          if (coach) {
            const allNotifs = { ...useSettingsStore.getState().notifications, ...settings }
            const anyEnabled = allNotifs.messages || allNotifs.sessions || allNotifs.alerts
            supabase.from('profiles').update({ notifications_enabled: anyEnabled }).eq('id', coach.id).then()
          }
        }
      },

      setTheme: (theme) => {
        set({ theme })
        const coach = useAuthStore.getState().coach
        if (coach) {
          supabase.from('coaches').update({ theme }).eq('id', coach.id).then()
        }
      },

      setAccentColor: (color) => {
        set({ accentColor: color })
        const coach = useAuthStore.getState().coach
        if (coach) {
          supabase.from('coaches').update({ accent_color: color }).eq('id', coach.id).then()
        }
      },

      setTwoFactorEnabled: (enabled) => {
        set({ twoFactorEnabled: enabled })
        const coach = useAuthStore.getState().coach
        if (coach) {
          supabase.from('coaches').update({ two_factor_enabled: enabled }).eq('id', coach.id).then()
        }
      },

      loadFromDB: async () => {
        const coach = useAuthStore.getState().coach
        if (!coach) return

        const { data: coachData } = await supabase
          .from('coaches')
          .select('theme, accent_color, two_factor_enabled')
          .eq('id', coach.id)
          .single()

        if (coachData) {
          set({
            theme: coachData.theme || 'dark',
            accentColor: coachData.accent_color || 'orange',
            twoFactorEnabled: coachData.two_factor_enabled || false,
          })
        }
      },
    }),
    {
      name: 'fitgame-settings',
    }
  )
)
