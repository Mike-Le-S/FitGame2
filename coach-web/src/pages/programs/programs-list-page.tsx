import { useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Plus,
  Dumbbell,
  Users,
  Calendar,
  ChevronRight,
  MoreVertical,
  Search,
  Filter,
  Zap,
  Copy,
  Trash2,
  Edit3,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Badge } from '@/components/ui'
import { useProgramsStore } from '@/store/programs-store'
import { formatDate } from '@/lib/utils'
import { cn } from '@/lib/utils'
import type { Goal } from '@/types'

type FilterGoal = Goal | 'all'

const goalConfig = {
  all: { label: 'Tous', color: 'text-text-secondary' },
  bulk: { label: 'Masse', color: 'text-success' },
  cut: { label: 'Sèche', color: 'text-warning' },
  maintain: { label: 'Maintien', color: 'text-info' },
}

export function ProgramsListPage() {
  const { programs } = useProgramsStore()
  const [searchQuery, setSearchQuery] = useState('')
  const [filterGoal, setFilterGoal] = useState<FilterGoal>('all')
  const [openMenuId, setOpenMenuId] = useState<string | null>(null)

  const filteredPrograms = programs.filter((program) => {
    const matchesSearch = program.name.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesGoal = filterGoal === 'all' || program.goal === filterGoal
    return matchesSearch && matchesGoal
  })

  // Stats
  const totalPrograms = programs.length
  const totalAssigned = programs.reduce((acc, p) => acc + p.assignedStudentIds.length, 0)

  return (
    <div className="min-h-screen">
      <Header
        title="Programmes"
        subtitle={`${programs.length} programmes créés`}
        action={
          <Link
            to="/programs/create"
            className={cn(
              'flex items-center gap-2 h-11 px-5 rounded-xl font-semibold text-white',
              'bg-gradient-to-r from-accent to-[#ff8f5c]',
              'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
              'transition-all duration-300'
            )}
          >
            <Plus className="w-5 h-5" />
            Créer un programme
          </Link>
        }
      />

      <div className="p-8 space-y-6">
        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-4">
          {[
            { label: 'Programmes actifs', value: totalPrograms, icon: Dumbbell, color: 'accent' },
            { label: 'Élèves assignés', value: totalAssigned, icon: Users, color: 'success' },
            { label: 'Durée moyenne', value: `${Math.round(programs.reduce((acc, p) => acc + p.durationWeeks, 0) / programs.length || 0)} sem`, icon: Calendar, color: 'info' },
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
                stat.color === 'success' ? 'bg-success/10' : 'bg-info/10'
              )}>
                <stat.icon className={cn(
                  'w-6 h-6',
                  stat.color === 'accent' ? 'text-accent' :
                  stat.color === 'success' ? 'text-success' : 'text-info'
                )} />
              </div>
              <div>
                <p className="text-2xl font-bold text-text-primary">{stat.value}</p>
                <p className="text-sm text-text-muted">{stat.label}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Filters */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            {/* Search */}
            <div className="relative group">
              <Search className="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-text-muted group-focus-within:text-accent transition-colors" />
              <input
                type="text"
                placeholder="Rechercher un programme..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className={cn(
                  'w-72 h-11 pl-11 pr-4 rounded-xl',
                  'bg-surface-elevated border border-border',
                  'text-text-primary placeholder:text-text-muted',
                  'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                  'transition-all duration-200'
                )}
              />
            </div>

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
                  {goalConfig[goal].label}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Programs Grid */}
        <div className="grid grid-cols-2 gap-5">
          {filteredPrograms.map((program, index) => (
            <div
              key={program.id}
              className={cn(
                'group relative p-5 rounded-2xl overflow-hidden',
                'bg-surface border border-border',
                'hover:border-accent/30 hover:shadow-[0_0_30px_rgba(255,107,53,0.1)]',
                'transition-all duration-300',
                'animate-[fadeIn_0.4s_ease-out_forwards] opacity-0'
              )}
              style={{ animationDelay: `${index * 50}ms` }}
            >
              {/* Hover glow */}
              <div className="absolute top-0 right-0 w-32 h-32 bg-accent/5 rounded-full blur-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

              <div className="relative">
                {/* Header */}
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-4">
                    <div className={cn(
                      'w-14 h-14 rounded-xl flex items-center justify-center',
                      'bg-gradient-to-br from-accent/20 to-accent/5'
                    )}>
                      <Dumbbell className="w-7 h-7 text-accent" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-text-primary group-hover:text-accent transition-colors">
                        {program.name}
                      </h3>
                      <p className="text-sm text-text-muted line-clamp-1">
                        {program.description || 'Aucune description'}
                      </p>
                    </div>
                  </div>

                  {/* Menu */}
                  <div className="relative">
                    <button
                      onClick={(e) => {
                        e.preventDefault()
                        setOpenMenuId(openMenuId === program.id ? null : program.id)
                      }}
                      className={cn(
                        'p-2 rounded-lg transition-all duration-200',
                        'text-text-muted hover:text-text-primary hover:bg-surface-elevated'
                      )}
                    >
                      <MoreVertical className="w-4 h-4" />
                    </button>

                    {openMenuId === program.id && (
                      <div className={cn(
                        'absolute top-full right-0 mt-1 w-40',
                        'bg-surface border border-border rounded-xl shadow-xl',
                        'animate-[fadeIn_0.15s_ease-out]',
                        'z-10'
                      )}>
                        <div className="p-1">
                          <button className="w-full flex items-center gap-2 px-3 py-2 text-sm text-text-secondary hover:text-text-primary hover:bg-surface-elevated rounded-lg transition-colors">
                            <Edit3 className="w-4 h-4" />
                            Modifier
                          </button>
                          <button className="w-full flex items-center gap-2 px-3 py-2 text-sm text-text-secondary hover:text-text-primary hover:bg-surface-elevated rounded-lg transition-colors">
                            <Copy className="w-4 h-4" />
                            Dupliquer
                          </button>
                          <button className="w-full flex items-center gap-2 px-3 py-2 text-sm text-error hover:bg-error/10 rounded-lg transition-colors">
                            <Trash2 className="w-4 h-4" />
                            Supprimer
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Stats */}
                <div className="flex items-center gap-3 mb-4">
                  <Badge
                    variant={
                      program.goal === 'bulk' ? 'success' :
                      program.goal === 'cut' ? 'warning' : 'info'
                    }
                  >
                    {goalConfig[program.goal].label}
                  </Badge>
                  <span className="flex items-center gap-1.5 text-sm text-text-secondary">
                    <Calendar className="w-4 h-4" />
                    {program.durationWeeks} semaines
                  </span>
                  <span className="flex items-center gap-1.5 text-sm text-text-secondary">
                    <Users className="w-4 h-4" />
                    {program.assignedStudentIds.length} élève{program.assignedStudentIds.length > 1 ? 's' : ''}
                  </span>
                  {program.deloadFrequency && (
                    <span className="flex items-center gap-1.5 text-sm text-text-secondary">
                      <Zap className="w-4 h-4" />
                      Deload {program.deloadFrequency}sem
                    </span>
                  )}
                </div>

                {/* Days preview */}
                {program.days.length > 0 && (
                  <div className="flex flex-wrap gap-2 mb-4">
                    {program.days.slice(0, 4).map((day) => (
                      <span
                        key={day.id}
                        className={cn(
                          'px-2.5 py-1 rounded-lg text-xs font-medium',
                          day.isRestDay
                            ? 'bg-surface-elevated text-text-muted'
                            : 'bg-accent/10 text-accent'
                        )}
                      >
                        {day.name}
                      </span>
                    ))}
                    {program.days.length > 4 && (
                      <span className="px-2.5 py-1 rounded-lg text-xs font-medium bg-surface-elevated text-text-muted">
                        +{program.days.length - 4}
                      </span>
                    )}
                  </div>
                )}

                {/* Footer */}
                <div className="flex items-center justify-between pt-4 border-t border-border/50">
                  <p className="text-xs text-text-muted">
                    Modifié le {formatDate(program.updatedAt)}
                  </p>
                  <Link
                    to={`/programs/${program.id}`}
                    className={cn(
                      'flex items-center gap-1.5 text-sm font-medium',
                      'text-accent hover:text-accent-hover transition-colors'
                    )}
                  >
                    Voir détails
                    <ChevronRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                  </Link>
                </div>
              </div>
            </div>
          ))}

          {/* Add Program Card */}
          <Link
            to="/programs/create"
            className={cn(
              'flex flex-col items-center justify-center gap-4 p-8 rounded-2xl min-h-[280px]',
              'border-2 border-dashed border-border',
              'hover:border-accent/50 hover:bg-accent/5',
              'transition-all duration-300'
            )}
          >
            <div className="w-16 h-16 rounded-2xl bg-accent/10 flex items-center justify-center">
              <Plus className="w-8 h-8 text-accent" />
            </div>
            <span className="text-sm font-medium text-text-muted">Créer un programme</span>
          </Link>
        </div>

        {/* Empty State */}
        {filteredPrograms.length === 0 && programs.length > 0 && (
          <div className="flex flex-col items-center justify-center py-20">
            <div className="w-20 h-20 rounded-2xl bg-surface-elevated flex items-center justify-center mb-5">
              <Dumbbell className="w-10 h-10 text-text-muted" />
            </div>
            <h3 className="text-lg font-semibold text-text-primary mb-2">Aucun résultat</h3>
            <p className="text-sm text-text-muted mb-6">
              Essayez de modifier vos filtres de recherche
            </p>
          </div>
        )}

        {programs.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20 rounded-2xl bg-surface border border-border">
            <div className="w-20 h-20 rounded-2xl bg-accent/10 flex items-center justify-center mb-5">
              <Dumbbell className="w-10 h-10 text-accent" />
            </div>
            <h3 className="text-lg font-semibold text-text-primary mb-2">
              Aucun programme
            </h3>
            <p className="text-sm text-text-muted mb-6">
              Créez votre premier programme d'entraînement
            </p>
            <Link
              to="/programs/create"
              className={cn(
                'flex items-center gap-2 px-5 py-3 rounded-xl',
                'bg-accent text-white font-medium',
                'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
                'transition-all duration-300'
              )}
            >
              <Plus className="w-5 h-5" />
              Créer un programme
            </Link>
          </div>
        )}
      </div>
    </div>
  )
}
