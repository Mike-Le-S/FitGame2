import { NavLink, useLocation } from 'react-router-dom'
import {
  LayoutDashboard,
  Users,
  Dumbbell,
  Apple,
  MessageSquare,
  Settings,
  LogOut,
  ChevronRight,
  X,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/store/auth-store'
import { Avatar } from '@/components/ui'

const navItems = [
  { path: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { path: '/students', icon: Users, label: 'Élèves' },
  { path: '/programs', icon: Dumbbell, label: 'Programmes' },
  { path: '/nutrition', icon: Apple, label: 'Nutrition' },
  { path: '/messages', icon: MessageSquare, label: 'Messages', badge: 3 },
]

interface SidebarProps {
  isOpen: boolean
  onClose: () => void
}

export function Sidebar({ isOpen, onClose }: SidebarProps) {
  const location = useLocation()
  const { coach, logout } = useAuthStore()

  return (
    <aside
      className={cn(
        'fixed left-0 top-0 h-screen w-72 flex flex-col z-50',
        'transition-transform duration-300 ease-out',
        isOpen ? 'translate-x-0' : '-translate-x-full'
      )}
    >
      {/* Background with subtle gradient */}
      <div className="absolute inset-0 bg-surface border-r border-border">
        {/* Subtle accent glow at top */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-48 h-48 bg-accent/5 blur-[100px] rounded-full" />
      </div>

      {/* Content */}
      <div className="relative flex flex-col h-full">
        {/* Logo Section */}
        <div className="h-20 px-6 flex items-center justify-between">
          <div className="flex items-center gap-3 group cursor-pointer">
            {/* Animated logo container */}
            <div className="relative">
              <div className="absolute inset-0 bg-accent/20 blur-xl rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
              <div className="relative w-11 h-11 rounded-xl bg-gradient-to-br from-accent to-[#ff8f5c] flex items-center justify-center shadow-lg shadow-accent/25">
                <Dumbbell className="w-6 h-6 text-white" />
              </div>
            </div>
            <div className="flex flex-col">
              <span className="text-xl font-bold tracking-tight text-text-primary">
                Fit<span className="text-accent">Game</span>
              </span>
              <span className="text-[10px] uppercase tracking-[0.2em] text-text-muted font-medium">
                Coach Pro
              </span>
            </div>
          </div>

          {/* Close button */}
          <button
            onClick={onClose}
            className={cn(
              'p-2 rounded-lg',
              'text-text-muted hover:text-text-primary',
              'hover:bg-surface-elevated transition-all'
            )}
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-3 py-2 overflow-y-auto">
          <div className="mb-3 px-3">
            <span className="text-[10px] uppercase tracking-[0.15em] text-text-muted font-semibold">
              Menu principal
            </span>
          </div>

          <ul className="space-y-1">
            {navItems.map((item, index) => {
              const isActive =
                item.path === '/'
                  ? location.pathname === '/'
                  : location.pathname.startsWith(item.path)

              return (
                <li
                  key={item.path}
                  style={{
                    animationDelay: `${index * 50}ms`,
                  }}
                  className="animate-[fadeSlideIn_0.4s_ease-out_forwards] opacity-0"
                >
                  <NavLink
                    to={item.path}
                    className={cn(
                      'group relative flex items-center gap-3 px-3 py-3 rounded-xl',
                      'text-sm font-medium transition-all duration-300',
                      isActive
                        ? 'text-white'
                        : 'text-text-secondary hover:text-text-primary'
                    )}
                  >
                    {/* Active background with glow */}
                    {isActive && (
                      <>
                        <div className="absolute inset-0 bg-gradient-to-r from-accent/20 via-accent/10 to-transparent rounded-xl" />
                        <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 bg-accent rounded-r-full shadow-[0_0_12px_rgba(255,107,53,0.5)]" />
                      </>
                    )}

                    {/* Hover background */}
                    <div className={cn(
                      'absolute inset-0 rounded-xl transition-all duration-300',
                      !isActive && 'group-hover:bg-surface-elevated'
                    )} />

                    {/* Icon container */}
                    <div className={cn(
                      'relative w-9 h-9 rounded-lg flex items-center justify-center transition-all duration-300',
                      isActive
                        ? 'bg-accent/20'
                        : 'bg-surface-elevated group-hover:bg-[#252525]'
                    )}>
                      <item.icon
                        className={cn(
                          'w-[18px] h-[18px] transition-all duration-300',
                          isActive
                            ? 'text-accent'
                            : 'text-text-muted group-hover:text-text-secondary'
                        )}
                      />
                    </div>

                    {/* Label */}
                    <span className="relative flex-1">{item.label}</span>

                    {/* Badge or chevron */}
                    {item.badge ? (
                      <span className={cn(
                        'relative px-2 py-0.5 rounded-full text-xs font-semibold',
                        'bg-accent text-white',
                        'shadow-[0_0_10px_rgba(255,107,53,0.4)]',
                        'animate-pulse'
                      )}>
                        {item.badge}
                      </span>
                    ) : (
                      <ChevronRight className={cn(
                        'relative w-4 h-4 transition-all duration-300',
                        isActive
                          ? 'text-accent opacity-100'
                          : 'text-text-muted opacity-0 group-hover:opacity-100 group-hover:translate-x-1'
                      )} />
                    )}
                  </NavLink>
                </li>
              )
            })}
          </ul>
        </nav>

        {/* Bottom section */}
        <div className="p-3 border-t border-border/50">
          {/* Settings link */}
          <NavLink
            to="/settings"
            className={cn(
              'group relative flex items-center gap-3 px-3 py-3 rounded-xl mb-3',
              'text-sm font-medium transition-all duration-300',
              location.pathname === '/settings'
                ? 'text-white'
                : 'text-text-secondary hover:text-text-primary'
            )}
          >
            {location.pathname === '/settings' && (
              <>
                <div className="absolute inset-0 bg-gradient-to-r from-accent/20 via-accent/10 to-transparent rounded-xl" />
                <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 bg-accent rounded-r-full shadow-[0_0_12px_rgba(255,107,53,0.5)]" />
              </>
            )}
            <div className={cn(
              'absolute inset-0 rounded-xl transition-all duration-300',
              location.pathname !== '/settings' && 'group-hover:bg-surface-elevated'
            )} />
            <div className={cn(
              'relative w-9 h-9 rounded-lg flex items-center justify-center transition-all duration-300',
              location.pathname === '/settings'
                ? 'bg-accent/20'
                : 'bg-surface-elevated group-hover:bg-[#252525]'
            )}>
              <Settings className={cn(
                'w-[18px] h-[18px] transition-all duration-300',
                location.pathname === '/settings'
                  ? 'text-accent'
                  : 'text-text-muted group-hover:text-text-secondary group-hover:rotate-45'
              )} />
            </div>
            <span className="relative">Paramètres</span>
          </NavLink>

          {/* User profile card */}
          <div className="relative group">
            <div className="absolute inset-0 bg-gradient-to-r from-accent/5 via-transparent to-transparent rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
            <div className="relative flex items-center gap-3 p-3 rounded-xl bg-surface-elevated/50 border border-border/50 backdrop-blur-sm">
              {/* Avatar with status indicator */}
              <div className="relative">
                <Avatar name={coach?.name || 'Coach'} size="md" />
                <div className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 bg-success rounded-full border-2 border-surface" />
              </div>

              {/* User info */}
              <div className="flex-1 min-w-0 overflow-hidden">
                <p className="text-sm font-semibold text-text-primary truncate">
                  {coach?.name}
                </p>
                <p className="text-xs text-text-muted truncate">{coach?.email}</p>
              </div>

              {/* Logout button */}
              <button
                onClick={logout}
                className={cn(
                  'p-2 rounded-lg transition-all duration-300',
                  'text-text-muted hover:text-error',
                  'hover:bg-error/10 hover:shadow-[0_0_15px_rgba(239,68,68,0.2)]'
                )}
                title="Déconnexion"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </aside>
  )
}
