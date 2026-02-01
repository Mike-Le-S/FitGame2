// Browser Notifications Service

export type NotificationPermission = 'granted' | 'denied' | 'default'

export interface NotificationOptions {
  title: string
  body: string
  icon?: string
  tag?: string
  onClick?: () => void
}

class NotificationService {
  private permission: NotificationPermission = 'default'

  constructor() {
    if (typeof window !== 'undefined' && 'Notification' in window) {
      this.permission = Notification.permission as NotificationPermission
    }
  }

  isSupported(): boolean {
    return typeof window !== 'undefined' && 'Notification' in window
  }

  getPermission(): NotificationPermission {
    return this.permission
  }

  async requestPermission(): Promise<NotificationPermission> {
    if (!this.isSupported()) {
      return 'denied'
    }

    try {
      const result = await Notification.requestPermission()
      this.permission = result as NotificationPermission
      return this.permission
    } catch (error) {
      console.error('Error requesting notification permission:', error)
      return 'denied'
    }
  }

  show(options: NotificationOptions): Notification | null {
    if (!this.isSupported() || this.permission !== 'granted') {
      return null
    }

    try {
      const notification = new Notification(options.title, {
        body: options.body,
        icon: options.icon || '/favicon.ico',
        tag: options.tag,
        badge: '/favicon.ico',
      })

      if (options.onClick) {
        notification.onclick = () => {
          window.focus()
          options.onClick?.()
          notification.close()
        }
      }

      // Auto-close after 5 seconds
      setTimeout(() => notification.close(), 5000)

      return notification
    } catch (error) {
      console.error('Error showing notification:', error)
      return null
    }
  }

  // Show message notification
  showMessageNotification(senderName: string, messagePreview: string, onClick?: () => void): Notification | null {
    return this.show({
      title: `Nouveau message de ${senderName}`,
      body: messagePreview.length > 100 ? messagePreview.slice(0, 100) + '...' : messagePreview,
      tag: 'message',
      onClick,
    })
  }

  // Show session notification
  showSessionNotification(studentName: string, sessionType: string, onClick?: () => void): Notification | null {
    return this.show({
      title: `Séance complétée`,
      body: `${studentName} a terminé sa séance ${sessionType}`,
      tag: 'session',
      onClick,
    })
  }
}

export const notificationService = new NotificationService()
