import { useState, useEffect, useRef } from 'react'
import { Outlet, Navigate, useLocation } from 'react-router-dom'
import { Menu, Loader2 } from 'lucide-react'
import { Sidebar } from './sidebar'
import { ErrorBoundary } from '@/components/shared/error-boundary'
import { useAuthStore } from '@/store/auth-store'
import { useProgramsStore } from '@/store/programs-store'
import { useNutritionStore } from '@/store/nutrition-store'
import { useStudentsStore } from '@/store/students-store'
import { useMessagesStore } from '@/store/messages-store'
import { useStatsStore } from '@/store/stats-store'
import { cn } from '@/lib/utils'

export function AppShell() {
  const { isAuthenticated, isLoading: authLoading, checkSession } = useAuthStore()
  const { fetchPrograms, isLoading: programsLoading } = useProgramsStore()
  const { fetchDietPlans, isLoading: nutritionLoading } = useNutritionStore()
  const { fetchStudents, isLoading: studentsLoading } = useStudentsStore()
  const { fetchMessages, subscribeToRealtime, unsubscribeFromRealtime } = useMessagesStore()
  const { refreshAll: refreshStats } = useStatsStore()

  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [dataInitialized, setDataInitialized] = useState(false)
  const location = useLocation()
  const initRef = useRef(false)

  // Check session on mount
  useEffect(() => {
    checkSession()
  }, [checkSession])

  // Load data once authenticated
  useEffect(() => {
    if (isAuthenticated && !initRef.current) {
      initRef.current = true
      Promise.all([
        fetchPrograms(),
        fetchDietPlans(),
        fetchStudents(),
        fetchMessages(),
        refreshStats(),
      ]).then(() => {
        setDataInitialized(true)
        // Subscribe to realtime messages after initial fetch
        subscribeToRealtime()
      })
    }

    // Cleanup realtime subscription on unmount
    return () => {
      if (initRef.current) {
        unsubscribeFromRealtime()
      }
    }
  }, [isAuthenticated, fetchPrograms, fetchDietPlans, fetchStudents, fetchMessages, subscribeToRealtime, unsubscribeFromRealtime, refreshStats])

  // Ferme la sidebar sur mobile quand on change de page
  useEffect(() => {
    if (window.innerWidth < 1024) {
      setSidebarOpen(false)
    }
  }, [location.pathname])

  // Show loading while checking auth
  if (authLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="w-8 h-8 text-accent animate-spin" />
          <p className="text-text-muted">Chargement...</p>
        </div>
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  // Show loading while fetching initial data
  const isLoadingData = !dataInitialized && (programsLoading || nutritionLoading || studentsLoading)
  if (isLoadingData) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="w-8 h-8 text-accent animate-spin" />
          <p className="text-text-muted">Chargement des données...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background relative">
      {/* Ambient background effects */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        {/* Top-left accent glow */}
        <div className="absolute -top-32 -left-32 w-[500px] h-[500px] bg-accent/3 rounded-full blur-[150px]" />

        {/* Bottom-right subtle glow */}
        <div className="absolute -bottom-32 -right-32 w-[400px] h-[400px] bg-accent/2 rounded-full blur-[120px]" />

        {/* Grid pattern overlay */}
        <div
          className="absolute inset-0 opacity-[0.015]"
          style={{
            backgroundImage: `
              linear-gradient(rgba(255,255,255,0.05) 1px, transparent 1px),
              linear-gradient(90deg, rgba(255,255,255,0.05) 1px, transparent 1px)
            `,
            backgroundSize: '64px 64px'
          }}
        />
      </div>

      {/* Menu button - visible when sidebar is closed */}
      {!sidebarOpen && (
        <button
          onClick={() => setSidebarOpen(true)}
          className={cn(
            'fixed top-5 left-5 z-40 p-3 rounded-xl',
            'bg-surface border border-border',
            'text-text-secondary hover:text-text-primary',
            'transition-all duration-300 hover:border-accent/30'
          )}
        >
          <Menu className="w-5 h-5" />
        </button>
      )}

      {/* Overlay backdrop - mobile only */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/60 backdrop-blur-sm z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />

      {/* Main content area */}
      <main
        className={cn(
          'min-h-screen relative transition-[margin] duration-300',
          sidebarOpen ? 'ml-72' : 'ml-0'
        )}
      >
        {/* Subtle top gradient fade */}
        <div
          className={cn(
            'fixed top-0 right-0 h-32 bg-gradient-to-b from-background to-transparent pointer-events-none z-30 transition-[left] duration-300',
            sidebarOpen ? 'left-72' : 'left-0'
          )}
        />

        {/* Page content */}
        <div className="relative">
          <ErrorBoundary>
            <Outlet />
          </ErrorBoundary>
        </div>
      </main>
    </div>
  )
}
