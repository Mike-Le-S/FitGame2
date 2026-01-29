import {
  Users,
  Dumbbell,
  MessageSquare,
  TrendingUp,
  AlertTriangle,
  Clock,
  ChevronRight,
  Flame,
  Plus,
  ArrowUpRight,
  Activity,
  Target,
  Calendar,
} from 'lucide-react'
import { Link } from 'react-router-dom'
import { Header } from '@/components/layout'
import { Badge, Avatar } from '@/components/ui'
import { useStudentsStore } from '@/store/students-store'
import { useProgramsStore } from '@/store/programs-store'
import { formatRelativeTime } from '@/lib/utils'
import { cn } from '@/lib/utils'

interface StatCardProps {
  title: string
  value: string | number
  change?: string
  changeType?: 'positive' | 'negative' | 'neutral'
  icon: React.ElementType
  color?: 'accent' | 'success' | 'warning' | 'info'
  delay?: number
}

function StatCard({
  title,
  value,
  change,
  changeType = 'neutral',
  icon: Icon,
  color = 'accent',
  delay = 0,
}: StatCardProps) {
  const colorClasses = {
    accent: {
      bg: 'bg-accent/10',
      text: 'text-accent',
      glow: 'shadow-accent/20',
      gradient: 'from-accent/20 via-accent/5 to-transparent',
    },
    success: {
      bg: 'bg-success/10',
      text: 'text-success',
      glow: 'shadow-success/20',
      gradient: 'from-success/20 via-success/5 to-transparent',
    },
    warning: {
      bg: 'bg-warning/10',
      text: 'text-warning',
      glow: 'shadow-warning/20',
      gradient: 'from-warning/20 via-warning/5 to-transparent',
    },
    info: {
      bg: 'bg-info/10',
      text: 'text-info',
      glow: 'shadow-info/20',
      gradient: 'from-info/20 via-info/5 to-transparent',
    },
  }

  const colors = colorClasses[color]

  return (
    <div
      className={cn(
        'relative group p-5 rounded-2xl overflow-hidden',
        'bg-surface border border-border',
        'hover:border-[rgba(255,255,255,0.12)] transition-all duration-300',
        'animate-[fadeIn_0.5s_ease-out_forwards] opacity-0'
      )}
      style={{ animationDelay: `${delay}ms` }}
    >
      {/* Background gradient */}
      <div className={cn(
        'absolute top-0 right-0 w-32 h-32 rounded-full blur-3xl opacity-50',
        'bg-gradient-to-br',
        colors.gradient
      )} />

      <div className="relative flex items-start justify-between">
        <div className="space-y-1">
          <p className="text-sm text-text-secondary">{title}</p>
          <p className="text-3xl font-bold text-text-primary tracking-tight">{value}</p>
          {change && (
            <div className="flex items-center gap-1.5 mt-2">
              {changeType === 'positive' && (
                <ArrowUpRight className="w-3.5 h-3.5 text-success" />
              )}
              <p className={cn(
                'text-xs font-medium',
                changeType === 'positive' ? 'text-success' :
                changeType === 'negative' ? 'text-error' : 'text-text-muted'
              )}>
                {change}
              </p>
            </div>
          )}
        </div>

        <div className={cn(
          'w-12 h-12 rounded-xl flex items-center justify-center',
          'transition-all duration-300 group-hover:scale-110',
          colors.bg
        )}>
          <Icon className={cn('w-6 h-6', colors.text)} />
        </div>
      </div>
    </div>
  )
}

// Mini chart component (decorative)
function MiniChart() {
  const bars = [35, 52, 45, 68, 55, 72, 48]
  const maxHeight = Math.max(...bars)

  return (
    <div className="flex items-end gap-1.5 h-12">
      {bars.map((height, i) => (
        <div
          key={i}
          className={cn(
            'w-2 rounded-full transition-all duration-500',
            i === bars.length - 1 ? 'bg-accent' : 'bg-accent/30'
          )}
          style={{
            height: `${(height / maxHeight) * 100}%`,
            animationDelay: `${i * 50}ms`,
          }}
        />
      ))}
    </div>
  )
}

