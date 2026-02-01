import { create } from 'zustand'
import { persist } from 'zustand/middleware'

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

      updateNotifications: (settings) =>
        set((state) => ({
          notifications: { ...state.notifications, ...settings },
        })),

      setTheme: (theme) => set({ theme }),

      setAccentColor: (color) => set({ accentColor: color }),

      setTwoFactorEnabled: (enabled) => set({ twoFactorEnabled: enabled }),
    }),
    {
      name: 'fitgame-settings',
    }
  )
)
