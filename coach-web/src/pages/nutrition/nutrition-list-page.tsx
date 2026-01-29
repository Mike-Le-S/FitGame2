import { useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Plus,
  Apple,
  Users,
  ChevronRight,
  MoreVertical,
  Flame,
  Search,
  Filter,
  Salad,
  Target,
  Edit3,
  Copy,
  Trash2,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Badge } from '@/components/ui'
import { useNutritionStore } from '@/store/nutrition-store'
import { formatDate, cn } from '@/lib/utils'
import type { Goal } from '@/types'

type FilterGoal = Goal | 'all'

const goalConfig = {
  all: { label: 'Tous', color: 'text-text-secondary' },
  bulk: { label: 'Masse', color: 'text-success' },
  cut: { label: 'Sèche', color: 'text-warning' },
  maintain: { label: 'Maintien', color: 'text-info' },
}

export function NutritionListPage() {
  const { dietPlans } = useNutritionStore()
  const [searchQuery, setSearchQuery] = useState('')
  const [filterGoal, setFilterGoal] = useState<FilterGoal>('all')
  const [openMenuId, setOpenMenuId] = useState<string | null>(null)

  const filteredPlans = dietPlans.filter((plan) => {
    const matchesSearch = plan.name.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesGoal = filterGoal === 'all' || plan.goal === filterGoal
    return matchesSearch && matchesGoal
  })

  // Stats
  const totalPlans = dietPlans.length
  const totalAssigned = dietPlans.reduce((acc, p) => acc + p.assignedStudentIds.length, 0)
  const avgCalories = Math.round(
    dietPlans.reduce((acc, p) => acc + p.trainingCalories, 0) / dietPlans.length || 0
  )

  return (
    <div className="min-h-screen">
      <Header
        title="Plans Nutrition"
        subtitle={`${dietPlans.length} plan${dietPlans.length > 1 ? 's' : ''} créé${dietPlans.length > 1 ? 's' : ''}`}
        action={
          <Link
            to="/nutrition/create"
            className={cn(
              'flex items-center gap-2 h-11 px-5 rounded-xl font-semibold text-white',
              'bg-gradient-to-r from-success to-[#4ade80]',
              'hover:shadow-[0_0_25px_rgba(34,197,94,0.35)]',
              'transition-all duration-300'
            )}
          >
            <Plus className="w-5 h-5" />
            Créer un plan
          </Link>
        }
      />

      <div className="p-8 space-y-6">
        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-4">
          {[
            { label: 'Plans actifs', value: totalPlans, icon: Salad, color: 'success' },
            { label: 'Élèves suivis', value: totalAssigned, icon: Users, color: 'accent' },
            { label: 'Kcal moyenne', value: avgCalories || '-', icon: Flame, color: 'warning' },
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
                stat.color === 'success' ? 'bg-success/10' :
                stat.color === 'accent' ? 'bg-accent/10' : 'bg-warning/10'
              )}>
                <stat.icon className={cn(
                  'w-6 h-6',
                  stat.color === 'success' ? 'text-success' :
                  stat.color === 'accent' ? 'text-accent' : 'text-warning'
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
              <Search className="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-text-muted group-focus-within:text-success transition-colors" />
              <input
                type="text"
                placeholder="Rechercher un plan..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className={cn(
                  'w-72 h-11 pl-11 pr-4 rounded-xl',
                  'bg-surface-elevated border border-border',
                  'text-text-primary placeholder:text-text-muted',
                  'focus:outline-none focus:border-success focus:ring-2 focus:ring-success/20',
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
                      ? 'bg-success text-white shadow-sm'
                      : 'text-text-secondary hover:text-text-primary hover:bg-surface-elevated'
                  )}
                >
                  {goalConfig[goal].label}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Plans Grid */}
        <div className="grid grid-cols-2 gap-5">
          {filteredPlans.map((plan, index) => (
            <div
              key={plan.id}
              className={cn(
                'group relative p-5 rounded-2xl overflow-hidden',
                'bg-surface border border-border',
                'hover:border-success/30 hover:shadow-[0_0_30px_rgba(34,197,94,0.1)]',
                'transition-all duration-300',
                'animate-[fadeIn_0.4s_ease-out_forwards] opacity-0'
              )}
              style={{ animationDelay: `${index * 50}ms` }}
            >
              {/* Hover glow */}
              <div className="absolute top-0 right-0 w-32 h-32 bg-success/5 rounded-full blur-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

              <div className="relative">
                {/* Header */}
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-4">
                    <div className={cn(
                      'w-14 h-14 rounded-xl flex items-center justify-center',
                      'bg-gradient-to-br from-success/20 to-success/5'
                    )}>
                      <Apple className="w-7 h-7 text-success" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-text-primary group-hover:text-success transition-colors">
                        {plan.name}
                      </h3>
                      <p className="text-sm text-text-muted">
                        {plan.meals.length} repas/jour
                      </p>
                    </div>
                  </div>

                  {/* Menu */}
                  <div className="relative">
                    <button
                      onClick={(e) => {
                        e.preventDefault()
                        setOpenMenuId(openMenuId === plan.id ? null : plan.id)
                      }}
                      className={cn(
                        'p-2 rounded-lg transition-all duration-200',
                        'text-text-muted hover:text-text-primary hover:bg-surface-elevated'
                      )}
                    >
                      <MoreVertical className="w-4 h-4" />
                    </button>

                    {openMenuId === plan.id && (
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

                {/* Badges */}
                <div className="flex items-center gap-3 mb-4">
                  <Badge
                    variant={
                      plan.goal === 'bulk' ? 'success' :
                      plan.goal === 'cut' ? 'warning' : 'info'
                    }
                  >
                    <Target className="w-3 h-3 mr-1" />
                    {plan.goal === 'bulk' ? 'Prise de masse' :
                     plan.goal === 'cut' ? 'Sèche' : 'Maintien'}
                  </Badge>
                  <span className="flex items-center gap-1.5 text-sm text-text-secondary">
                    <Users className="w-4 h-4" />
                    {plan.assignedStudentIds.length} élève{plan.assignedStudentIds.length > 1 ? 's' : ''}
                  </span>
                </div>

                {/* Calories Cards */}
                <div className="grid grid-cols-2 gap-3 mb-4">
                  <div className={cn(
                    'p-3 rounded-xl',
                    'bg-gradient-to-br from-accent/10 to-transparent',
                    'border border-accent/10'
                  )}>
                    <div className="flex items-center gap-2 mb-2">
                      <Flame className="w-4 h-4 text-accent" />
                      <span className="text-xs font-medium text-text-muted">Training</span>
                    </div>
                    <p className="text-xl font-bold text-text-primary">{plan.trainingCalories}</p>
                    <p className="text-xs text-text-muted">
                      P:{plan.trainingMacros.protein} C:{plan.trainingMacros.carbs} L:{plan.trainingMacros.fat}
                    </p>
                  </div>
                  <div className={cn(
                    'p-3 rounded-xl',
                    'bg-surface-elevated border border-border'
                  )}>
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-xs font-medium text-text-muted">Repos</span>
                    </div>
                    <p className="text-xl font-bold text-text-primary">{plan.restCalories}</p>
                    <p className="text-xs text-text-muted">
                      P:{plan.restMacros.protein} C:{plan.restMacros.carbs} L:{plan.restMacros.fat}
                    </p>
                  </div>
                </div>

                {/* Footer */}
                <div className="flex items-center justify-between pt-4 border-t border-border/50">
                  <p className="text-xs text-text-muted">
                    Modifié le {formatDate(plan.updatedAt)}
                  </p>
                  <Link
                    to={`/nutrition/${plan.id}`}
                    className={cn(
                      'flex items-center gap-1.5 text-sm font-medium',
                      'text-success hover:text-[#4ade80] transition-colors'
                    )}
                  >
                    Voir détails
                    <ChevronRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                  </Link>
                </div>
              </div>
            </div>
          ))}

          {/* Add Plan Card */}
          <Link
            to="/nutrition/create"
            className={cn(
              'flex flex-col items-center justify-center gap-4 p-8 rounded-2xl min-h-[320px]',
              'border-2 border-dashed border-border',
              'hover:border-success/50 hover:bg-success/5',
              'transition-all duration-300'
            )}
          >
            <div className="w-16 h-16 rounded-2xl bg-success/10 flex items-center justify-center">
              <Plus className="w-8 h-8 text-success" />
            </div>
            <span className="text-sm font-medium text-text-muted">Créer un plan</span>
          </Link>
        </div>

        {/* Empty State */}
        {filteredPlans.length === 0 && dietPlans.length > 0 && (
          <div className="flex flex-col items-center justify-center py-20">
            <div className="w-20 h-20 rounded-2xl bg-surface-elevated flex items-center justify-center mb-5">
              <Apple className="w-10 h-10 text-text-muted" />
            </div>
            <h3 className="text-lg font-semibold text-text-primary mb-2">Aucun résultat</h3>
            <p className="text-sm text-text-muted mb-6">
              Essayez de modifier vos filtres de recherche
            </p>
          </div>
        )}

        {dietPlans.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20 rounded-2xl bg-surface border border-border">
            <div className="w-20 h-20 rounded-2xl bg-success/10 flex items-center justify-center mb-5">
              <Apple className="w-10 h-10 text-success" />
            </div>
            <h3 className="text-lg font-semibold text-text-primary mb-2">
              Aucun plan nutrition
            </h3>
            <p className="text-sm text-text-muted mb-6">
              Créez votre premier plan nutritionnel
            </p>
            <Link
              to="/nutrition/create"
              className={cn(
                'flex items-center gap-2 px-5 py-3 rounded-xl',
                'bg-success text-white font-medium',
                'hover:shadow-[0_0_25px_rgba(34,197,94,0.35)]',
                'transition-all duration-300'
              )}
            >
              <Plus className="w-5 h-5" />
              Créer un plan
            </Link>
          </div>
        )}
      </div>
    </div>
  )
}