export function DashboardPage() {
  const { students } = useStudentsStore()
  const { programs } = useProgramsStore()

  // Calculate stats
  const activeStudents = students.length
  const totalWorkoutsThisWeek = students.reduce((acc, s) => acc + s.stats.thisWeekWorkouts, 0)
  const averageCompliance = Math.round(
    students.reduce((acc, s) => acc + s.stats.complianceRate, 0) / students.length
  )

  // Students needing attention (low compliance or no recent workout)
  const alertStudents = students.filter(
    (s) => s.stats.complianceRate < 70 || s.stats.thisWeekWorkouts < 2
  )

  // Recent activity
  const recentActivity = students
    .filter((s) => s.lastWorkout)
    .sort((a, b) => new Date(b.lastWorkout!).getTime() - new Date(a.lastWorkout!).getTime())
    .slice(0, 5)

  // Top performers
  const topPerformers = [...students]
    .sort((a, b) => b.currentStreak - a.currentStreak)
    .slice(0, 3)

  const quickActions = [
    { icon: Plus, label: 'Programme', href: '/programs/create', color: 'accent' as const },
    { icon: Users, label: 'Élève', href: '/students', color: 'info' as const },
    { icon: Calendar, label: 'Événement', href: '/calendar', color: 'success' as const },
  ]

  return (
    <div className="min-h-screen">
      <Header
        title="Dashboard"
        subtitle={new Date().toLocaleDateString('fr-FR', {
          weekday: 'long',
          day: 'numeric',
          month: 'long',
        })}
      />

      <div className="p-8 space-y-8">
        {/* Stats Grid */}
        <div className="grid grid-cols-4 gap-5">
          <StatCard
            title="Élèves actifs"
            value={activeStudents}
            change="+2 ce mois"
            changeType="positive"
            icon={Users}
            color="accent"
            delay={0}
          />
          <StatCard
            title="Séances cette semaine"
            value={totalWorkoutsThisWeek}
            change="+12% vs semaine dernière"
            changeType="positive"
            icon={Dumbbell}
            color="success"
            delay={50}
          />
          <StatCard
            title="Compliance moyenne"
            value={`${averageCompliance}%`}
            changeType={averageCompliance > 80 ? 'positive' : 'neutral'}
            icon={TrendingUp}
            color="info"
            delay={100}
          />
          <StatCard
            title="Messages non lus"
            value={3}
            icon={MessageSquare}
            color="warning"
            delay={150}
          />
        </div>

        {/* Main content grid */}
        <div className="grid grid-cols-12 gap-6">
          {/* Left column */}
          <div className="col-span-8 space-y-6">
            {/* Quick Actions + Performance */}
            <div className="grid grid-cols-2 gap-5">
              {/* Quick Actions */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <h3 className="text-sm font-semibold text-text-secondary mb-4 flex items-center gap-2">
                  <Activity className="w-4 h-4 text-accent" />
                  Actions rapides
                </h3>
                <div className="grid grid-cols-3 gap-3">
                  {quickActions.map((action) => (
                    <Link
                      key={action.label}
                      to={action.href}
                      className={cn(
                        'group flex flex-col items-center gap-2 p-4 rounded-xl',
                        'bg-surface-elevated border border-border',
                        'hover:border-accent/30 hover:bg-accent/5',
                        'transition-all duration-300'
                      )}
                    >
                      <div className={cn(
                        'w-10 h-10 rounded-xl flex items-center justify-center',
                        'bg-accent/10 group-hover:bg-accent/20 transition-colors'
                      )}>
                        <action.icon className="w-5 h-5 text-accent" />
                      </div>
                      <span className="text-xs text-text-primary text-center font-medium">
                        {action.label}
                      </span>
                    </Link>
                  ))}
                </div>
              </div>

              {/* Weekly Performance */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-sm font-semibold text-text-secondary flex items-center gap-2">
                    <Target className="w-4 h-4 text-accent" />
                    Performance semaine
                  </h3>
                  <span className="text-xs text-text-muted">7 derniers jours</span>
                </div>

                <div className="flex items-end justify-between">
                  <div>
                    <p className="text-3xl font-bold text-text-primary">{totalWorkoutsThisWeek}</p>
                    <p className="text-sm text-text-muted">séances complétées</p>
                  </div>
                  <MiniChart />
                </div>
              </div>
            </div>

            {/* Alerts & Activity Row */}
            <div className="grid grid-cols-2 gap-5">
              {/* Alerts */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-base font-semibold text-text-primary flex items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-warning/10 flex items-center justify-center">
                      <AlertTriangle className="w-4 h-4 text-warning" />
                    </div>
                    Alertes
                  </h3>
                  <Badge variant="warning">{alertStudents.length}</Badge>
                </div>

                <div className="space-y-2">
                  {alertStudents.slice(0, 4).map((student) => (
                    <Link
                      key={student.id}
                      to={`/students/${student.id}`}
                      className={cn(
                        'group flex items-center gap-3 p-3 rounded-xl',
                        'hover:bg-surface-elevated transition-all duration-200'
                      )}
                    >
                      <Avatar name={student.name} size="sm" />
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-text-primary truncate">
                          {student.name}
                        </p>
                        <p className="text-xs text-text-muted">
                          {student.stats.complianceRate < 70
                            ? `Compliance: ${student.stats.complianceRate}%`
                            : `${student.stats.thisWeekWorkouts} séance(s) cette semaine`}
                        </p>
                      </div>
                      <ChevronRight className={cn(
                        'w-4 h-4 text-text-muted transition-all duration-200',
                        'opacity-0 group-hover:opacity-100 group-hover:translate-x-1'
                      )} />
                    </Link>
                  ))}

                  {alertStudents.length === 0 && (
                    <div className="flex flex-col items-center justify-center py-8 text-center">
                      <div className="w-12 h-12 rounded-full bg-success/10 flex items-center justify-center mb-3">
                        <Target className="w-6 h-6 text-success" />
                      </div>
                      <p className="text-sm text-text-secondary">Tous vos élèves sont sur la bonne voie !</p>
                    </div>
                  )}
                </div>
              </div>

              {/* Recent Activity */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-base font-semibold text-text-primary flex items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-accent/10 flex items-center justify-center">
                      <Clock className="w-4 h-4 text-accent" />
                    </div>
                    Activité récente
                  </h3>
                </div>

                <div className="space-y-2">
                  {recentActivity.slice(0, 4).map((student, index) => (
                    <Link
                      key={student.id}
                      to={`/students/${student.id}`}
                      className={cn(
                        'group flex items-center gap-3 p-3 rounded-xl',
                        'hover:bg-surface-elevated transition-all duration-200'
                      )}
                    >
                      {/* Timeline indicator */}
                      <div className="relative">
                        <Avatar name={student.name} size="sm" />
                        {index < recentActivity.length - 1 && (
                          <div className="absolute top-full left-1/2 -translate-x-1/2 w-px h-4 bg-border" />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-text-primary truncate">
                          {student.name}
                        </p>
                        <p className="text-xs text-text-muted">
                          {formatRelativeTime(student.lastWorkout!)}
                        </p>
                      </div>
                      <div className="flex items-center gap-1.5 px-2 py-1 rounded-full bg-accent/10">
                        <Flame className="w-3.5 h-3.5 text-accent" />
                        <span className="text-xs font-semibold text-accent">
                          {student.currentStreak}
                        </span>
                      </div>
                    </Link>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Right column */}
          <div className="col-span-4 space-y-6">
            {/* Top Performers */}
            <div className="p-5 rounded-2xl bg-gradient-to-br from-accent/10 via-surface to-surface border border-accent/20">
              <div className="flex items-center justify-between mb-5">
                <h3 className="text-base font-semibold text-text-primary flex items-center gap-2">
                  <Flame className="w-5 h-5 text-accent" />
                  Top Performers
                </h3>
              </div>

              <div className="space-y-3">
                {topPerformers.map((student, index) => (
                  <Link
                    key={student.id}
                    to={`/students/${student.id}`}
                    className={cn(
                      'group flex items-center gap-3 p-3 rounded-xl',
                      'bg-surface/50 hover:bg-surface transition-all duration-200'
                    )}
                  >
                    {/* Rank */}
                    <div className={cn(
                      'w-8 h-8 rounded-lg flex items-center justify-center font-bold text-sm',
                      index === 0 ? 'bg-accent text-white' :
                      index === 1 ? 'bg-text-muted/20 text-text-secondary' :
                      'bg-surface-elevated text-text-muted'
                    )}>
                      {index + 1}
                    </div>
                    <Avatar name={student.name} size="sm" />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-text-primary truncate">
                        {student.name}
                      </p>
                      <p className="text-xs text-text-muted">
                        {student.stats.totalWorkouts} séances totales
                      </p>
                    </div>
                    <div className="flex items-center gap-1 text-accent">
                      <Flame className="w-4 h-4" />
                      <span className="text-sm font-bold">{student.currentStreak}</span>
                    </div>
                  </Link>
                ))}
              </div>
            </div>

            {/* Programs */}
            <div className="p-5 rounded-2xl bg-surface border border-border">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-base font-semibold text-text-primary flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-info/10 flex items-center justify-center">
                    <Dumbbell className="w-4 h-4 text-info" />
                  </div>
                  Programmes
                </h3>
                <Link
                  to="/programs"
                  className="text-xs text-accent hover:text-accent-hover transition-colors font-medium"
                >
                  Voir tous
                </Link>
              </div>

              <div className="space-y-2">
                {programs.slice(0, 4).map((program) => (
                  <Link
                    key={program.id}
                    to={`/programs/${program.id}`}
                    className={cn(
                      'group flex items-center justify-between p-3 rounded-xl',
                      'hover:bg-surface-elevated transition-all duration-200'
                    )}
                  >
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-text-primary truncate">
                        {program.name}
                      </p>
                      <p className="text-xs text-text-muted">
                        {program.durationWeeks} sem. · {program.assignedStudentIds.length} élèves
                      </p>
                    </div>
                    <Badge
                      variant={
                        program.goal === 'bulk' ? 'success' :
                        program.goal === 'cut' ? 'warning' : 'info'
                      }
                    >
                      {program.goal === 'bulk' ? 'Masse' :
                       program.goal === 'cut' ? 'Sèche' : 'Maintien'}
                    </Badge>
                  </Link>
                ))}
              </div>

              {/* Add program button */}
              <Link
                to="/programs/create"
                className={cn(
                  'flex items-center justify-center gap-2 mt-4 p-3 rounded-xl',
                  'border border-dashed border-border',
                  'text-sm text-text-muted hover:text-accent hover:border-accent/30',
                  'transition-all duration-200'
                )}
              >
                <Plus className="w-4 h-4" />
                Créer un programme
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
