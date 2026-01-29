import { useState, useRef, useEffect } from 'react'
import { Bell, Search, Command, X, Sparkles } from 'lucide-react'
import { cn } from '@/lib/utils'

interface HeaderProps {
  title: string
  subtitle?: string
  action?: React.ReactNode
}

export function Header({ title, subtitle, action }: HeaderProps) {
  const [searchFocused, setSearchFocused] = useState(false)
  const [searchValue, setSearchValue] = useState('')
  const [showNotifications, setShowNotifications] = useState(false)
  const searchRef = useRef<HTMLInputElement>(null)
  const notifRef = useRef<HTMLDivElement>(null)

  // Mock notifications
  const notifications = [
    { id: 1, title: 'Nouvelle séance complétée', desc: 'Marie Laurent a terminé Push A', time: 'Il y a 5min', unread: true },
    { id: 2, title: 'Alerte compliance', desc: 'Emma Dubois - 0 séance cette semaine', time: 'Il y a 1h', unread: true },
    { id: 3, title: 'Message reçu', desc: 'Thomas Bernard vous a envoyé un message', time: 'Il y a 2h', unread: false },
  ]

  const unreadCount = notifications.filter(n => n.unread).length

  // Close notifications on outside click
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (notifRef.current && !notifRef.current.contains(event.target as Node)) {
        setShowNotifications(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  // Keyboard shortcut for search
  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if ((event.metaKey || event.ctrlKey) && event.key === 'k') {
        event.preventDefault()
        searchRef.current?.focus()
      }
      if (event.key === 'Escape') {
        searchRef.current?.blur()
        setSearchFocused(false)
      }
    }
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [])

  return (
    <header className="sticky top-0 z-40 backdrop-blur-xl">
      {/* Gradient border bottom */}
      <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-border to-transparent" />

      {/* Background */}
      <div className="absolute inset-0 bg-background/80" />

      <div className="relative h-[72px] px-8 flex items-center justify-between">
        {/* Left: Title section */}
        <div className="flex flex-col gap-0.5">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-text-primary tracking-tight">
              {title}
            </h1>
            {/* Status indicator */}
            <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-success/10 border border-success/20">
              <div className="w-1.5 h-1.5 rounded-full bg-success animate-pulse" />
              <span className="text-[10px] font-semibold uppercase tracking-wider text-success">
                En ligne
              </span>
            </div>
          </div>
          {subtitle && (
            <p className="text-sm text-text-secondary">{subtitle}</p>
          )}
        </div>

        {/* Right: Actions */}
        <div className="flex items-center gap-3">
          {/* Search box */}
          <div className="relative">
            <div className={cn(
              'relative flex items-center transition-all duration-300',
              searchFocused ? 'w-80' : 'w-64'
            )}>
              {/* Search glow effect */}
              {searchFocused && (
                <div className="absolute inset-0 bg-accent/10 blur-xl rounded-xl" />
              )}

              {/* Search input container */}
              <div className={cn(
                'relative w-full flex items-center gap-2 px-4 h-11 rounded-xl',
                'bg-surface-elevated border transition-all duration-300',
                searchFocused
                  ? 'border-accent/50 shadow-[0_0_20px_rgba(255,107,53,0.15)]'
                  : 'border-border hover:border-border-subtle'
              )}>
                <Search className={cn(
                  'w-4 h-4 transition-colors duration-300',
                  searchFocused ? 'text-accent' : 'text-text-muted'
                )} />

                <input
                  ref={searchRef}
                  type="text"
                  placeholder="Rechercher un élève, programme..."
                  value={searchValue}
                  onChange={(e) => setSearchValue(e.target.value)}
                  onFocus={() => setSearchFocused(true)}
                  onBlur={() => setSearchFocused(false)}
                  className="flex-1 bg-transparent text-sm text-text-primary placeholder:text-text-muted outline-none"
                />

                {searchValue ? (
                  <button
                    onClick={() => setSearchValue('')}
                    className="p-1 rounded-md hover:bg-surface text-text-muted hover:text-text-secondary transition-colors"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                ) : (
                  <div className="flex items-center gap-1 px-1.5 py-0.5 rounded-md bg-surface border border-border">
                    <Command className="w-3 h-3 text-text-muted" />
                    <span className="text-[10px] text-text-muted font-medium">K</span>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Divider */}
          <div className="w-px h-8 bg-border" />

          {/* AI Assistant button (decorative) */}
          <button className={cn(
            'relative group flex items-center gap-2 px-4 h-11 rounded-xl',
            'bg-gradient-to-r from-accent/10 to-transparent',
            'border border-accent/20 hover:border-accent/40',
            'transition-all duration-300'
          )}>
            <div className="absolute inset-0 bg-accent/5 opacity-0 group-hover:opacity-100 rounded-xl transition-opacity duration-300" />
            <Sparkles className="relative w-4 h-4 text-accent" />
            <span className="relative text-sm font-medium text-accent">IA Coach</span>
          </button>

          {/* Notifications */}
          <div className="relative" ref={notifRef}>
            <button
              onClick={() => setShowNotifications(!showNotifications)}
              className={cn(
                'relative p-3 rounded-xl transition-all duration-300',
                'hover:bg-surface-elevated',
                showNotifications && 'bg-surface-elevated'
              )}
            >
              <Bell className={cn(
                'w-5 h-5 transition-colors',
                showNotifications ? 'text-accent' : 'text-text-secondary hover:text-text-primary'
              )} />

              {/* Notification badge */}
              {unreadCount > 0 && (
                <span className={cn(
                  'absolute top-2 right-2 min-w-[18px] h-[18px] px-1',
                  'flex items-center justify-center',
                  'text-[10px] font-bold text-white',
                  'bg-accent rounded-full',
                  'shadow-[0_0_10px_rgba(255,107,53,0.5)]',
                  'animate-pulse'
                )}>
                  {unreadCount}
                </span>
              )}
            </button>

            {/* Notifications dropdown */}
            {showNotifications && (
              <div className={cn(
                'absolute top-full right-0 mt-2 w-80',
                'bg-surface border border-border rounded-xl',
                'shadow-2xl shadow-black/50',
                'overflow-hidden',
                'animate-[fadeIn_0.2s_ease-out]'
              )}>
                {/* Header */}
                <div className="flex items-center justify-between px-4 py-3 border-b border-border">
                  <span className="text-sm font-semibold text-text-primary">Notifications</span>
                  <button className="text-xs text-accent hover:text-accent-hover transition-colors">
                    Tout marquer lu
                  </button>
                </div>

                {/* Notifications list */}
                <div className="max-h-80 overflow-y-auto">
                  {notifications.map((notif, index) => (
                    <div
                      key={notif.id}
                      className={cn(
                        'relative px-4 py-3 hover:bg-surface-elevated transition-colors cursor-pointer',
                        index !== notifications.length - 1 && 'border-b border-border/50'
                      )}
                    >
                      {notif.unread && (
                        <div className="absolute left-2 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-accent" />
                      )}
                      <p className={cn(
                        'text-sm mb-0.5',
                        notif.unread ? 'text-text-primary font-medium' : 'text-text-secondary'
                      )}>
                        {notif.title}
                      </p>
                      <p className="text-xs text-text-muted mb-1">{notif.desc}</p>
                      <p className="text-[10px] text-text-muted">{notif.time}</p>
                    </div>
                  ))}
                </div>

                {/* Footer */}
                <div className="px-4 py-3 border-t border-border bg-surface-elevated/50">
                  <button className="w-full text-center text-sm text-accent hover:text-accent-hover transition-colors">
                    Voir toutes les notifications
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Action button */}
          {action}
        </div>
      </div>
    </header>
  )
}
