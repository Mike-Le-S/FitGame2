import { useState } from 'react'
import { useParams, Link, Navigate, useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Apple,
  Users,
  Flame,
  Edit3,
  Copy,
  Trash2,
  ChevronDown,
  ChevronUp,
  Target,
  MoreHorizontal,
  Pill,
  Clock,
  Utensils,
  FileDown,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Badge, Avatar } from '@/components/ui'
import { useNutritionStore } from '@/store/nutrition-store'
import { useStudentsStore } from '@/store/students-store'
import { useAuthStore } from '@/store/auth-store'
import { formatDate, cn } from '@/lib/utils'
import { goalConfig } from '@/constants/goals'
import { exportDietPlanToPDF } from '@/lib/pdf-export'

const timingLabels: Record<string, string> = {
  'morning': 'Matin',
  'pre-workout': 'Pré-entraînement',
  'post-workout': 'Post-entraînement',
  'evening': 'Soir',
  'with-meal': 'Avec un repas',
}

export function NutritionDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { getDietPlanById, deleteDietPlan, duplicateDietPlan } = useNutritionStore()
  const { students } = useStudentsStore()
  const { coach } = useAuthStore()

  const [expandedMealId, setExpandedMealId] = useState<string | null>(null)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [showMenu, setShowMenu] = useState(false)

  const plan = getDietPlanById(id!)

  if (!plan) {
    return <Navigate to="/nutrition" replace />
  }

  const assignedStudents = students.filter(s =>
    plan.assignedStudentIds.includes(s.id)
  )

  const handleDuplicate = () => {
    setShowMenu(false)
    const newId = duplicateDietPlan(plan.id)
    if (newId) {
      navigate(`/nutrition/${newId}`)
    }
  }

  const handleExportPDF = () => {
    setShowMenu(false)
    exportDietPlanToPDF(plan, coach?.name)
  }

  const handleDelete = () => {
    deleteDietPlan(plan.id)
    navigate('/nutrition')
  }

  return (
    <div className="min-h-screen">
      <Header
        title=""
        action={
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
              Actions
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
                    onClick={() => setShowMenu(false)}
                    className="w-full flex items-center gap-2 px-3 py-2.5 text-sm text-text-secondary hover:text-text-primary hover:bg-surface-elevated rounded-lg transition-colors"
                  >
                    <Edit3 className="w-4 h-4" />
                    Modifier
                  </button>
                  <button
                    onClick={handleExportPDF}
                    className="w-full flex items-center gap-2 px-3 py-2.5 text-sm text-text-secondary hover:text-text-primary hover:bg-surface-elevated rounded-lg transition-colors"
                  >
                    <FileDown className="w-4 h-4" />
                    Exporter PDF
                  </button>
                  <button
                    onClick={handleDuplicate}
                    className="w-full flex items-center gap-2 px-3 py-2.5 text-sm text-text-secondary hover:text-text-primary hover:bg-surface-elevated rounded-lg transition-colors"
                  >
                    <Copy className="w-4 h-4" />
                    Dupliquer
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
        }
      />

      <div className="p-8">
        {/* Back link */}
        <Link
          to="/nutrition"
          className={cn(
            'inline-flex items-center gap-2 text-sm mb-6',
            'text-text-secondary hover:text-success transition-colors'
          )}
        >
          <ArrowLeft className="w-4 h-4" />
          Retour aux plans
        </Link>

        {/* Plan Header */}
        <div className={cn(
          'relative p-6 rounded-2xl mb-6 overflow-hidden',
          'bg-surface border border-border'
        )}>
          <div className="absolute top-0 right-0 w-96 h-96 bg-success/5 rounded-full blur-[100px]" />

          <div className="relative flex items-start gap-6">
            <div className={cn(
              'w-20 h-20 rounded-2xl flex items-center justify-center',
              'bg-gradient-to-br from-success/20 to-success/5'
            )}>
              <Apple className="w-10 h-10 text-success" />
            </div>

            <div className="flex-1">
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-2xl font-bold text-text-primary">{plan.name}</h1>
                <Badge variant={goalConfig[plan.goal].color as 'success' | 'warning' | 'info'}>
                  <Target className="w-3 h-3 mr-1" />
                  {goalConfig[plan.goal].label}
                </Badge>
              </div>
              {plan.notes && (
                <p className="text-text-secondary mb-4 max-w-2xl">{plan.notes}</p>
              )}

              <div className="flex items-center gap-6">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-accent/10 flex items-center justify-center">
                    <Flame className="w-5 h-5 text-accent" />
                  </div>
                  <div>
                    <p className="text-xs text-text-muted">Training</p>
                    <p className="font-semibold text-text-primary">{plan.trainingCalories} kcal</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-surface-elevated flex items-center justify-center">
                    <Clock className="w-5 h-5 text-text-muted" />
                  </div>
                  <div>
                    <p className="text-xs text-text-muted">Repos</p>
                    <p className="font-semibold text-text-primary">{plan.restCalories} kcal</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-surface-elevated flex items-center justify-center">
                    <Utensils className="w-5 h-5 text-text-muted" />
                  </div>
                  <div>
                    <p className="text-xs text-text-muted">Repas</p>
                    <p className="font-semibold text-text-primary">{plan.meals.length} par jour</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-surface-elevated flex items-center justify-center">
                    <Users className="w-5 h-5 text-text-muted" />
                  </div>
                  <div>
                    <p className="text-xs text-text-muted">Élèves</p>
                    <p className="font-semibold text-text-primary">{assignedStudents.length} assignés</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Macros Summary */}
        <div className="grid grid-cols-2 gap-6 mb-6">
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
                <p className="text-2xl font-bold text-text-primary">{plan.trainingCalories}</p>
                <p className="text-xs text-text-muted">Calories</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-success">{plan.trainingMacros.protein}g</p>
                <p className="text-xs text-text-muted">Protéines</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-info">{plan.trainingMacros.carbs}g</p>
                <p className="text-xs text-text-muted">Glucides</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-warning">{plan.trainingMacros.fat}g</p>
                <p className="text-xs text-text-muted">Lipides</p>
              </div>
            </div>
          </div>

          <div className={cn(
            'p-5 rounded-2xl',
            'bg-surface border border-border'
          )}>
            <div className="flex items-center gap-2 mb-4">
              <Clock className="w-5 h-5 text-text-muted" />
              <h3 className="font-semibold text-text-primary">Jour de repos</h3>
            </div>
            <div className="grid grid-cols-4 gap-4">
              <div className="text-center">
                <p className="text-2xl font-bold text-text-primary">{plan.restCalories}</p>
                <p className="text-xs text-text-muted">Calories</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-success">{plan.restMacros.protein}g</p>
                <p className="text-xs text-text-muted">Protéines</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-info">{plan.restMacros.carbs}g</p>
                <p className="text-xs text-text-muted">Glucides</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-warning">{plan.restMacros.fat}g</p>
                <p className="text-xs text-text-muted">Lipides</p>
              </div>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-6">
          {/* Meals List */}
          <div className="col-span-2 space-y-4">
            <h3 className="text-lg font-semibold text-text-primary mb-4">
              Plan des repas
            </h3>

            {plan.meals.map((meal, index) => (
              <div
                key={meal.id}
                className={cn(
                  'rounded-2xl overflow-hidden',
                  'bg-surface border border-border',
                  'animate-[fadeIn_0.3s_ease-out]'
                )}
                style={{ animationDelay: `${index * 50}ms` }}
              >
                <button
                  onClick={() => setExpandedMealId(expandedMealId === meal.id ? null : meal.id)}
                  className={cn(
                    'w-full flex items-center justify-between p-5',
                    'hover:bg-surface-elevated/50 transition-colors'
                  )}
                >
                  <div className="flex items-center gap-4">
                    <div className={cn(
                      'w-12 h-12 rounded-xl flex items-center justify-center text-lg font-bold',
                      'bg-success/10 text-success'
                    )}>
                      {index + 1}
                    </div>
                    <div className="text-left">
                      <h4 className="font-semibold text-text-primary">{meal.name}</h4>
                      <p className="text-sm text-text-muted">
                        {meal.foods.length} aliment{meal.foods.length > 1 ? 's' : ''}
                        {meal.targetTime && ` - ${meal.targetTime}`}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    {expandedMealId === meal.id ? (
                      <ChevronUp className="w-5 h-5 text-text-muted" />
                    ) : (
                      <ChevronDown className="w-5 h-5 text-text-muted" />
                    )}
                  </div>
                </button>

                {expandedMealId === meal.id && (
                  <div className="border-t border-border p-5 animate-[fadeIn_0.2s_ease-out]">
                    {meal.foods.length > 0 ? (
                      <div className="space-y-3">
                        {meal.foods.map((food) => (
                          <div
                            key={food.id}
                            className={cn(
                              'flex items-center justify-between p-4 rounded-xl',
                              'bg-surface-elevated'
                            )}
                          >
                            <div>
                              <p className="font-medium text-text-primary">{food.name}</p>
                              <p className="text-sm text-text-muted">
                                {food.quantity} {food.unit}
                              </p>
                            </div>
                            <div className="text-right">
                              <p className="font-semibold text-text-primary">
                                {Math.round(food.calories * food.quantity / 100)} kcal
                              </p>
                              <p className="text-xs text-text-muted">
                                P:{Math.round(food.macros.protein * food.quantity / 100)}
                                C:{Math.round(food.macros.carbs * food.quantity / 100)}
                                L:{Math.round(food.macros.fat * food.quantity / 100)}
                              </p>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <p className="text-text-muted text-sm text-center py-4">
                        Aucun aliment défini pour ce repas
                      </p>
                    )}
                  </div>
                )}
              </div>
            ))}

            {/* Supplements */}
            {plan.supplements.length > 0 && (
              <div className={cn(
                'mt-6 p-5 rounded-2xl',
                'bg-surface border border-border'
              )}>
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 rounded-xl bg-info/10 flex items-center justify-center">
                    <Pill className="w-5 h-5 text-info" />
                  </div>
                  <h3 className="font-semibold text-text-primary">Suppléments</h3>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  {plan.supplements.map((supp) => (
                    <div
                      key={supp.id}
                      className={cn(
                        'p-4 rounded-xl',
                        'bg-surface-elevated'
                      )}
                    >
                      <p className="font-medium text-text-primary">{supp.name}</p>
                      <div className="flex items-center gap-2 mt-1">
                        <Badge variant="default" className="text-xs">
                          {supp.dosage}
                        </Badge>
                        <span className="text-xs text-text-muted">
                          {timingLabels[supp.timing] || supp.timing}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Assigned Students */}
            <div className="p-5 rounded-2xl bg-surface border border-border">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-sm font-semibold text-text-secondary flex items-center gap-2">
                  <Users className="w-4 h-4 text-success" />
                  Élèves assignés
                </h3>
                <span className="text-xs text-text-muted">
                  {assignedStudents.length} élève{assignedStudents.length > 1 ? 's' : ''}
                </span>
              </div>

              {assignedStudents.length > 0 ? (
                <div className="space-y-2">
                  {assignedStudents.map((student) => (
                    <Link
                      key={student.id}
                      to={`/students/${student.id}`}
                      className={cn(
                        'flex items-center gap-3 p-3 rounded-xl',
                        'hover:bg-surface-elevated transition-colors'
                      )}
                    >
                      <Avatar name={student.name} size="sm" />
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-text-primary text-sm truncate">
                          {student.name}
                        </p>
                        <p className="text-xs text-text-muted">
                          {student.stats.complianceRate}% compliance
                        </p>
                      </div>
                      <Badge
                        variant={
                          student.goal === 'bulk' ? 'success' :
                          student.goal === 'cut' ? 'warning' : 'info'
                        }
                        className="text-xs"
                      >
                        {student.goal === 'bulk' ? 'Masse' :
                         student.goal === 'cut' ? 'Sèche' : 'Maintien'}
                      </Badge>
                    </Link>
                  ))}
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center py-8">
                  <div className="w-12 h-12 rounded-xl bg-surface-elevated flex items-center justify-center mb-3">
                    <Users className="w-6 h-6 text-text-muted" />
                  </div>
                  <p className="text-sm text-text-muted text-center">
                    Aucun élève assigné à ce plan
                  </p>
                </div>
              )}
            </div>

            {/* Info */}
            <div className="p-5 rounded-2xl bg-surface border border-border">
              <h3 className="text-sm font-semibold text-text-secondary mb-4">
                Informations
              </h3>
              <div className="space-y-3 text-sm">
                <div className="flex justify-between">
                  <span className="text-text-muted">Créé le</span>
                  <span className="text-text-primary">{formatDate(plan.createdAt)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-text-muted">Modifié le</span>
                  <span className="text-text-primary">{formatDate(plan.updatedAt)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-text-muted">Suppléments</span>
                  <span className="text-text-primary">{plan.supplements.length}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Delete Confirmation Modal */}
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
                <h3 className="text-lg font-semibold text-text-primary">Supprimer le plan</h3>
                <p className="text-sm text-text-muted">Cette action est irréversible</p>
              </div>
            </div>
            <p className="text-text-secondary mb-6">
              Êtes-vous sûr de vouloir supprimer "{plan.name}" ?
              {assignedStudents.length > 0 && (
                <span className="text-warning"> {assignedStudents.length} élève{assignedStudents.length > 1 ? 's' : ''} perdra{assignedStudents.length > 1 ? 'ont' : ''} leur assignation.</span>
              )}
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
