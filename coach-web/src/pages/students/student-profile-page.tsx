import { useState, useEffect } from 'react'
import { useParams, Link, Navigate, useNavigate } from 'react-router-dom'
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
  Trash2,
  Scale,
  Moon,
  LineChart,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Badge, Avatar } from '@/components/ui'
import { EditStudentModal } from '@/components/modals/edit-student-modal'
import { AssignProgramModal } from '@/components/modals/assign-program-modal'
import { AssignDietModal } from '@/components/modals/assign-diet-modal'
import { SessionDetailModal } from '@/components/modals/session-detail-modal'
import { useStudentsStore } from '@/store/students-store'
import { useProgramsStore } from '@/store/programs-store'
import { useNutritionStore } from '@/store/nutrition-store'
import { formatDate } from '@/lib/utils'
import { cn } from '@/lib/utils'
import { goalConfig } from '@/constants/goals'

type Tab = 'overview' | 'workouts' | 'nutrition' | 'health' | 'progress'

export function StudentProfilePage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { getStudentById, deleteStudent, fetchStudentSessions, studentSessions } = useStudentsStore()
  const { programs } = useProgramsStore()
  const { dietPlans } = useNutritionStore()
  const [activeTab, setActiveTab] = useState<Tab>('overview')
  const [showMenu, setShowMenu] = useState(false)
  const [showEditModal, setShowEditModal] = useState(false)
  const [showAssignProgramModal, setShowAssignProgramModal] = useState(false)
  const [showAssignDietModal, setShowAssignDietModal] = useState(false)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [selectedSession, setSelectedSession] = useState<any>(null)
  const [isLoadingSessions, setIsLoadingSessions] = useState(true)

  const student = getStudentById(id!)

  // Fetch real workout sessions from Supabase
  useEffect(() => {
    if (id) {
      setIsLoadingSessions(true)
      fetchStudentSessions(id, 20).finally(() => setIsLoadingSessions(false))
    }
  }, [id, fetchStudentSessions])

  // Get sessions from store
  const realSessions = id ? (studentSessions[id] || []) : []

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

  // Mock data for weekly progress and health
  const weeklyProgress = [65, 72, 68, 85, 78, 92, 88]

  const mockHealthData = {
    weight: [82.5, 82.3, 82.1, 82.0, 81.8, 81.7, 81.5],
    sleep: [7.5, 6.8, 7.2, 8.1, 7.0, 6.5, 7.8],
    restingHR: [62, 60, 58, 61, 59, 57, 58],
  }

  const handleDelete = () => {
    deleteStudent(student.id)
    navigate('/students')
  }

  return (
    <div className="min-h-screen">
      <Header
        title=""
        action={
          <div className="flex items-center gap-2">
            <div className="relative">
              <button
                onClick={() => setShowMenu(!showMenu)}
                className={cn(
                  'flex items-center gap-2 h-10 px-4 rounded-xl',
                  'bg-surface-elevated border border-border',
                  'text-text-secondary hover:text-text-primary hover:border-text-muted',
                  'transition-all duration-200'
                )}
              >
                <MoreHorizontal className="w-4 h-4" />
              </button>

              {showMenu && (
                <div className={cn(
                  'absolute top-full right-0 mt-2 w-48',
                  'bg-surface border border-border rounded-xl shadow-xl',
                  'animate-[fadeIn_0.15s_ease-out]',
                  'z-10'
                )}>
                  <div className="p-1">
                    <button
                      onClick={() => {
                        setShowMenu(false)
                        setShowEditModal(true)
                      }}
                      className="w-full flex items-center gap-2 px-3 py-2.5 text-sm text-text-secondary hover:text-text-primary hover:bg-surface-elevated rounded-lg transition-colors"
                    >
                      <Edit3 className="w-4 h-4" />
                      Modifier profil
                    </button>
                    <button
                      onClick={() => {
                        setShowMenu(false)
                        setShowDeleteConfirm(true)
                      }}
                      className="w-full flex items-center gap-2 px-3 py-2.5 text-sm text-error hover:bg-error/10 rounded-lg transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                      Supprimer
                    </button>
                  </div>
                </div>
              )}
            </div>
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
          <div className="absolute top-0 right-0 w-96 h-96 bg-accent/5 rounded-full blur-[100px]" />

          <div className="relative flex items-start gap-6">
            <div className="relative">
              <Avatar name={student.name} size="xl" className="w-24 h-24 text-3xl" />
              <div className={cn(
                'absolute -bottom-1 -right-1 w-6 h-6 rounded-full border-3 border-surface',
                student.stats.thisWeekWorkouts > 0 ? 'bg-success' : 'bg-text-muted'
              )} />
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-2xl font-bold text-text-primary truncate">{student.name}</h1>
                <Badge variant={goalConfig[student.goal].color as 'success' | 'warning' | 'info'}>
                  {goalConfig[student.goal].label}
                </Badge>
              </div>
              <p className="text-text-secondary mb-1">{student.email}</p>
              <p className="text-sm text-text-muted">
                Membre depuis {formatDate(student.joinedAt)}
              </p>

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

            <div className="flex flex-col gap-2">
              <button
                onClick={() => setShowEditModal(true)}
                className={cn(
                  'flex items-center gap-2 px-4 py-2 rounded-xl text-sm',
                  'bg-surface-elevated border border-border',
                  'text-text-secondary hover:text-text-primary hover:border-text-muted',
                  'transition-all duration-200'
                )}
              >
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

        {/* Tab Content: Overview */}
        {activeTab === 'overview' && (
          <div className="grid grid-cols-12 gap-6">
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
                  <button
                    onClick={() => setActiveTab('workouts')}
                    className="text-sm text-accent hover:text-accent-hover transition-colors"
                  >
                    Voir tout
                  </button>
                </div>

                <div className="space-y-3">
                  {isLoadingSessions ? (
                    <div className="flex items-center justify-center py-8">
                      <div className="w-6 h-6 border-2 border-accent border-t-transparent rounded-full animate-spin" />
                    </div>
                  ) : realSessions.length === 0 ? (
                    <div className="text-center py-8 text-text-muted">
                      Aucune séance récente
                    </div>
                  ) : (
                    realSessions.slice(0, 4).map((session) => (
                      <button
                        key={session.id}
                        onClick={() => setSelectedSession({
                          id: session.id,
                          name: session.dayName,
                          date: new Date(session.completedAt || session.startedAt),
                          duration: session.durationMinutes,
                          completed: !!session.completedAt,
                          exercises: session.exercises.map((ex: any, i: number) => ({
                            id: `ex-${i}`,
                            name: ex.exerciseName,
                            muscle: ex.muscleGroup || 'other',
                            mode: 'classic',
                            sets: (ex.sets || []).map((s: any, j: number) => ({
                              id: `s-${j}`,
                              targetReps: s.reps,
                              targetWeight: s.weight,
                              actualReps: s.reps,
                              actualWeight: s.weight,
                              isWarmup: s.isWarmup || false,
                              restSeconds: 120,
                            })),
                          })),
                          notes: session.notes,
                        })}
                        className={cn(
                          'w-full group flex items-center justify-between p-4 rounded-xl text-left',
                          'hover:bg-surface-elevated transition-all duration-200'
                        )}
                      >
                        <div className="flex items-center gap-4">
                          <div className={cn(
                            'w-12 h-12 rounded-xl flex items-center justify-center',
                            session.completedAt ? 'bg-accent/10' : 'bg-surface-elevated'
                          )}>
                            <Dumbbell className={cn(
                              'w-5 h-5',
                              session.completedAt ? 'text-accent' : 'text-text-muted'
                            )} />
                          </div>
                          <div>
                            <div className="flex items-center gap-2 min-w-0">
                              <h4 className="font-medium text-text-primary truncate">{session.dayName}</h4>
                              {session.personalRecords && session.personalRecords.length > 0 && (
                                <Badge variant="warning" className="text-[10px]">PR</Badge>
                              )}
                            </div>
                            <p className="text-sm text-text-muted">
                              {formatDate(new Date(session.completedAt || session.startedAt))} - {session.exercises.length} exercices
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-4">
                          {session.completedAt && (
                            <div className="text-right">
                              <p className="text-xs text-text-muted">Durée</p>
                              <p className="font-semibold text-text-primary">{session.durationMinutes} min</p>
                            </div>
                          )}
                          <ChevronRight className={cn(
                            'w-5 h-5 text-text-muted transition-all duration-200',
                            'opacity-0 group-hover:opacity-100 group-hover:translate-x-1'
                          )} />
                        </div>
                      </button>
                    ))
                  )}
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
                  <button
                    onClick={() => setShowAssignProgramModal(true)}
                    className="text-xs text-accent hover:text-accent-hover transition-colors"
                  >
                    {assignedProgram ? 'Modifier' : 'Assigner'}
                  </button>
                </div>

                {assignedProgram ? (
                  <Link
                    to={`/programs/${assignedProgram.id}`}
                    className={cn(
                      'block p-4 rounded-xl',
                      'bg-gradient-to-br from-accent/10 via-surface-elevated to-surface-elevated',
                      'border border-accent/20',
                      'hover:border-accent/40 transition-colors'
                    )}
                  >
                    <div className="flex items-start justify-between gap-2 mb-3">
                      <h4 className="font-semibold text-text-primary truncate">{assignedProgram.name}</h4>
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
                  </Link>
                ) : (
                  <div className="flex flex-col items-center justify-center py-8">
                    <div className="w-12 h-12 rounded-xl bg-surface-elevated flex items-center justify-center mb-3">
                      <Dumbbell className="w-6 h-6 text-text-muted" />
                    </div>
                    <p className="text-sm text-text-muted mb-3">Aucun programme</p>
                    <button
                      onClick={() => setShowAssignProgramModal(true)}
                      className={cn(
                        'px-4 py-2 rounded-lg text-sm font-medium',
                        'bg-accent/10 text-accent hover:bg-accent/20',
                        'transition-colors'
                      )}
                    >
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
                  <button
                    onClick={() => setShowAssignDietModal(true)}
                    className="text-xs text-accent hover:text-accent-hover transition-colors"
                  >
                    {assignedDiet ? 'Modifier' : 'Assigner'}
                  </button>
                </div>

                {assignedDiet ? (
                  <Link
                    to={`/nutrition/${assignedDiet.id}`}
                    className={cn(
                      'block p-4 rounded-xl bg-surface-elevated border border-border/50',
                      'hover:border-success/30 transition-colors'
                    )}
                  >
                    <div className="flex items-start justify-between gap-2 mb-3">
                      <h4 className="font-semibold text-text-primary truncate">{assignedDiet.name}</h4>
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
                  </Link>
                ) : (
                  <div className="flex flex-col items-center justify-center py-8">
                    <div className="w-12 h-12 rounded-xl bg-surface-elevated flex items-center justify-center mb-3">
                      <Apple className="w-6 h-6 text-text-muted" />
                    </div>
                    <p className="text-sm text-text-muted mb-3">Aucun plan</p>
                    <button
                      onClick={() => setShowAssignDietModal(true)}
                      className={cn(
                        'px-4 py-2 rounded-lg text-sm font-medium',
                        'bg-success/10 text-success hover:bg-success/20',
                        'transition-colors'
                      )}
                    >
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

        {/* Tab Content: Workouts */}
        {activeTab === 'workouts' && (
          <div className="space-y-6">
            <div className="grid grid-cols-4 gap-4">
              {[
                { label: 'Séances totales', value: student.stats.totalWorkouts, icon: Dumbbell, color: 'accent' },
                { label: 'Cette semaine', value: student.stats.thisWeekWorkouts, icon: Calendar, color: 'success' },
                { label: 'Durée moyenne', value: `${student.stats.averageSessionDuration}min`, icon: Clock, color: 'info' },
                { label: 'Compliance', value: `${student.stats.complianceRate}%`, icon: Target, color: 'warning' },
              ].map((stat) => (
                <div key={stat.label} className="p-5 rounded-2xl bg-surface border border-border">
                  <div className={cn(
                    'w-10 h-10 rounded-xl flex items-center justify-center mb-3',
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
                  <p className="text-2xl font-bold text-text-primary">{stat.value}</p>
                  <p className="text-sm text-text-muted">{stat.label}</p>
                </div>
              ))}
            </div>

            <div className="p-5 rounded-2xl bg-surface border border-border">
              <h3 className="text-lg font-semibold text-text-primary mb-4">Historique des séances</h3>
              <div className="space-y-3">
                {isLoadingSessions ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="w-6 h-6 border-2 border-accent border-t-transparent rounded-full animate-spin" />
                  </div>
                ) : realSessions.length === 0 ? (
                  <div className="text-center py-8 text-text-muted">
                    Aucune séance enregistrée
                  </div>
                ) : (
                  realSessions.map((session) => (
                    <button
                      key={session.id}
                      onClick={() => setSelectedSession({
                        id: session.id,
                        name: session.dayName,
                        date: new Date(session.completedAt || session.startedAt),
                        duration: session.durationMinutes,
                        completed: !!session.completedAt,
                        exercises: session.exercises.map((ex: any, i: number) => ({
                          id: `ex-${i}`,
                          name: ex.exerciseName,
                          muscle: ex.muscleGroup || 'other',
                          mode: 'classic',
                          sets: (ex.sets || []).map((s: any, j: number) => ({
                            id: `s-${j}`,
                            targetReps: s.reps,
                            targetWeight: s.weight,
                            actualReps: s.reps,
                            actualWeight: s.weight,
                            isWarmup: s.isWarmup || false,
                            restSeconds: 120,
                          })),
                        })),
                        notes: session.notes,
                      })}
                      className={cn(
                        'w-full flex items-center justify-between p-4 rounded-xl text-left',
                        'bg-surface-elevated hover:bg-surface-elevated/80 transition-colors'
                      )}
                    >
                      <div className="flex items-center gap-4">
                        <div className={cn(
                          'w-12 h-12 rounded-xl flex items-center justify-center',
                          session.completedAt ? 'bg-accent/10' : 'bg-error/10'
                        )}>
                          <Dumbbell className={cn(
                            'w-5 h-5',
                            session.completedAt ? 'text-accent' : 'text-error'
                          )} />
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h4 className="font-medium text-text-primary">{session.dayName}</h4>
                            {session.personalRecords && session.personalRecords.length > 0 && (
                              <Badge variant="warning" className="text-[10px]">PR</Badge>
                            )}
                            <Badge variant="success" className="text-xs">
                              Complétée
                            </Badge>
                          </div>
                          <p className="text-sm text-text-muted">
                            {formatDate(new Date(session.completedAt || session.startedAt))} - {session.exercises.length} exercices
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-semibold text-text-primary">{session.durationMinutes} min</p>
                        <p className="text-xs text-text-muted">Durée</p>
                      </div>
                    </button>
                  ))
                )}
              </div>
            </div>
          </div>
        )}

        {/* Tab Content: Nutrition */}
        {activeTab === 'nutrition' && (
          <div className="space-y-6">
            {assignedDiet ? (
              <>
                <div className="grid grid-cols-2 gap-6">
                  <div className={cn(
                    'p-5 rounded-2xl',
                    'bg-gradient-to-br from-accent/10 via-surface to-surface',
                    'border border-accent/20'
                  )}>
                    <div className="flex items-center gap-2 mb-4">
                      <Flame className="w-5 h-5 text-accent" />
                      <h3 className="font-semibold text-text-primary">Jour d'entraînement</h3>
                    </div>
                    <div className="grid grid-cols-4 gap-4">
                      <div className="text-center">
                        <p className="text-2xl font-bold text-text-primary">{assignedDiet.trainingCalories}</p>
                        <p className="text-xs text-text-muted">Calories</p>
                      </div>
                      <div className="text-center">
                        <p className="text-2xl font-bold text-success">{assignedDiet.trainingMacros.protein}g</p>
                        <p className="text-xs text-text-muted">Protéines</p>
                      </div>
                      <div className="text-center">
                        <p className="text-2xl font-bold text-info">{assignedDiet.trainingMacros.carbs}g</p>
                        <p className="text-xs text-text-muted">Glucides</p>
                      </div>
                      <div className="text-center">
                        <p className="text-2xl font-bold text-warning">{assignedDiet.trainingMacros.fat}g</p>
                        <p className="text-xs text-text-muted">Lipides</p>
                      </div>
                    </div>
                  </div>

                  <div className="p-5 rounded-2xl bg-surface border border-border">
                    <div className="flex items-center gap-2 mb-4">
                      <Clock className="w-5 h-5 text-text-muted" />
                      <h3 className="font-semibold text-text-primary">Jour de repos</h3>
                    </div>
                    <div className="grid grid-cols-4 gap-4">
                      <div className="text-center">
                        <p className="text-2xl font-bold text-text-primary">{assignedDiet.restCalories}</p>
                        <p className="text-xs text-text-muted">Calories</p>
                      </div>
                      <div className="text-center">
                        <p className="text-2xl font-bold text-success">{assignedDiet.restMacros.protein}g</p>
                        <p className="text-xs text-text-muted">Protéines</p>
                      </div>
                      <div className="text-center">
                        <p className="text-2xl font-bold text-info">{assignedDiet.restMacros.carbs}g</p>
                        <p className="text-xs text-text-muted">Glucides</p>
                      </div>
                      <div className="text-center">
                        <p className="text-2xl font-bold text-warning">{assignedDiet.restMacros.fat}g</p>
                        <p className="text-xs text-text-muted">Lipides</p>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="p-5 rounded-2xl bg-surface border border-border">
                  <h3 className="text-lg font-semibold text-text-primary mb-4">
                    Adhérence au plan - 7 derniers jours
                  </h3>
                  <div className="grid grid-cols-7 gap-2">
                    {['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((day, i) => {
                      const adherence = [95, 88, 102, 78, 92, 85, 90][i]
                      return (
                        <div key={day} className="text-center">
                          <div className={cn(
                            'w-full aspect-square rounded-xl flex items-center justify-center mb-2',
                            adherence >= 90 && adherence <= 110 ? 'bg-success/20 text-success' :
                            adherence >= 80 ? 'bg-warning/20 text-warning' : 'bg-error/20 text-error'
                          )}>
                            <span className="font-bold">{adherence}%</span>
                          </div>
                          <span className="text-xs text-text-muted">{day}</span>
                        </div>
                      )
                    })}
                  </div>
                </div>
              </>
            ) : (
              <div className="flex flex-col items-center justify-center py-20 rounded-2xl bg-surface border border-border">
                <div className="w-16 h-16 rounded-2xl bg-success/10 flex items-center justify-center mb-4">
                  <Apple className="w-8 h-8 text-success" />
                </div>
                <h3 className="text-lg font-semibold text-text-primary mb-2">
                  Aucun plan nutrition assigné
                </h3>
                <p className="text-sm text-text-muted mb-6">
                  Assignez un plan nutrition pour suivre l'adhérence
                </p>
                <button
                  onClick={() => setShowAssignDietModal(true)}
                  className={cn(
                    'flex items-center gap-2 px-5 py-3 rounded-xl',
                    'bg-success text-white font-medium',
                    'hover:shadow-[0_0_25px_rgba(34,197,94,0.35)]',
                    'transition-all duration-300'
                  )}
                >
                  <Apple className="w-5 h-5" />
                  Assigner un plan
                </button>
              </div>
            )}
          </div>
        )}

        {/* Tab Content: Health */}
        {activeTab === 'health' && (
          <div className="space-y-6">
            <div className="grid grid-cols-3 gap-4">
              {[
                { label: 'Poids actuel', value: '81.5 kg', change: '-1.0 kg', icon: Scale, color: 'success' },
                { label: 'Sommeil moyen', value: '7.2h', change: '+0.3h', icon: Moon, color: 'info' },
                { label: 'FC repos', value: '58 bpm', change: '-4 bpm', icon: Heart, color: 'accent' },
              ].map((metric) => (
                <div key={metric.label} className="p-5 rounded-2xl bg-surface border border-border">
                  <div className={cn(
                    'w-10 h-10 rounded-xl flex items-center justify-center mb-3',
                    metric.color === 'success' ? 'bg-success/10' :
                    metric.color === 'info' ? 'bg-info/10' : 'bg-accent/10'
                  )}>
                    <metric.icon className={cn(
                      'w-5 h-5',
                      metric.color === 'success' ? 'text-success' :
                      metric.color === 'info' ? 'text-info' : 'text-accent'
                    )} />
                  </div>
                  <p className="text-2xl font-bold text-text-primary">{metric.value}</p>
                  <div className="flex items-center gap-2">
                    <p className="text-sm text-text-muted">{metric.label}</p>
                    <span className="text-xs text-success">{metric.change}</span>
                  </div>
                </div>
              ))}
            </div>

            <div className="grid grid-cols-3 gap-6">
              {/* Weight Chart */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <h3 className="font-semibold text-text-primary mb-4 flex items-center gap-2">
                  <Scale className="w-4 h-4 text-success" />
                  Évolution du poids
                </h3>
                <div className="flex items-end justify-between gap-1 h-32">
                  {mockHealthData.weight.map((w, i) => (
                    <div key={i} className="flex-1 flex flex-col items-center gap-1">
                      <div
                        className="w-full bg-success/30 rounded-t"
                        style={{ height: `${((w - 80) / 5) * 100}%` }}
                      />
                      <span className="text-[10px] text-text-muted">{['L', 'M', 'M', 'J', 'V', 'S', 'D'][i]}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Sleep Chart */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <h3 className="font-semibold text-text-primary mb-4 flex items-center gap-2">
                  <Moon className="w-4 h-4 text-info" />
                  Qualité du sommeil
                </h3>
                <div className="flex items-end justify-between gap-1 h-32">
                  {mockHealthData.sleep.map((s, i) => (
                    <div key={i} className="flex-1 flex flex-col items-center gap-1">
                      <div
                        className={cn(
                          'w-full rounded-t',
                          s >= 7 ? 'bg-success/30' : s >= 6 ? 'bg-warning/30' : 'bg-error/30'
                        )}
                        style={{ height: `${(s / 10) * 100}%` }}
                      />
                      <span className="text-[10px] text-text-muted">{['L', 'M', 'M', 'J', 'V', 'S', 'D'][i]}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Heart Rate Chart */}
              <div className="p-5 rounded-2xl bg-surface border border-border">
                <h3 className="font-semibold text-text-primary mb-4 flex items-center gap-2">
                  <Heart className="w-4 h-4 text-accent" />
                  FC au repos
                </h3>
                <div className="flex items-end justify-between gap-1 h-32">
                  {mockHealthData.restingHR.map((hr, i) => (
                    <div key={i} className="flex-1 flex flex-col items-center gap-1">
                      <div
                        className="w-full bg-accent/30 rounded-t"
                        style={{ height: `${((hr - 50) / 20) * 100}%` }}
                      />
                      <span className="text-[10px] text-text-muted">{['L', 'M', 'M', 'J', 'V', 'S', 'D'][i]}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Tab Content: Progress */}
        {activeTab === 'progress' && (
          <div className="space-y-6">
            <div className="grid grid-cols-4 gap-4">
              {[
                { label: 'Poids initial', value: '85.0 kg', color: 'text-text-muted' },
                { label: 'Poids actuel', value: '81.5 kg', color: 'text-success' },
                { label: 'Objectif', value: '78.0 kg', color: 'text-accent' },
                { label: 'Progression', value: '50%', color: 'text-info' },
              ].map((stat) => (
                <div key={stat.label} className="p-5 rounded-2xl bg-surface border border-border text-center">
                  <p className={cn('text-3xl font-bold mb-1', stat.color)}>{stat.value}</p>
                  <p className="text-sm text-text-muted">{stat.label}</p>
                </div>
              ))}
            </div>

            <div className="p-5 rounded-2xl bg-surface border border-border">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-lg font-semibold text-text-primary flex items-center gap-2">
                  <LineChart className="w-5 h-5 text-accent" />
                  Évolution globale
                </h3>
                <div className="flex items-center gap-4 text-sm">
                  <span className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-accent" />
                    Poids
                  </span>
                  <span className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-success" />
                    Force
                  </span>
                </div>
              </div>

              <div className="h-64 flex items-end justify-between gap-2 px-4">
                {[...Array(12)].map((_, i) => (
                  <div key={i} className="flex-1 flex flex-col items-center gap-2">
                    <div className="w-full space-y-1">
                      <div
                        className="w-full bg-accent rounded-t"
                        style={{ height: `${100 - (i * 2)}px` }}
                      />
                      <div
                        className="w-full bg-success rounded-t"
                        style={{ height: `${40 + (i * 5)}px` }}
                      />
                    </div>
                    <span className="text-[10px] text-text-muted">S{i + 1}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="p-5 rounded-2xl bg-surface border border-border">
              <h3 className="text-lg font-semibold text-text-primary mb-4">Records personnels</h3>
              <div className="grid grid-cols-3 gap-4">
                {[
                  { exercise: 'Développé couché', weight: '100 kg', date: 'il y a 2 sem' },
                  { exercise: 'Squat', weight: '140 kg', date: 'il y a 1 sem' },
                  { exercise: 'Soulevé de terre', weight: '160 kg', date: 'il y a 3 sem' },
                ].map((pr) => (
                  <div key={pr.exercise} className="p-4 rounded-xl bg-surface-elevated">
                    <p className="font-medium text-text-primary mb-1">{pr.exercise}</p>
                    <p className="text-2xl font-bold text-accent mb-1">{pr.weight}</p>
                    <p className="text-xs text-text-muted">{pr.date}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Modals */}
      <EditStudentModal
        isOpen={showEditModal}
        onClose={() => setShowEditModal(false)}
        student={student}
      />

      <AssignProgramModal
        isOpen={showAssignProgramModal}
        onClose={() => setShowAssignProgramModal(false)}
        student={student}
      />

      <AssignDietModal
        isOpen={showAssignDietModal}
        onClose={() => setShowAssignDietModal(false)}
        student={student}
      />

      {/* Session Detail Modal */}
      <SessionDetailModal
        isOpen={selectedSession !== null}
        onClose={() => setSelectedSession(null)}
        session={selectedSession}
      />

      {/* Delete Confirmation */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setShowDeleteConfirm(false)}
          />
          <div className={cn(
            'relative w-full max-w-md mx-4 p-6',
            'bg-surface border border-border rounded-2xl',
            'shadow-2xl animate-[fadeIn_0.2s_ease-out]'
          )}>
            <div className="flex items-center gap-4 mb-4">
              <div className="w-12 h-12 rounded-xl bg-error/10 flex items-center justify-center">
                <Trash2 className="w-6 h-6 text-error" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-text-primary">Supprimer l'élève</h3>
                <p className="text-sm text-text-muted">Cette action est irréversible</p>
              </div>
            </div>
            <p className="text-text-secondary mb-6">
              Êtes-vous sûr de vouloir supprimer "{student.name}" ? Toutes les données associées seront perdues.
            </p>
            <div className="flex items-center justify-end gap-3">
              <button
                onClick={() => setShowDeleteConfirm(false)}
                className={cn(
                  'h-10 px-4 rounded-xl font-medium',
                  'bg-surface-elevated border border-border',
                  'text-text-secondary hover:text-text-primary',
                  'transition-all duration-200'
                )}
              >
                Annuler
              </button>
              <button
                onClick={handleDelete}
                className={cn(
                  'flex items-center gap-2 h-10 px-4 rounded-xl font-medium',
                  'bg-error text-white hover:bg-error/90',
                  'transition-all duration-200'
                )}
              >
                <Trash2 className="w-4 h-4" />
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
