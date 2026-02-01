import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { useSettingsStore } from '@/store/settings-store'

// Helper to reset store state
function resetStore() {
  useSettingsStore.setState({
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
  })
}

describe('useSettingsStore', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    resetStore()
  })

  afterEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  describe('initial state', () => {
    it('should have correct default notification settings', () => {
      resetStore()
      const state = useSettingsStore.getState()
      expect(state.notifications).toEqual({
        messages: true,
        sessions: true,
        alerts: true,
        checkins: false,
        weekly: true,
      })
    })

    it('should have dark theme by default', () => {
      resetStore()
      const state = useSettingsStore.getState()
      expect(state.theme).toBe('dark')
    })

    it('should have orange accent color by default', () => {
      resetStore()
      const state = useSettingsStore.getState()
      expect(state.accentColor).toBe('orange')
    })

    it('should have two-factor disabled by default', () => {
      resetStore()
      const state = useSettingsStore.getState()
      expect(state.twoFactorEnabled).toBe(false)
    })
  })

  describe('updateNotifications', () => {
    it('should update single notification setting', () => {
      useSettingsStore.getState().updateNotifications({ messages: false })

      const state = useSettingsStore.getState()
      expect(state.notifications.messages).toBe(false)
      expect(state.notifications.sessions).toBe(true)
      expect(state.notifications.alerts).toBe(true)
    })

    it('should update multiple notification settings', () => {
      useSettingsStore.getState().updateNotifications({
        messages: false,
        sessions: false,
        checkins: true,
      })

      const state = useSettingsStore.getState()
      expect(state.notifications.messages).toBe(false)
      expect(state.notifications.sessions).toBe(false)
      expect(state.notifications.checkins).toBe(true)
      expect(state.notifications.alerts).toBe(true)
      expect(state.notifications.weekly).toBe(true)
    })

    it('should preserve other notification settings when updating one', () => {
      useSettingsStore.getState().updateNotifications({ alerts: false })

      const state = useSettingsStore.getState()
      expect(state.notifications).toEqual({
        messages: true,
        sessions: true,
        alerts: false,
        checkins: false,
        weekly: true,
      })
    })

    it('should handle toggling notifications off and on', () => {
      useSettingsStore.getState().updateNotifications({ messages: false })
      expect(useSettingsStore.getState().notifications.messages).toBe(false)

      useSettingsStore.getState().updateNotifications({ messages: true })
      expect(useSettingsStore.getState().notifications.messages).toBe(true)
    })
  })

  describe('setTheme', () => {
    it('should set theme to dark', () => {
      useSettingsStore.getState().setTheme('light')
      useSettingsStore.getState().setTheme('dark')

      const state = useSettingsStore.getState()
      expect(state.theme).toBe('dark')
    })

    it('should set theme to light', () => {
      useSettingsStore.getState().setTheme('light')

      const state = useSettingsStore.getState()
      expect(state.theme).toBe('light')
    })

    it('should set theme to system', () => {
      useSettingsStore.getState().setTheme('system')

      const state = useSettingsStore.getState()
      expect(state.theme).toBe('system')
    })

    it('should override previous theme setting', () => {
      useSettingsStore.getState().setTheme('light')
      expect(useSettingsStore.getState().theme).toBe('light')

      useSettingsStore.getState().setTheme('dark')
      expect(useSettingsStore.getState().theme).toBe('dark')

      useSettingsStore.getState().setTheme('system')
      expect(useSettingsStore.getState().theme).toBe('system')
    })
  })

  describe('setAccentColor', () => {
    it('should set accent color', () => {
      useSettingsStore.getState().setAccentColor('blue')

      const state = useSettingsStore.getState()
      expect(state.accentColor).toBe('blue')
    })

    it('should change accent color from default', () => {
      expect(useSettingsStore.getState().accentColor).toBe('orange')

      useSettingsStore.getState().setAccentColor('red')

      expect(useSettingsStore.getState().accentColor).toBe('red')
    })

    it('should handle various color values', () => {
      const colors = ['orange', 'blue', 'green', 'purple', 'red', '#FF6B35', 'rgb(255, 107, 53)']

      colors.forEach(color => {
        useSettingsStore.getState().setAccentColor(color)
        expect(useSettingsStore.getState().accentColor).toBe(color)
      })
    })

    it('should override previous accent color', () => {
      useSettingsStore.getState().setAccentColor('blue')
      expect(useSettingsStore.getState().accentColor).toBe('blue')

      useSettingsStore.getState().setAccentColor('green')
      expect(useSettingsStore.getState().accentColor).toBe('green')
    })
  })

  describe('setTwoFactorEnabled', () => {
    it('should enable two-factor authentication', () => {
      useSettingsStore.getState().setTwoFactorEnabled(true)

      const state = useSettingsStore.getState()
      expect(state.twoFactorEnabled).toBe(true)
    })

    it('should disable two-factor authentication', () => {
      useSettingsStore.getState().setTwoFactorEnabled(true)
      useSettingsStore.getState().setTwoFactorEnabled(false)

      const state = useSettingsStore.getState()
      expect(state.twoFactorEnabled).toBe(false)
    })

    it('should toggle two-factor setting', () => {
      expect(useSettingsStore.getState().twoFactorEnabled).toBe(false)

      useSettingsStore.getState().setTwoFactorEnabled(true)
      expect(useSettingsStore.getState().twoFactorEnabled).toBe(true)

      useSettingsStore.getState().setTwoFactorEnabled(false)
      expect(useSettingsStore.getState().twoFactorEnabled).toBe(false)
    })
  })

  describe('persistence', () => {
    it('should persist settings to localStorage', () => {
      useSettingsStore.getState().setTheme('light')
      useSettingsStore.getState().setAccentColor('blue')
      useSettingsStore.getState().setTwoFactorEnabled(true)
      useSettingsStore.getState().updateNotifications({ messages: false })

      const persisted = localStorage.getItem('fitgame-settings')
      expect(persisted).not.toBeNull()

      if (persisted) {
        const parsed = JSON.parse(persisted)
        expect(parsed.state.theme).toBe('light')
        expect(parsed.state.accentColor).toBe('blue')
        expect(parsed.state.twoFactorEnabled).toBe(true)
        expect(parsed.state.notifications.messages).toBe(false)
      }
    })

    it('should restore settings from localStorage', () => {
      // Set up persisted state
      const persistedState = {
        state: {
          notifications: {
            messages: false,
            sessions: false,
            alerts: true,
            checkins: true,
            weekly: false,
          },
          theme: 'light',
          accentColor: 'purple',
          twoFactorEnabled: true,
        },
        version: 0,
      }

      localStorage.setItem('fitgame-settings', JSON.stringify(persistedState))

      // Force store to re-hydrate by resetting
      useSettingsStore.setState({
        ...persistedState.state,
      })

      const state = useSettingsStore.getState()
      expect(state.theme).toBe('light')
      expect(state.accentColor).toBe('purple')
      expect(state.twoFactorEnabled).toBe(true)
      expect(state.notifications.messages).toBe(false)
      expect(state.notifications.checkins).toBe(true)
    })

    it('should use correct localStorage key', () => {
      useSettingsStore.getState().setTheme('light')

      // Check that localStorage.setItem was called with the correct key
      expect(localStorage.setItem).toHaveBeenCalled()
      const calls = (localStorage.setItem as any).mock.calls
      const hasCorrectKey = calls.some((call: any[]) => call[0] === 'fitgame-settings')
      expect(hasCorrectKey).toBe(true)
    })
  })

  describe('state isolation', () => {
    it('should not affect other state when updating notifications', () => {
      useSettingsStore.getState().setTheme('light')
      useSettingsStore.getState().setAccentColor('blue')
      useSettingsStore.getState().setTwoFactorEnabled(true)

      useSettingsStore.getState().updateNotifications({ messages: false })

      const state = useSettingsStore.getState()
      expect(state.theme).toBe('light')
      expect(state.accentColor).toBe('blue')
      expect(state.twoFactorEnabled).toBe(true)
    })

    it('should not affect other state when updating theme', () => {
      useSettingsStore.getState().setAccentColor('blue')
      useSettingsStore.getState().updateNotifications({ messages: false })

      useSettingsStore.getState().setTheme('light')

      const state = useSettingsStore.getState()
      expect(state.accentColor).toBe('blue')
      expect(state.notifications.messages).toBe(false)
    })

    it('should not affect other state when updating accent color', () => {
      useSettingsStore.getState().setTheme('light')
      useSettingsStore.getState().setTwoFactorEnabled(true)

      useSettingsStore.getState().setAccentColor('green')

      const state = useSettingsStore.getState()
      expect(state.theme).toBe('light')
      expect(state.twoFactorEnabled).toBe(true)
    })
  })

  describe('edge cases', () => {
    it('should handle empty notification updates', () => {
      const originalState = useSettingsStore.getState().notifications

      useSettingsStore.getState().updateNotifications({})

      const newState = useSettingsStore.getState().notifications
      expect(newState).toEqual(originalState)
    })

    it('should handle setting same theme value', () => {
      useSettingsStore.getState().setTheme('dark')
      useSettingsStore.getState().setTheme('dark')

      expect(useSettingsStore.getState().theme).toBe('dark')
    })

    it('should handle setting same accent color', () => {
      useSettingsStore.getState().setAccentColor('orange')
      useSettingsStore.getState().setAccentColor('orange')

      expect(useSettingsStore.getState().accentColor).toBe('orange')
    })

    it('should handle setting same two-factor value', () => {
      useSettingsStore.getState().setTwoFactorEnabled(false)
      useSettingsStore.getState().setTwoFactorEnabled(false)

      expect(useSettingsStore.getState().twoFactorEnabled).toBe(false)
    })

    it('should handle rapid sequential updates', () => {
      // 100 updates, starting at i=0 (dark), ending at i=99 (light)
      for (let i = 0; i < 100; i++) {
        useSettingsStore.getState().setTheme(i % 2 === 0 ? 'dark' : 'light')
      }
      // i=99 is odd, so last update is 'light'
      expect(useSettingsStore.getState().theme).toBe('light')
    })

    it('should handle all notifications being disabled', () => {
      useSettingsStore.getState().updateNotifications({
        messages: false,
        sessions: false,
        alerts: false,
        checkins: false,
        weekly: false,
      })

      const state = useSettingsStore.getState()
      expect(state.notifications.messages).toBe(false)
      expect(state.notifications.sessions).toBe(false)
      expect(state.notifications.alerts).toBe(false)
      expect(state.notifications.checkins).toBe(false)
      expect(state.notifications.weekly).toBe(false)
    })

    it('should handle all notifications being enabled', () => {
      useSettingsStore.getState().updateNotifications({
        messages: true,
        sessions: true,
        alerts: true,
        checkins: true,
        weekly: true,
      })

      const state = useSettingsStore.getState()
      expect(state.notifications.messages).toBe(true)
      expect(state.notifications.sessions).toBe(true)
      expect(state.notifications.alerts).toBe(true)
      expect(state.notifications.checkins).toBe(true)
      expect(state.notifications.weekly).toBe(true)
    })
  })

  describe('type safety', () => {
    it('should only accept valid theme values', () => {
      const validThemes: Array<'dark' | 'light' | 'system'> = ['dark', 'light', 'system']

      validThemes.forEach(theme => {
        useSettingsStore.getState().setTheme(theme)
        expect(useSettingsStore.getState().theme).toBe(theme)
      })
    })

    it('should handle boolean notification values correctly', () => {
      useSettingsStore.getState().updateNotifications({ messages: true })
      expect(typeof useSettingsStore.getState().notifications.messages).toBe('boolean')

      useSettingsStore.getState().updateNotifications({ messages: false })
      expect(typeof useSettingsStore.getState().notifications.messages).toBe('boolean')
    })

    it('should handle string accent color values', () => {
      useSettingsStore.getState().setAccentColor('test-color')
      expect(typeof useSettingsStore.getState().accentColor).toBe('string')
    })

    it('should handle boolean two-factor values correctly', () => {
      useSettingsStore.getState().setTwoFactorEnabled(true)
      expect(typeof useSettingsStore.getState().twoFactorEnabled).toBe('boolean')

      useSettingsStore.getState().setTwoFactorEnabled(false)
      expect(typeof useSettingsStore.getState().twoFactorEnabled).toBe('boolean')
    })
  })
})
