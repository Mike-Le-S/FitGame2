import { Outlet, Navigate } from 'react-router-dom'
import { Sidebar } from './sidebar'
import { useAuthStore } from '@/store/auth-store'

export function AppShell() {
  const { isAuthenticated } = useAuthStore()

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
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

      {/* Sidebar */}
      <Sidebar />

      {/* Main content area */}
      <main className="ml-72 min-h-screen relative">
        {/* Subtle top gradient fade */}
        <div className="fixed top-0 left-72 right-0 h-32 bg-gradient-to-b from-background to-transparent pointer-events-none z-30" />

        {/* Page content */}
        <div className="relative">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
