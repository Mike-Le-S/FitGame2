import { useState } from 'react'
import { useParams, Link, Navigate } from 'react-router-dom'
import {
  ArrowLeft,
  Flame,
  TrendingUp,
  Clock,
  Calendar,
  Dumbbell,
  Apple,
  Heart,
  MessageSquare,
  ChevronRight,
  Edit3,
  MoreHorizontal,
  Activity,
  Target,
  Zap,
  ArrowUpRight,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Badge, Avatar } from '@/components/ui'
import { useStudentsStore } from '@/store/students-store'
import { useProgramsStore } from '@/store/programs-store'
import { useNutritionStore } from '@/store/nutrition-store'
import { formatDate } from '@/lib/utils'
import { cn } from '@/lib/utils'

type Tab = 'overview' | 'workouts' | 'nutrition' | 'health' | 'progress'

const goalConfig = {
  bulk: { label: 'Prise de masse', color: 'success' },
  cut: { label: 'Sèche', color: 'warning' },
  maintain: { label: 'Maintien', color: 'info' },
} as const

export function StudentProfilePage() {
  const { id } = useParams()
  const { getStudentById } = useStudentsStore()
  const { programs } = useProgramsStore()
  const { dietPlans } = useNutritionStore()
  const [activeTab, setActiveTab] = useState<Tab>('overview')

  const student = getStudentById(id!)

  if (!student) {
    return <Navigate to="/students" replace />
  }

  const assignedProgram = programs.find((p) => p.id === student.assignedProgramId)
  const assignedDiet = dietPlans.find((d) => d.id === student.assignedDietId)

  const tabs: { id: Tab; label: string; icon: React.ElementType }[] = [
    { id: 'overview', label: 'Aperçu', icon: Activity },
    { id: 'workouts', label: 'Entraînements', icon: Dumbbell },
    { id: 'nutrition', label: 'Nutrition', icon: Apple },
    { id: 'health', label: 'Santé', icon: Heart },
    { id: 'progress', label: 'Progression', icon: TrendingUp },
  ]

  // Mock chart data
  const weeklyProgress = [65, 72, 68, 85, 78, 92, 88]

  return (
    <div className="min-h-screen">
      <Header
        title=""
        action={
          <div className="flex items-center gap-2">
            <button className={cn(
              'flex items-center gap-2 h-10 px-4 rounded-xl',
              'bg-surface-elevated border border-border',
              'text-text-secondary hover:text-text-primary hover:border-text-muted',
              'transition-all duration-200'
            )}>
              <MoreHorizontal className="w-4 h-4" />
            </button>
            <button className={cn(
              'flex items-center gap-2 h-10 px-5 rounded-xl font-medium',
              'bg-gradient-to-r from-accent to-[#ff8f5c] text-white',
              'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
              'transition-all duration-300'
            )}>
              <MessageSquare className="w-4 h-4" />
              Message
            </button>
          </div>
        }
      />

      <div className="p-8">
        {/* Back link */}
        <Link
          to="/students"
          className={cn(
            'inline-flex items-center gap-2 text-sm mb-6',
            'text-text-secondary hover:text-accent transition-colors'
          )}
        >
          <ArrowLeft className="w-4 h-4" />
          Retour aux élèves
        </Link>

        {/* Profile Header Card */}
        <div className={cn(
          'relative p-6 rounded-2xl mb-6 overflow-hidden',
          'bg-surface border border-border'
        )}>
          {/* Background gradient */}
          <div className="absolute top-0 right-0 w-96 h-96 bg-accent/5 rounded-full blur-[100px]" />

          <div className="relative flex items-start gap-6">
            {/* Avatar */}
            <div className="relative">
              <Avatar name={student.name} size="xl" className="w-24 h-24 text-3xl" />
              <div className={cn(
                'absolute -bottom-1 -right-1 w-6 h-6 rounded-full border-3 border-surface',
                student.stats.thisWeekWorkouts > 0 ? 'bg-success' : 'bg-text-muted'
              )} />
            </div>

            {/* Info */}
            <div className="flex-1">
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-2xl font-bold text-text-primary">{student.name}</h1>
                <Badge variant={goalConfig[student.goal].color as 'success' | 'warning' | 'info'}>
                  {goalConfig[student.goal].label}
                </Badge>
              </div>
              <p className="text-text-secondary mb-1">{student.email}</p>
              <p className="text-sm text-text-muted">
                Membre depuis {formatDate(student.joinedAt)}
              </p>

              {/* Stats Row */}
              <div className="flex items-center gap-6 mt-5">
                {[
                  { icon: Flame, label: 'Streak', value: `${student.currentStreak}j`, color: 'accent' },
                  { icon: Target, label: 'Compliance', value: `${student.stats.complianceRate}%`, color: 'success' },
                  { icon: Dumbbell, label: 'Séances', value: student.stats.totalWorkouts, color: 'info' },
                  { icon: Clock, label: 'Durée moy.', value: `${student.stats.averageSessionDuration}min`, color: 'warning' },
                ].map((stat) => (
                  <div key={stat.label} className="flex items-center gap-3">
                    <div className={cn(
                      'w-10 h-10 rounded-xl flex items-center justify-center',
                      stat.color === 'accent' ? 'bg-accent/10' :
                      stat.color === 'success' ? 'bg-success/10' :
                      stat.color === 'info' ? 'bg-info/10' : 'bg-warning/10'
                    )}>
                      <stat.icon className={cn(
                        'w-5 h-5',
                        stat.color === 'accent' ? 'text-accent' :
                        stat.color === 'success' ? 'text-success' :
                        stat.color === 'info' ? 'text-info' : 'text-warning'
                      )} />
                    </div>
                    <div>
                      <p className="text-xs text-text-muted">{stat.label}</p>
                      <p className="text-lg font-bold text-text-primary">{stat.value}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Quick Actions */}
            <div className="flex flex-col gap-2">
              <button className={cn(
                'flex items-center gap-2 px-4 py-2 rounded-xl text-sm',
                'bg-surface-elevated border border-border',
                'text-text-secondary hover:text-text-primary hover:border-text-muted',
                'transition-all duration-200'
              )}>
                <Edit3 className="w-4 h-4" />
                Modifier profil
              </button>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex items-center gap-1 p-1.5 rounded-xl bg-surface border border-border mb-6 w-fit">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 text-sm font-medium rounded-lg',
                'transition-all duration-200',
                activeTab === tab.id
                  ? 'bg-accent text-white shadow-sm'
                  : 'text-text-secondary hover:text-text-primary hover:bg-surface-elevated'
              )}
            >
              <tab.icon className="w-4 h-4" />
              {tab.label}
            </button>
          ))}
        </div>

        {/* Tab Content */}
        {activeTab === 'overview' && (
          <div className="grid grid-cols-12 gap-6">
            {/* Left Column */}
            <div className="col-span-8 space-y-6">
              {/* Weekly Progress */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <div className="flex items-center justify-between mb-5">
                  <h3 className="text-base font-semibold text-text-primary flex items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-accent/10 flex items-center justify-center">
                      <Activity className="w-4 h-4 text-accent" />
                    </div>
                    Activité cette semaine
                  </h3>
                  <div className="flex items-center gap-2 text-sm">
                    <ArrowUpRight className="w-4 h-4 text-success" />
                    <span className="text-success font-medium">+12%</span>
                    <span className="text-text-muted">vs semaine dernière</span>
                  </div>
                </div>

                {/* Mini Chart */}
                <div className="flex items-end justify-between gap-2 h-24 px-2">
                  {weeklyProgress.map((value, i) => (
                    <div key={i} className="flex-1 flex flex-col items-center gap-2">
                      <div
                        className={cn(
                          'w-full rounded-t-lg transition-all duration-500',
                          i === weeklyProgress.length - 1 ? 'bg-accent' : 'bg-accent/30'
                        )}
                        style={{ height: `${value}%` }}
                      />
                      <span className="text-[10px] text-text-muted">
                        {['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'][i]}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Recent Sessions */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <div className="flex items-center justify-between mb-5">
                  <h3 className="text-base font-semibold text-text-primary flex items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-info/10 flex items-center justify-center">
                      <Calendar className="w-4 h-4 text-info" />
                    </div>
                    Séances récentes
                  </h3>
                  <button className="text-sm text-accent hover:text-accent-hover transition-colors">
                    Voir tout
                  </button>
                </div>

                <div className="space-y-3">
                  {[
                    { date: new Date(Date.now() - 86400000), name: 'Push A', duration: 58, exercises: 5, completed: true },
                    { date: new Date(Date.now() - 172800000), name: 'Pull A', duration: 62, exercises: 5, completed: true },
                    { date: new Date(Date.now() - 259200000), name: 'Legs A', duration: 55, exercises: 5, completed: true },
                    { date: new Date(Date.now() - 345600000), name: 'Push B', duration: 0, exercises: 5, completed: false },
                  ].map((session, i) => (
                    <div
                      key={i}
                      className={cn(
                        'group flex items-center justify-between p-4 rounded-xl',
                        'hover:bg-surface-elevated transition-all duration-200'
                      )}
                    >
                      <div className="flex items-center gap-4">
                        <div className={cn(
                          'w-12 h-12 rounded-xl flex items-center justify-center',
                          session.completed ? 'bg-accent/10' : 'bg-surface-elevated'
                        )}>
                          <Dumbbell className={cn(
                            'w-5 h-5',
                            session.completed ? 'text-accent' : 'text-text-muted'
                          )} />
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h4 className="font-medium text-text-primary">{session.name}</h4>
                            {!session.completed && (
                              <Badge variant="warning" className="text-[10px]">Manquée</Badge>
                            )}
                          </div>
                          <p className="text-sm text-text-muted">
                            {formatDate(session.date)} · {session.exercises} exercices
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-4">
                        {session.completed && (
                          <div className="text-right">
                            <p className="text-xs text-text-muted">Durée</p>
                            <p className="font-semibold text-text-primary">{session.duration} min</p>
                          </div>
                        )}
                        <ChevronRight className={cn(
                          'w-5 h-5 text-text-muted transition-all duration-200',
                          'opacity-0 group-hover:opacity-100 group-hover:translate-x-1'
                        )} />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Right Column */}
            <div className="col-span-4 space-y-6">
              {/* Assigned Program */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-sm font-semibold text-text-secondary flex items-center gap-2">
                    <Dumbbell className="w-4 h-4 text-accent" />
                    Programme
                  </h3>
                  <button className="text-xs text-accent hover:text-accent-hover transition-colors">
                    Modifier
                  </button>
                </div>

                {assignedProgram ? (
                  <div className={cn(
                    'p-4 rounded-xl',
                    'bg-gradient-to-br from-accent/10 via-surface-elevated to-surface-elevated',
                    'border border-accent/20'
                  )}>
                    <div className="flex items-start justify-between mb-3">
                      <h4 className="font-semibold text-text-primary">{assignedProgram.name}</h4>
                      <Badge variant="accent" className="text-[10px]">
                        {assignedProgram.durationWeeks} sem
                      </Badge>
                    </div>
                    <p className="text-sm text-text-muted mb-4 line-clamp-2">
                      {assignedProgram.description || 'Aucune description'}
                    </p>
                    <div className="flex items-center gap-4 text-xs text-text-secondary">
                      <span className="flex items-center gap-1">
                        <Calendar className="w-3.5 h-3.5" />
                        {assignedProgram.days.length}j/sem
                      </span>
                      {assignedProgram.deloadFrequency && (
                        <span className="flex items-center gap-1">
                          <Zap className="w-3.5 h-3.5" />
                          Deload: {assignedProgram.deloadFrequency} sem
                        </span>
                      )}
                    </div>
                  </div>
                ) : (
                  <div className="flex flex-col items-center justify-center py-8">
                    <div className="w-12 h-12 rounded-xl bg-surface-elevated flex items-center justify-center mb-3">
                      <Dumbbell className="w-6 h-6 text-text-muted" />
                    </div>
                    <p className="text-sm text-text-muted mb-3">Aucun programme</p>
                    <button className={cn(
                      'px-4 py-2 rounded-lg text-sm font-medium',
                      'bg-accent/10 text-accent hover:bg-accent/20',
                      'transition-colors'
                    )}>
                      Assigner
                    </button>
                  </div>
                )}
              </div>

              {/* Assigned Diet */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-sm font-semibold text-text-secondary flex items-center gap-2">
                    <Apple className="w-4 h-4 text-success" />
                    Nutrition
                  </h3>
                  <button className="text-xs text-accent hover:text-accent-hover transition-colors">
                    Modifier
                  </button>
                </div>

                {assignedDiet ? (
                  <div className="p-4 rounded-xl bg-surface-elevated border border-border/50">
                    <div className="flex items-start justify-between mb-3">
                      <h4 className="font-semibold text-text-primary">{assignedDiet.name}</h4>
                      <Badge
                        variant={goalConfig[assignedDiet.goal].color as 'success' | 'warning' | 'info'}
                        className="text-[10px]"
                      >
                        {goalConfig[assignedDiet.goal].label}
                      </Badge>
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                      <div className="p-3 rounded-lg bg-surface">
                        <p className="text-[10px] uppercase tracking-wider text-text-muted mb-1">Training</p>
                        <p className="text-lg font-bold text-text-primary">
                          {assignedDiet.trainingCalories}
                          <span className="text-xs font-normal text-text-muted ml-1">kcal</span>
                        </p>
                      </div>
                      <div className="p-3 rounded-lg bg-surface">
                        <p className="text-[10px] uppercase tracking-wider text-text-muted mb-1">Repos</p>
                        <p className="text-lg font-bold text-text-primary">
                          {assignedDiet.restCalories}
                          <span className="text-xs font-normal text-text-muted ml-1">kcal</span>
                        </p>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="flex flex-col items-center justify-center py-8">
                    <div className="w-12 h-12 rounded-xl bg-surface-elevated flex items-center justify-center mb-3">
                      <Apple className="w-6 h-6 text-text-muted" />
                    </div>
                    <p className="text-sm text-text-muted mb-3">Aucun plan</p>
                    <button className={cn(
                      'px-4 py-2 rounded-lg text-sm font-medium',
                      'bg-success/10 text-success hover:bg-success/20',
                      'transition-colors'
                    )}>
                      Assigner
                    </button>
                  </div>
                )}
              </div>

              {/* Quick Stats */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <h3 className="text-sm font-semibold text-text-secondary mb-4">
                  Cette semaine
                </h3>
                <div className="space-y-3">
                  {[
                    { label: 'Séances complétées', value: `${student.stats.thisWeekWorkouts}/5`, percent: (student.stats.thisWeekWorkouts / 5) * 100, color: 'accent' },
                    { label: 'Objectif atteint', value: '3/5 jours', percent: 60, color: 'success' },
                    { label: 'Temps total', value: '4h 12min', percent: 75, color: 'info' },
                  ].map((item) => (
                    <div key={item.label}>
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="text-sm text-text-muted">{item.label}</span>
                        <span className="text-sm font-semibold text-text-primary">{item.value}</span>
                      </div>
                      <div className="h-1.5 rounded-full bg-surface-elevated overflow-hidden">
                        <div
                          className={cn(
                            'h-full rounded-full transition-all duration-500',
                            item.color === 'accent' ? 'bg-accent' :
                            item.color === 'success' ? 'bg-success' : 'bg-info'
                          )}
                          style={{ width: `${item.percent}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab !== 'overview' && (
          <div className="flex flex-col items-center justify-center py-20 rounded-2xl bg-surface border border-border">
            <div className="w-16 h-16 rounded-2xl bg-surface-elevated flex items-center justify-center mb-4">
              {tabs.find(t => t.id === activeTab)?.icon && (
                <div className="w-8 h-8 text-text-muted">
                  {(() => {
                    const Icon = tabs.find(t => t.id === activeTab)!.icon
                    return <Icon className="w-8 h-8" />
                  })()}
                </div>
              )}
            </div>
            <h3 className="text-lg font-semibold text-text-primary mb-2">
              {tabs.find(t => t.id === activeTab)?.label}
            </h3>
            <p className="text-sm text-text-muted">
              Cette section sera bientôt disponible
            </p>
          </div>
        )}
      </div>
    </div>
  )
}
