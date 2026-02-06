import { useState } from 'react'
import { Link } from 'react-router-dom'
import {
  LayoutGrid,
  List,
  Plus,
  ChevronRight,
  Flame,
  TrendingUp,
  Users,
  UserPlus,
  Filter,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Badge, Avatar } from '@/components/ui'
import { AddStudentModal } from '@/components/modals/add-student-modal'
import { useStudentsStore } from '@/store/students-store'
import { formatRelativeTime } from '@/lib/utils'
import { cn } from '@/lib/utils'
import { goalConfig, goalFilterConfig, type FilterGoalType } from '@/constants/goals'

type ViewMode = 'grid' | 'list'
type FilterGoal = FilterGoalType

export function StudentsListPage() {
  const { students } = useStudentsStore()
  const [viewMode, setViewMode] = useState<ViewMode>('grid')
  const [searchQuery, setSearchQuery] = useState('')
  const [filterGoal, setFilterGoal] = useState<FilterGoal>('all')
  const [isAddModalOpen, setIsAddModalOpen] = useState(false)

  // Filter students
  const filteredStudents = students.filter((student) => {
    const matchesSearch = student.name
      .toLowerCase()
      .includes(searchQuery.toLowerCase())
    const matchesGoal = filterGoal === 'all' || student.goal === filterGoal
    return matchesSearch && matchesGoal
  })

  // Stats
  const totalActive = students.length
  const avgCompliance = students.length > 0
    ? Math.round(students.reduce((acc, s) => acc + s.stats.complianceRate, 0) / students.length)
    : 0
  const totalWorkoutsWeek = students.reduce((acc, s) => acc + s.stats.thisWeekWorkouts, 0)

  return (
    <div className="min-h-screen">
      <Header
        title="Élèves"
        subtitle={`${students.length} élèves actifs`}
        action={
          <button
            onClick={() => setIsAddModalOpen(true)}
            className={cn(
            'flex items-center gap-2 h-11 px-5 rounded-xl font-semibold text-white',
            'bg-gradient-to-r from-accent to-[#ff8f5c]',
            'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
            'transition-all duration-300'
          )}>
            <UserPlus className="w-5 h-5" />
            Ajouter un élève
          </button>
        }
      />

      <div className="p-8 space-y-6">
        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-4">
          {[
            { label: 'Élèves actifs', value: totalActive, icon: Users, color: 'accent' },
            { label: 'Compliance moyenne', value: `${avgCompliance}%`, icon: TrendingUp, color: 'success' },
            { label: 'Séances cette semaine', value: totalWorkoutsWeek, icon: Flame, color: 'warning' },
          ].map((stat, index) => (
            <div
              key={stat.label}
              className={cn(
                'flex items-center gap-4 p-4 rounded-xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out_forwards] opacity-0'
              )}
              style={{ animationDelay: `${index * 50}ms` }}
            >
              <div className={cn(
                'w-12 h-12 rounded-xl flex items-center justify-center',
                stat.color === 'accent' ? 'bg-accent/10' :
                stat.color === 'success' ? 'bg-success/10' : 'bg-warning/10'
              )}>
                <stat.icon className={cn(
                  'w-6 h-6',
                  stat.color === 'accent' ? 'text-accent' :
                  stat.color === 'success' ? 'text-success' : 'text-warning'
                )} />
              </div>
              <div>
                <p className="text-2xl font-bold text-text-primary">{stat.value}</p>
                <p className="text-sm text-text-muted">{stat.label}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Filters Bar */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            {/* Goal Filter */}
            <div className="flex items-center gap-1 p-1.5 rounded-xl bg-surface border border-border">
              <Filter className="w-4 h-4 text-text-muted mx-2" />
              {(['all', 'bulk', 'cut', 'maintain'] as FilterGoal[]).map((goal) => (
                <button
                  key={goal}
                  onClick={() => setFilterGoal(goal)}
                  className={cn(
                    'px-3.5 py-2 text-sm font-medium rounded-lg transition-all duration-200',
                    filterGoal === goal
                      ? 'bg-accent text-white shadow-sm'
                      : 'text-text-secondary hover:text-text-primary hover:bg-surface-elevated'
                  )}
                >
                  {goalFilterConfig[goal].label}
                </button>
              ))}
            </div>
          </div>

          {/* View Toggle */}
          <div className="flex items-center gap-1 p-1.5 rounded-xl bg-surface border border-border">
            <button
              onClick={() => setViewMode('grid')}
              className={cn(
                'p-2.5 rounded-lg transition-all duration-200',
                viewMode === 'grid'
                  ? 'bg-accent text-white'
                  : 'text-text-muted hover:text-text-primary hover:bg-surface-elevated'
              )}
            >
              <LayoutGrid className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={cn(
                'p-2.5 rounded-lg transition-all duration-200',
                viewMode === 'list'
                  ? 'bg-accent text-white'
                  : 'text-text-muted hover:text-text-primary hover:bg-surface-elevated'
              )}
            >
              <List className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Results count */}
        {filterGoal !== 'all' || searchQuery ? (
          <div className="flex items-center gap-2 text-sm text-text-muted">
            <span>{filteredStudents.length} résultat{filteredStudents.length > 1 ? 's' : ''}</span>
            {(filterGoal !== 'all' || searchQuery) && (
              <button
                onClick={() => { setFilterGoal('all'); setSearchQuery('') }}
                className="text-accent hover:text-accent-hover transition-colors"
              >
                Effacer les filtres
              </button>
            )}
          </div>
        ) : null}

        {/* Grid View */}
        {viewMode === 'grid' && (
          <div className="grid grid-cols-3 gap-5">
            {filteredStudents.map((student, index) => (
              <Link
                key={student.id}
                to={`/students/${student.id}`}
                className={cn(
                  'group relative p-5 rounded-2xl overflow-hidden',
                  'bg-surface border border-border',
                  'hover:border-accent/30 hover:shadow-[0_0_30px_rgba(255,107,53,0.1)]',
                  'transition-all duration-300',
                  'animate-[fadeIn_0.4s_ease-out_forwards] opacity-0'
                )}
                style={{ animationDelay: `${index * 30}ms` }}
              >
                {/* Hover glow */}
                <div className="absolute top-0 right-0 w-32 h-32 bg-accent/5 rounded-full blur-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

                <div className="relative">
                  {/* Header */}
                  <div className="flex items-start justify-between mb-5">
                    <div className="flex items-center gap-3">
                      <div className="relative">
                        <Avatar name={student.name} size="lg" />
                        {/* Online indicator */}
                        <div className={cn(
                          'absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full border-2 border-surface',
                          student.stats.thisWeekWorkouts > 0 ? 'bg-success' : 'bg-text-muted'
                        )} />
                      </div>
                      <div>
                        <h3 className="font-semibold text-text-primary group-hover:text-accent transition-colors">
                          {student.name}
                        </h3>
                        <p className="text-sm text-text-muted">{student.email}</p>
                      </div>
                    </div>
                    <Badge
                      variant={
                        student.goal === 'bulk' || student.goal === 'recomp' ? 'success' :
                        student.goal === 'cut' ? 'warning' :
                        student.goal === 'strength' ? 'default' : 'info'
                      }
                      className="text-xs"
                    >
                      {goalConfig[student.goal].label}
                    </Badge>
                  </div>

                  {/* Stats Grid */}
                  <div className="grid grid-cols-3 gap-3 mb-5">
                    <div className="p-3 rounded-xl bg-surface-elevated/50">
                      <p className="text-[10px] uppercase tracking-wider text-text-muted mb-1">Streak</p>
                      <div className="flex items-center gap-1.5">
                        <Flame className="w-4 h-4 text-accent" />
                        <span className="text-lg font-bold text-text-primary">
                          {student.currentStreak}
                        </span>
                        <span className="text-xs text-text-muted">j</span>
                      </div>
                    </div>
                    <div className="p-3 rounded-xl bg-surface-elevated/50">
                      <p className="text-[10px] uppercase tracking-wider text-text-muted mb-1">Séances</p>
                      <p className="text-lg font-bold text-text-primary">
                        {student.stats.totalWorkouts}
                      </p>
                    </div>
                    <div className="p-3 rounded-xl bg-surface-elevated/50">
                      <p className="text-[10px] uppercase tracking-wider text-text-muted mb-1">Compliance</p>
                      <div className="flex items-center gap-1.5">
                        <span className={cn(
                          'text-lg font-bold',
                          student.stats.complianceRate > 80 ? 'text-success' :
                          student.stats.complianceRate > 60 ? 'text-warning' : 'text-error'
                        )}>
                          {student.stats.complianceRate}%
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Footer */}
                  <div className="flex items-center justify-between pt-4 border-t border-border/50">
                    <p className="text-xs text-text-muted">
                      Dernière séance: {student.lastWorkout
                        ? formatRelativeTime(student.lastWorkout)
                        : 'Jamais'}
                    </p>
                    <ChevronRight className={cn(
                      'w-5 h-5 text-text-muted transition-all duration-200',
                      'group-hover:text-accent group-hover:translate-x-1'
                    )} />
                  </div>
                </div>
              </Link>
            ))}

            {/* Add Student Card */}
            <button
              onClick={() => setIsAddModalOpen(true)}
              className={cn(
              'flex flex-col items-center justify-center gap-3 p-8 rounded-2xl',
              'border-2 border-dashed border-border',
              'hover:border-accent/50 hover:bg-accent/5',
              'transition-all duration-300 min-h-[280px]'
            )}>
              <div className="w-14 h-14 rounded-2xl bg-accent/10 flex items-center justify-center">
                <Plus className="w-7 h-7 text-accent" />
              </div>
              <span className="text-sm font-medium text-text-muted">Ajouter un élève</span>
            </button>
          </div>
        )}

        {/* List View */}
        {viewMode === 'list' && (
          <div className="rounded-2xl bg-surface border border-border overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="border-b border-border bg-surface-elevated/30">
                  <th className="text-left text-[10px] font-semibold text-text-muted uppercase tracking-wider px-5 py-4">
                    Élève
                  </th>
                  <th className="text-left text-[10px] font-semibold text-text-muted uppercase tracking-wider px-5 py-4">
                    Objectif
                  </th>
                  <th className="text-left text-[10px] font-semibold text-text-muted uppercase tracking-wider px-5 py-4">
                    Streak
                  </th>
                  <th className="text-left text-[10px] font-semibold text-text-muted uppercase tracking-wider px-5 py-4">
                    Séances
                  </th>
                  <th className="text-left text-[10px] font-semibold text-text-muted uppercase tracking-wider px-5 py-4">
                    Compliance
                  </th>
                  <th className="text-left text-[10px] font-semibold text-text-muted uppercase tracking-wider px-5 py-4">
                    Dernière séance
                  </th>
                  <th className="w-12"></th>
                </tr>
              </thead>
              <tbody>
                {filteredStudents.map((student, index) => (
                  <tr
                    key={student.id}
                    className={cn(
                      'group border-b border-border/50 last:border-0',
                      'hover:bg-surface-elevated/50 transition-colors',
                      'animate-[fadeIn_0.3s_ease-out_forwards] opacity-0'
                    )}
                    style={{ animationDelay: `${index * 20}ms` }}
                  >
                    <td className="px-5 py-4">
                      <Link
                        to={`/students/${student.id}`}
                        className="flex items-center gap-3"
                      >
                        <div className="relative">
                          <Avatar name={student.name} size="sm" />
                          <div className={cn(
                            'absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-surface',
                            student.stats.thisWeekWorkouts > 0 ? 'bg-success' : 'bg-text-muted'
                          )} />
                        </div>
                        <div>
                          <p className="font-medium text-text-primary group-hover:text-accent transition-colors">
                            {student.name}
                          </p>
                          <p className="text-sm text-text-muted">{student.email}</p>
                        </div>
                      </Link>
                    </td>
                    <td className="px-5 py-4">
                      <Badge
                        variant={
                          student.goal === 'bulk' ? 'success' :
                          student.goal === 'cut' ? 'warning' : 'info'
                        }
                      >
                        {goalConfig[student.goal].label}
                      </Badge>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-1.5">
                        <Flame className="w-4 h-4 text-accent" />
                        <span className="font-semibold text-text-primary">{student.currentStreak}</span>
                        <span className="text-text-muted text-sm">jours</span>
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <span className="font-semibold text-text-primary">{student.stats.totalWorkouts}</span>
                      <span className="text-text-muted text-sm ml-1.5">
                        ({student.stats.thisWeekWorkouts}/sem)
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-20 h-2 rounded-full bg-surface-elevated overflow-hidden">
                          <div
                            className={cn(
                              'h-full rounded-full transition-all duration-500',
                              student.stats.complianceRate > 80 ? 'bg-success' :
                              student.stats.complianceRate > 60 ? 'bg-warning' : 'bg-error'
                            )}
                            style={{ width: `${student.stats.complianceRate}%` }}
                          />
                        </div>
                        <span className={cn(
                          'text-sm font-semibold',
                          student.stats.complianceRate > 80 ? 'text-success' :
                          student.stats.complianceRate > 60 ? 'text-warning' : 'text-error'
                        )}>
                          {student.stats.complianceRate}%
                        </span>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-sm text-text-muted">
                      {student.lastWorkout
                        ? formatRelativeTime(student.lastWorkout)
                        : 'Jamais'}
                    </td>
                    <td className="px-5 py-4">
                      <Link
                        to={`/students/${student.id}`}
                        className={cn(
                          'p-2 rounded-lg transition-all duration-200',
                          'text-text-muted hover:text-accent hover:bg-accent/10'
                        )}
                      >
                        <ChevronRight className="w-4 h-4" />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Empty State */}
        {filteredStudents.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20">
            <div className="w-20 h-20 rounded-2xl bg-surface-elevated flex items-center justify-center mb-5">
              <Users className="w-10 h-10 text-text-muted" />
            </div>
            <h3 className="text-lg font-semibold text-text-primary mb-2">Aucun élève trouvé</h3>
            <p className="text-sm text-text-muted mb-6">
              {searchQuery || filterGoal !== 'all'
                ? 'Essayez de modifier vos filtres de recherche'
                : 'Commencez par ajouter votre premier élève'}
            </p>
            <button
              onClick={() => setIsAddModalOpen(true)}
              className={cn(
              'flex items-center gap-2 px-5 py-3 rounded-xl',
              'bg-accent text-white font-medium',
              'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
              'transition-all duration-300'
            )}>
              <Plus className="w-5 h-5" />
              Ajouter un élève
            </button>
          </div>
        )}
      </div>

      {/* Add Student Modal */}
      <AddStudentModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
      />
    </div>
  )
}
