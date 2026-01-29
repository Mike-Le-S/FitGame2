import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import {
  ArrowLeft,
  ArrowRight,
  Check,
  Plus,
  Trash2,
  Flame,
  Apple,
  Target,
  Utensils,
  Clock,
  Pill,
  FileText,
  Sparkles,
  GripVertical,
  ChevronDown,
  ChevronUp,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Stepper } from '@/components/shared/stepper'
import { Badge } from '@/components/ui'
import { useNutritionStore, foodCatalog, supplementCatalog } from '@/store/nutrition-store'
import { generateId, cn } from '@/lib/utils'
import type { Goal, MealPlan, FoodEntry, SupplementEntry, Macros } from '@/types'

const steps = [
  { id: 'info', label: 'Infos' },
  { id: 'calories', label: 'Calories' },
  { id: 'macros', label: 'Macros' },
  { id: 'meals', label: 'Repas' },
  { id: 'foods', label: 'Aliments' },
  { id: 'supplements', label: 'Suppl.' },
  { id: 'notes', label: 'Notes' },
  { id: 'recap', label: 'Récap' },
]

const mealNames = ['Petit-déjeuner', 'Déjeuner', 'Collation', 'Dîner', 'Avant-dodo']

const goalConfig = {
  bulk: { label: 'Prise de masse', color: 'success', icon: '📈', desc: 'Surplus calorique contrôlé' },
  cut: { label: 'Sèche', color: 'warning', icon: '🔥', desc: 'Déficit calorique modéré' },
  maintain: { label: 'Maintien', color: 'info', icon: '⚖️', desc: 'Équilibre énergétique' },
}

export function NutritionCreatePage() {
  const navigate = useNavigate()
  const { addDietPlan } = useNutritionStore()
  const [currentStep, setCurrentStep] = useState(0)

  // Step 1: Info
  const [name, setName] = useState('')
  const [goal, setGoal] = useState<Goal>('bulk')

  // Step 2: Calories
  const [trainingCalories, setTrainingCalories] = useState(2500)
  const [restCalories, setRestCalories] = useState(2000)

  // Step 3: Macros
  const [trainingMacros, setTrainingMacros] = useState<Macros>({ protein: 150, carbs: 300, fat: 70 })
  const [restMacros, setRestMacros] = useState<Macros>({ protein: 150, carbs: 200, fat: 65 })

  // Step 4: Meals
  const [meals, setMeals] = useState<MealPlan[]>([
    { id: generateId(), name: 'Petit-déjeuner', foods: [] },
    { id: generateId(), name: 'Déjeuner', foods: [] },
    { id: generateId(), name: 'Collation', foods: [] },
    { id: generateId(), name: 'Dîner', foods: [] },
  ])

  // Step 5: Foods - editing state
  const [editingMealId, setEditingMealId] = useState<string | null>(null)
  const [expandedCategory, setExpandedCategory] = useState<string | null>(null)

  // Step 6: Supplements
  const [supplements, setSupplements] = useState<SupplementEntry[]>([])

  // Step 7: Notes
  const [notes, setNotes] = useState('')

  // Focus states
  const [focusedField, setFocusedField] = useState<string | null>(null)

  const addMeal = () => {
    const newMeal: MealPlan = {
      id: generateId(),
      name: `Repas ${meals.length + 1}`,
      foods: [],
    }
    setMeals([...meals, newMeal])
  }

  const updateMeal = (id: string, updates: Partial<MealPlan>) => {
    setMeals(meals.map((m) => (m.id === id ? { ...m, ...updates } : m)))
  }

  const removeMeal = (id: string) => {
    setMeals(meals.filter((m) => m.id !== id))
    if (editingMealId === id) {
      setEditingMealId(null)
    }
  }

  const addFoodToMeal = (mealId: string, food: Omit<FoodEntry, 'id' | 'quantity'>) => {
    const newFood: FoodEntry = { ...food, id: generateId(), quantity: 100 }
    setMeals(
      meals.map((m) =>
        m.id === mealId ? { ...m, foods: [...m.foods, newFood] } : m
      )
    )
  }

  const updateFood = (mealId: string, foodId: string, updates: Partial<FoodEntry>) => {
    setMeals(
      meals.map((m) =>
        m.id === mealId
          ? {
              ...m,
              foods: m.foods.map((f) => (f.id === foodId ? { ...f, ...updates } : f)),
            }
          : m
      )
    )
  }

  const removeFood = (mealId: string, foodId: string) => {
    setMeals(
      meals.map((m) =>
        m.id === mealId
          ? { ...m, foods: m.foods.filter((f) => f.id !== foodId) }
          : m
      )
    )
  }

  const addSupplement = (supp: Omit<SupplementEntry, 'id'>) => {
    setSupplements([...supplements, { ...supp, id: generateId() }])
  }

  const removeSupplement = (id: string) => {
    setSupplements(supplements.filter((s) => s.id !== id))
  }

  const calculateMacroPercent = (macros: Macros) => {
    const proteinCal = macros.protein * 4
    const carbsCal = macros.carbs * 4
    const fatCal = macros.fat * 9
    const total = proteinCal + carbsCal + fatCal
    return {
      protein: Math.round((proteinCal / total) * 100),
      carbs: Math.round((carbsCal / total) * 100),
      fat: Math.round((fatCal / total) * 100),
      total: Math.round(total),
    }
  }

  const canProceed = () => {
    switch (currentStep) {
      case 0:
        return name.trim().length > 0
      case 1:
        return trainingCalories > 0 && restCalories > 0
      case 2:
        return true
      case 3:
        return meals.length > 0
      default:
        return true
    }
  }

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1)
      // Auto-select first meal when entering foods step
      if (currentStep === 3 && meals.length > 0) {
        setEditingMealId(meals[0].id)
      }
    } else {
      addDietPlan({
        name,
        goal,
        trainingCalories,
        restCalories,
        trainingMacros,
        restMacros,
        meals,
        supplements,
        notes: notes || undefined,
      })
      navigate('/nutrition')
    }
  }

  const handleBack = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1)
    }
  }

  const editingMeal = meals.find((m) => m.id === editingMealId)
  const totalFoods = meals.reduce((acc, m) => acc + m.foods.length, 0)

  return (
    <div className="min-h-screen">
      <Header
        title="Créer un plan nutrition"
        subtitle="Configurez un nouveau plan alimentaire"
      />

      <div className="p-8">
        {/* Back link */}
        <Link
          to="/nutrition"
          className={cn(
            'inline-flex items-center gap-2 text-sm font-medium mb-8',
            'text-text-secondary hover:text-success transition-colors'
          )}
        >
          <ArrowLeft className="w-4 h-4" />
          Retour aux plans
        </Link>

        {/* Stepper */}
        <div className="mb-10">
          <Stepper steps={steps} currentStep={currentStep} />
        </div>

        {/* Main content area */}
        <div className="max-w-4xl mx-auto">
          {/* Step 1: Info */}
          {currentStep === 0 && (
            <div
              className={cn(
                'p-8 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}
            >
              <div className="flex items-center gap-4 mb-8">
                <div className={cn(
                  'w-14 h-14 rounded-xl flex items-center justify-center',
                  'bg-gradient-to-br from-success/20 to-success/5'
                )}>
                  <Sparkles className="w-7 h-7 text-success" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold text-text-primary">
                    Informations du plan
                  </h2>
                  <p className="text-sm text-text-muted">
                    Définissez le nom et l'objectif
                  </p>
                </div>
              </div>

              <div className="space-y-6">
                {/* Name */}
                <div className="space-y-2">
                  <label className="text-sm font-medium text-text-secondary">
                    Nom du plan
                  </label>
                  <div className="relative">
                    {focusedField === 'name' && (
                      <div className="absolute inset-0 bg-success/10 blur-xl rounded-xl" />
                    )}
                    <input
                      type="text"
                      placeholder="Ex: Sèche femme -500kcal, Bulk clean 3000..."
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      onFocus={() => setFocusedField('name')}
                      onBlur={() => setFocusedField(null)}
                      className={cn(
                        'relative w-full h-12 px-4 rounded-xl',
                        'bg-surface-elevated border transition-all duration-300',
                        'text-text-primary placeholder:text-text-muted',
                        'focus:outline-none',
                        focusedField === 'name'
                          ? 'border-success shadow-[0_0_0_3px_rgba(34,197,94,0.1)]'
                          : 'border-border hover:border-[rgba(255,255,255,0.12)]'
                      )}
                    />
                  </div>
                </div>

                {/* Goal selection */}
                <div className="space-y-3">
                  <label className="text-sm font-medium text-text-secondary">
                    Objectif principal
                  </label>
                  <div className="grid grid-cols-3 gap-3">
                    {(['bulk', 'cut', 'maintain'] as Goal[]).map((g) => (
                      <button
                        key={g}
                        onClick={() => setGoal(g)}
                        className={cn(
                          'group relative p-4 rounded-xl transition-all duration-300',
                          'border text-left',
                          goal === g
                            ? 'bg-success/10 border-success shadow-[0_0_20px_rgba(34,197,94,0.15)]'
                            : 'bg-surface-elevated border-border hover:border-success/30'
                        )}
                      >
                        <div className="flex items-center gap-3 mb-2">
                          <span className="text-2xl">{goalConfig[g].icon}</span>
                          <span className={cn(
                            'font-semibold transition-colors',
                            goal === g ? 'text-success' : 'text-text-primary'
                          )}>
                            {goalConfig[g].label}
                          </span>
                        </div>
                        <p className="text-xs text-text-muted">{goalConfig[g].desc}</p>
                        {goal === g && (
                          <div className="absolute top-3 right-3">
                            <div className="w-5 h-5 rounded-full bg-success flex items-center justify-center">
                              <Check className="w-3 h-3 text-white" />
                            </div>
                          </div>
                        )}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Step 2: Calories */}
          {currentStep === 1 && (
            <div
              className={cn(
                'p-8 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}
            >
              <div className="flex items-center gap-4 mb-8">
                <div className={cn(
                  'w-14 h-14 rounded-xl flex items-center justify-center',
                  'bg-gradient-to-br from-accent/20 to-accent/5'
                )}>
                  <Flame className="w-7 h-7 text-accent" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold text-text-primary">
                    Objectifs caloriques
                  </h2>
                  <p className="text-sm text-text-muted">
                    Définissez les apports par type de jour
                  </p>
                </div>
              </div>

              <div className="space-y-6">
                {/* Training day */}
                <div className={cn(
                  'p-6 rounded-xl',
                  'bg-gradient-to-br from-accent/10 to-transparent',
                  'border border-accent/20'
                )}>
                  <div className="flex items-center gap-3 mb-4">
                    <div className="w-10 h-10 rounded-lg bg-accent/20 flex items-center justify-center">
                      <Flame className="w-5 h-5 text-accent" />
                    </div>
                    <span className="font-semibold text-text-primary">Jour d'entraînement</span>
                  </div>
                  <div className="relative">
                    {focusedField === 'trainingCal' && (
                      <div className="absolute inset-0 bg-accent/10 blur-xl rounded-xl" />
                    )}
                    <input
                      type="number"
                      value={trainingCalories}
                      onChange={(e) => setTrainingCalories(parseInt(e.target.value) || 0)}
                      onFocus={() => setFocusedField('trainingCal')}
                      onBlur={() => setFocusedField(null)}
                      className={cn(
                        'relative w-full h-16 px-4 rounded-xl text-3xl font-bold text-center',
                        'bg-surface border transition-all duration-300',
                        'text-text-primary',
                        'focus:outline-none',
                        focusedField === 'trainingCal'
                          ? 'border-accent shadow-[0_0_0_3px_rgba(255,107,53,0.1)]'
                          : 'border-border'
                      )}
                    />
                  </div>
                  <p className="text-sm text-text-muted mt-2 text-center">kcal / jour</p>
                </div>

                {/* Rest day */}
                <div className={cn(
                  'p-6 rounded-xl',
                  'bg-surface-elevated border border-border'
                )}>
                  <div className="flex items-center gap-3 mb-4">
                    <div className="w-10 h-10 rounded-lg bg-surface flex items-center justify-center border border-border">
                      <Clock className="w-5 h-5 text-text-muted" />
                    </div>
                    <span className="font-semibold text-text-primary">Jour de repos</span>
                  </div>
                  <div className="relative">
                    {focusedField === 'restCal' && (
                      <div className="absolute inset-0 bg-success/10 blur-xl rounded-xl" />
                    )}
                    <input
                      type="number"
                      value={restCalories}
                      onChange={(e) => setRestCalories(parseInt(e.target.value) || 0)}
                      onFocus={() => setFocusedField('restCal')}
                      onBlur={() => setFocusedField(null)}
                      className={cn(
                        'relative w-full h-16 px-4 rounded-xl text-3xl font-bold text-center',
                        'bg-surface border transition-all duration-300',
                        'text-text-primary',
                        'focus:outline-none',
                        focusedField === 'restCal'
                          ? 'border-success shadow-[0_0_0_3px_rgba(34,197,94,0.1)]'
                          : 'border-border'
                      )}
                    />
                  </div>
                  <p className="text-sm text-text-muted mt-2 text-center">kcal / jour</p>
                </div>

                {/* Difference */}
                <div className={cn(
                  'p-4 rounded-xl text-center',
                  'bg-success/10 border border-success/20'
                )}>
                  <p className="text-success font-medium">
                    Différence: {trainingCalories - restCalories > 0 ? '+' : ''}
                    {trainingCalories - restCalories} kcal les jours d'entraînement
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Step 3: Macros */}
          {currentStep === 2 && (
            <div
              className={cn(
                'p-8 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}
            >
              <div className="flex items-center gap-4 mb-8">
                <div className={cn(
                  'w-14 h-14 rounded-xl flex items-center justify-center',
                  'bg-gradient-to-br from-info/20 to-info/5'
                )}>
                  <Target className="w-7 h-7 text-info" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold text-text-primary">
                    Répartition des macros
                  </h2>
                  <p className="text-sm text-text-muted">
                    Protéines, glucides et lipides
                  </p>
                </div>
              </div>

              <div className="space-y-6">
                {/* Training day macros */}
                <div className={cn(
                  'p-6 rounded-xl',
                  'bg-gradient-to-br from-accent/10 to-transparent',
                  'border border-accent/20'
                )}>
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-3">
                      <Flame className="w-5 h-5 text-accent" />
                      <span className="font-semibold text-text-primary">Jour d'entraînement</span>
                    </div>
                    <span className="text-sm text-text-muted">
                      {calculateMacroPercent(trainingMacros).total} kcal
                    </span>
                  </div>

                  <div className="grid grid-cols-3 gap-4">
                    {/* Protein */}
                    <div className="space-y-2">
                      <label className="text-xs font-medium text-success">Protéines</label>
                      <div className="flex items-center gap-2">
                        <input
                          type="number"
                          value={trainingMacros.protein}
                          onChange={(e) =>
                            setTrainingMacros({ ...trainingMacros, protein: parseInt(e.target.value) || 0 })
                          }
                          className={cn(
                            'w-full h-10 px-3 rounded-lg text-center',
                            'bg-surface border border-border',
                            'text-text-primary font-semibold',
                            'focus:outline-none focus:border-success focus:ring-2 focus:ring-success/20'
                          )}
                        />
                        <span className="text-sm text-text-muted">g</span>
                      </div>
                      <p className="text-xs text-success text-center">
                        {calculateMacroPercent(trainingMacros).protein}%
                      </p>
                    </div>
                    {/* Carbs */}
                    <div className="space-y-2">
                      <label className="text-xs font-medium text-info">Glucides</label>
                      <div className="flex items-center gap-2">
                        <input
                          type="number"
                          value={trainingMacros.carbs}
                          onChange={(e) =>
                            setTrainingMacros({ ...trainingMacros, carbs: parseInt(e.target.value) || 0 })
                          }
                          className={cn(
                            'w-full h-10 px-3 rounded-lg text-center',
                            'bg-surface border border-border',
                            'text-text-primary font-semibold',
                            'focus:outline-none focus:border-info focus:ring-2 focus:ring-info/20'
                          )}
                        />
                        <span className="text-sm text-text-muted">g</span>
                      </div>
                      <p className="text-xs text-info text-center">
                        {calculateMacroPercent(trainingMacros).carbs}%
                      </p>
                    </div>
                    {/* Fat */}
                    <div className="space-y-2">
                      <label className="text-xs font-medium text-warning">Lipides</label>
                      <div className="flex items-center gap-2">
                        <input
                          type="number"
                          value={trainingMacros.fat}
                          onChange={(e) =>
                            setTrainingMacros({ ...trainingMacros, fat: parseInt(e.target.value) || 0 })
                          }
                          className={cn(
                            'w-full h-10 px-3 rounded-lg text-center',
                            'bg-surface border border-border',
                            'text-text-primary font-semibold',
                            'focus:outline-none focus:border-warning focus:ring-2 focus:ring-warning/20'
                          )}
                        />
                        <span className="text-sm text-text-muted">g</span>
                      </div>
                      <p className="text-xs text-warning text-center">
                        {calculateMacroPercent(trainingMacros).fat}%
                      </p>
                    </div>
                  </div>
                </div>

                {/* Rest day macros */}
                <div className={cn(
                  'p-6 rounded-xl',
                  'bg-surface-elevated border border-border'
                )}>
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-3">
                      <Clock className="w-5 h-5 text-text-muted" />
                      <span className="font-semibold text-text-primary">Jour de repos</span>
                    </div>
                    <span className="text-sm text-text-muted">
                      {calculateMacroPercent(restMacros).total} kcal
                    </span>
                  </div>

                  <div className="grid grid-cols-3 gap-4">
                    <div className="space-y-2">
                      <label className="text-xs font-medium text-success">Protéines</label>
                      <div className="flex items-center gap-2">
                        <input
                          type="number"
                          value={restMacros.protein}
                          onChange={(e) =>
                            setRestMacros({ ...restMacros, protein: parseInt(e.target.value) || 0 })
                          }
                          className={cn(
                            'w-full h-10 px-3 rounded-lg text-center',
                            'bg-surface border border-border',
                            'text-text-primary font-semibold',
                            'focus:outline-none focus:border-success focus:ring-2 focus:ring-success/20'
                          )}
                        />
                        <span className="text-sm text-text-muted">g</span>
                      </div>
                    </div>
                    <div className="space-y-2">
                      <label className="text-xs font-medium text-info">Glucides</label>
                      <div className="flex items-center gap-2">
                        <input
                          type="number"
                          value={restMacros.carbs}
                          onChange={(e) =>
                            setRestMacros({ ...restMacros, carbs: parseInt(e.target.value) || 0 })
                          }
                          className={cn(
                            'w-full h-10 px-3 rounded-lg text-center',
                            'bg-surface border border-border',
                            'text-text-primary font-semibold',
                            'focus:outline-none focus:border-info focus:ring-2 focus:ring-info/20'
                          )}
                        />
                        <span className="text-sm text-text-muted">g</span>
                      </div>
                    </div>
                    <div className="space-y-2">
                      <label className="text-xs font-medium text-warning">Lipides</label>
                      <div className="flex items-center gap-2">
                        <input
                          type="number"
                          value={restMacros.fat}
                          onChange={(e) =>
                            setRestMacros({ ...restMacros, fat: parseInt(e.target.value) || 0 })
                          }
                          className={cn(
                            'w-full h-10 px-3 rounded-lg text-center',
                            'bg-surface border border-border',
                            'text-text-primary font-semibold',
                            'focus:outline-none focus:border-warning focus:ring-2 focus:ring-warning/20'
                          )}
                        />
                        <span className="text-sm text-text-muted">g</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Step 4: Meals */}
          {currentStep === 3 && (
            <div
              className={cn(
                'p-8 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}
            >
              <div className="flex items-center justify-between mb-8">
                <div className="flex items-center gap-4">
                  <div className={cn(
                    'w-14 h-14 rounded-xl flex items-center justify-center',
                    'bg-gradient-to-br from-success/20 to-success/5'
                  )}>
                    <Utensils className="w-7 h-7 text-success" />
                  </div>
                  <div>
                    <h2 className="text-xl font-semibold text-text-primary">
                      Structure des repas
                    </h2>
                    <p className="text-sm text-text-muted">
                      {meals.length} repas configurés
                    </p>
                  </div>
                </div>
                <button
                  onClick={addMeal}
                  className={cn(
                    'flex items-center gap-2 h-11 px-5 rounded-xl font-semibold text-white',
                    'bg-gradient-to-r from-success to-[#4ade80]',
                    'hover:shadow-[0_0_25px_rgba(34,197,94,0.35)]',
                    'transition-all duration-300'
                  )}
                >
                  <Plus className="w-5 h-5" />
                  Ajouter
                </button>
              </div>

              <div className="space-y-3">
                {meals.map((meal, index) => (
                  <div
                    key={meal.id}
                    className={cn(
                      'group flex items-center gap-4 p-4 rounded-xl',
                      'bg-surface-elevated border border-border',
                      'hover:border-success/30 transition-all duration-200',
                      'animate-[fadeIn_0.3s_ease-out]'
                    )}
                    style={{ animationDelay: `${index * 50}ms` }}
                  >
                    <GripVertical className="w-5 h-5 text-text-muted cursor-grab opacity-50 group-hover:opacity-100" />

                    <div className="flex-1 grid grid-cols-2 gap-4 items-center">
                      <select
                        value={meal.name}
                        onChange={(e) => updateMeal(meal.id, { name: e.target.value })}
                        className={cn(
                          'h-10 px-3 rounded-lg appearance-none cursor-pointer',
                          'bg-surface border border-border',
                          'text-text-primary',
                          'focus:outline-none focus:border-success focus:ring-2 focus:ring-success/20'
                        )}
                      >
                        {mealNames.map((name) => (
                          <option key={name} value={name}>
                            {name}
                          </option>
                        ))}
                        <option value={`Repas ${index + 1}`}>Personnalisé</option>
                      </select>

                      <input
                        type="text"
                        placeholder="Heure (ex: 08:00)"
                        value={meal.targetTime || ''}
                        onChange={(e) => updateMeal(meal.id, { targetTime: e.target.value })}
                        className={cn(
                          'h-10 px-3 rounded-lg',
                          'bg-surface border border-border',
                          'text-text-primary placeholder:text-text-muted',
                          'focus:outline-none focus:border-success focus:ring-2 focus:ring-success/20'
                        )}
                      />
                    </div>

                    <button
                      onClick={() => removeMeal(meal.id)}
                      className={cn(
                        'p-2 rounded-lg transition-all duration-200',
                        'text-text-muted hover:text-error hover:bg-error/10'
                      )}
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Step 5: Foods */}
          {currentStep === 4 && (
            <div className="grid grid-cols-5 gap-6 animate-[fadeIn_0.4s_ease-out]">
              {/* Meals sidebar */}
              <div className={cn(
                'col-span-2 p-6 rounded-2xl',
                'bg-surface border border-border'
              )}>
                <div className="flex items-center gap-3 mb-6">
                  <div className={cn(
                    'w-10 h-10 rounded-lg flex items-center justify-center',
                    'bg-success/10'
                  )}>
                    <Utensils className="w-5 h-5 text-success" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-text-primary">Repas</h3>
                    <p className="text-xs text-text-muted">{meals.length} repas</p>
                  </div>
                </div>

                <div className="space-y-2">
                  {meals.map((meal, index) => (
                    <button
                      key={meal.id}
                      onClick={() => setEditingMealId(meal.id)}
                      className={cn(
                        'w-full flex items-center justify-between p-4 rounded-xl transition-all duration-200',
                        'animate-[fadeIn_0.3s_ease-out]',
                        editingMealId === meal.id
                          ? 'bg-success/10 border-2 border-success shadow-[0_0_20px_rgba(34,197,94,0.1)]'
                          : 'bg-surface-elevated border border-border hover:border-success/30'
                      )}
                      style={{ animationDelay: `${index * 50}ms` }}
                    >
                      <div className="text-left">
                        <p className={cn(
                          'font-semibold transition-colors',
                          editingMealId === meal.id ? 'text-success' : 'text-text-primary'
                        )}>
                          {meal.name}
                        </p>
                        <p className="text-sm text-text-muted">
                          {meal.foods.length} aliment{meal.foods.length > 1 ? 's' : ''}
                        </p>
                      </div>
                      {meal.foods.length > 0 ? (
                        <div className="w-6 h-6 rounded-full bg-success/20 flex items-center justify-center">
                          <Check className="w-3.5 h-3.5 text-success" />
                        </div>
                      ) : (
                        <div className="w-6 h-6 rounded-full bg-surface-elevated flex items-center justify-center border border-border">
                          <span className="text-xs text-text-muted">0</span>
                        </div>
                      )}
                    </button>
                  ))}
                </div>
              </div>

              {/* Food selection */}
              <div className={cn(
                'col-span-3 p-6 rounded-2xl max-h-[600px] overflow-y-auto',
                'bg-surface border border-border'
              )}>
                {editingMeal ? (
                  <>
                    <div className="flex items-center gap-3 mb-6">
                      <div className={cn(
                        'w-10 h-10 rounded-lg flex items-center justify-center',
                        'bg-gradient-to-br from-success/20 to-success/5'
                      )}>
                        <Apple className="w-5 h-5 text-success" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-text-primary">
                          {editingMeal.name}
                        </h3>
                        <p className="text-xs text-text-muted">
                          {editingMeal.foods.length} aliment{editingMeal.foods.length > 1 ? 's' : ''}
                        </p>
                      </div>
                    </div>

                    {/* Selected foods */}
                    {editingMeal.foods.length > 0 && (
                      <div className="space-y-2 mb-6">
                        {editingMeal.foods.map((food, index) => (
                          <div
                            key={food.id}
                            className={cn(
                              'group flex items-center justify-between p-3 rounded-xl',
                              'bg-surface-elevated border border-border',
                              'hover:border-success/30 transition-all duration-200',
                              'animate-[fadeIn_0.2s_ease-out]'
                            )}
                            style={{ animationDelay: `${index * 30}ms` }}
                          >
                            <div className="flex-1">
                              <p className="font-medium text-text-primary text-sm">
                                {food.name}
                              </p>
                              <div className="flex items-center gap-2 mt-1">
                                <input
                                  type="number"
                                  value={food.quantity}
                                  onChange={(e) =>
                                    updateFood(editingMeal.id, food.id, {
                                      quantity: parseInt(e.target.value) || 0,
                                    })
                                  }
                                  className={cn(
                                    'w-16 h-6 px-2 rounded text-xs text-center',
                                    'bg-surface border border-border',
                                    'text-text-primary',
                                    'focus:outline-none focus:border-success'
                                  )}
                                />
                                <span className="text-xs text-text-muted">{food.unit}</span>
                                <span className="text-xs text-accent ml-auto">
                                  {Math.round((food.calories * food.quantity) / 100)} kcal
                                </span>
                              </div>
                            </div>
                            <button
                              onClick={() => removeFood(editingMeal.id, food.id)}
                              className={cn(
                                'p-1.5 rounded-lg transition-all duration-200 ml-2',
                                'text-text-muted hover:text-error hover:bg-error/10',
                                'opacity-0 group-hover:opacity-100'
                              )}
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        ))}
                      </div>
                    )}

                    {/* Food catalog */}
                    <div className="border-t border-border pt-4">
                      <p className="text-sm font-medium text-text-secondary mb-3">
                        Ajouter un aliment
                      </p>
                      <div className="space-y-1">
                        {foodCatalog.map((category) => (
                          <div key={category.category}>
                            <button
                              onClick={() =>
                                setExpandedCategory(
                                  expandedCategory === category.category ? null : category.category
                                )
                              }
                              className={cn(
                                'w-full flex items-center justify-between p-3 rounded-lg',
                                'transition-all duration-200',
                                expandedCategory === category.category
                                  ? 'bg-success/10 text-success'
                                  : 'hover:bg-surface-elevated text-text-primary'
                              )}
                            >
                              <span className="text-sm font-medium">{category.category}</span>
                              {expandedCategory === category.category ? (
                                <ChevronUp className="w-4 h-4" />
                              ) : (
                                <ChevronDown className="w-4 h-4 text-text-muted" />
                              )}
                            </button>
                            {expandedCategory === category.category && (
                              <div className="pl-4 space-y-1 mt-1 mb-2 animate-[fadeIn_0.2s_ease-out]">
                                {category.foods.map((food, i) => (
                                  <button
                                    key={i}
                                    onClick={() => addFoodToMeal(editingMeal.id, food)}
                                    className={cn(
                                      'w-full flex items-center justify-between p-2.5 rounded-lg',
                                      'text-sm text-text-secondary',
                                      'hover:text-success hover:bg-success/5',
                                      'transition-all duration-150'
                                    )}
                                  >
                                    <span>{food.name}</span>
                                    <span className="text-xs text-text-muted">
                                      {food.calories} kcal/{food.unit}
                                    </span>
                                  </button>
                                ))}
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  </>
                ) : (
                  <div className="flex flex-col items-center justify-center h-full py-16">
                    <div className="w-16 h-16 rounded-2xl bg-surface-elevated flex items-center justify-center mb-4">
                      <Apple className="w-8 h-8 text-text-muted" />
                    </div>
                    <p className="text-text-secondary font-medium mb-1">
                      Sélectionnez un repas
                    </p>
                    <p className="text-sm text-text-muted">
                      pour ajouter des aliments
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Step 6: Supplements */}
          {currentStep === 5 && (
            <div
              className={cn(
                'p-8 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}
            >
              <div className="flex items-center gap-4 mb-8">
                <div className={cn(
                  'w-14 h-14 rounded-xl flex items-center justify-center',
                  'bg-gradient-to-br from-info/20 to-info/5'
                )}>
                  <Pill className="w-7 h-7 text-info" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold text-text-primary">
                    Suppléments
                  </h2>
                  <p className="text-sm text-text-muted">
                    {supplements.length} supplément{supplements.length > 1 ? 's' : ''} sélectionné{supplements.length > 1 ? 's' : ''}
                  </p>
                </div>
              </div>

              {/* Selected supplements */}
              {supplements.length > 0 && (
                <div className="space-y-2 mb-6">
                  {supplements.map((supp, index) => (
                    <div
                      key={supp.id}
                      className={cn(
                        'group flex items-center justify-between p-4 rounded-xl',
                        'bg-surface-elevated border border-border',
                        'hover:border-info/30 transition-all duration-200',
                        'animate-[fadeIn_0.2s_ease-out]'
                      )}
                      style={{ animationDelay: `${index * 30}ms` }}
                    >
                      <div>
                        <p className="font-semibold text-text-primary">{supp.name}</p>
                        <p className="text-sm text-text-muted">
                          {supp.dosage} - {supp.timing}
                        </p>
                      </div>
                      <button
                        onClick={() => removeSupplement(supp.id)}
                        className={cn(
                          'p-2 rounded-lg transition-all duration-200',
                          'text-text-muted hover:text-error hover:bg-error/10',
                          'opacity-0 group-hover:opacity-100'
                        )}
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                </div>
              )}

              {/* Supplement catalog */}
              <div className="border-t border-border pt-6">
                <p className="text-sm font-medium text-text-secondary mb-4">
                  Ajouter un supplément
                </p>
                <div className="grid grid-cols-2 gap-3">
                  {supplementCatalog.map((supp, i) => {
                    const isSelected = supplements.some((s) => s.name === supp.name)
                    return (
                      <button
                        key={i}
                        onClick={() => !isSelected && addSupplement(supp)}
                        disabled={isSelected}
                        className={cn(
                          'flex items-center justify-between p-4 rounded-xl text-left transition-all duration-200',
                          isSelected
                            ? 'bg-info/10 border-2 border-info cursor-not-allowed'
                            : 'bg-surface-elevated border border-border hover:border-info/30'
                        )}
                      >
                        <div>
                          <p className={cn(
                            'font-semibold text-sm',
                            isSelected ? 'text-info' : 'text-text-primary'
                          )}>
                            {supp.name}
                          </p>
                          <p className="text-xs text-text-muted">{supp.dosage}</p>
                        </div>
                        {isSelected ? (
                          <div className="w-6 h-6 rounded-full bg-info flex items-center justify-center">
                            <Check className="w-3.5 h-3.5 text-white" />
                          </div>
                        ) : (
                          <Plus className="w-4 h-4 text-text-muted" />
                        )}
                      </button>
                    )
                  })}
                </div>
              </div>
            </div>
          )}

          {/* Step 7: Notes */}
          {currentStep === 6 && (
            <div
              className={cn(
                'p-8 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}
            >
              <div className="flex items-center gap-4 mb-8">
                <div className={cn(
                  'w-14 h-14 rounded-xl flex items-center justify-center',
                  'bg-gradient-to-br from-warning/20 to-warning/5'
                )}>
                  <FileText className="w-7 h-7 text-warning" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold text-text-primary">
                    Notes et instructions
                  </h2>
                  <p className="text-sm text-text-muted">
                    Informations complémentaires (optionnel)
                  </p>
                </div>
              </div>

              <div className="relative">
                {focusedField === 'notes' && (
                  <div className="absolute inset-0 bg-warning/10 blur-xl rounded-xl" />
                )}
                <textarea
                  placeholder="Ajoutez des notes ou instructions spécifiques pour ce plan...

Ex:
- Boire 3L d'eau minimum par jour
- Éviter les sucres rapides après 18h
- Privilégier les glucides autour de l'entraînement"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  onFocus={() => setFocusedField('notes')}
                  onBlur={() => setFocusedField(null)}
                  className={cn(
                    'relative w-full h-64 px-4 py-4 rounded-xl resize-none',
                    'bg-surface-elevated border transition-all duration-300',
                    'text-text-primary placeholder:text-text-muted',
                    'focus:outline-none',
                    focusedField === 'notes'
                      ? 'border-warning shadow-[0_0_0_3px_rgba(234,179,8,0.1)]'
                      : 'border-border hover:border-[rgba(255,255,255,0.12)]'
                  )}
                />
              </div>
            </div>
          )}

          {/* Step 8: Recap */}
          {currentStep === 7 && (
            <div
              className={cn(
                'p-8 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}
            >
              <div className="flex items-center gap-4 mb-8">
                <div className={cn(
                  'w-14 h-14 rounded-xl flex items-center justify-center',
                  'bg-gradient-to-br from-success/20 to-success/5'
                )}>
                  <Check className="w-7 h-7 text-success" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold text-text-primary">
                    Récapitulatif
                  </h2>
                  <p className="text-sm text-text-muted">
                    Vérifiez votre plan avant de le créer
                  </p>
                </div>
              </div>

              {/* Info summary */}
              <div className="grid grid-cols-2 gap-4 mb-6">
                <div className={cn(
                  'p-4 rounded-xl',
                  'bg-surface-elevated border border-border',
                  'animate-[fadeIn_0.3s_ease-out]'
                )}>
                  <p className="text-xs text-text-muted mb-1">Nom</p>
                  <p className="font-semibold text-text-primary">{name}</p>
                </div>
                <div className={cn(
                  'p-4 rounded-xl',
                  'bg-surface-elevated border border-border',
                  'animate-[fadeIn_0.3s_ease-out]'
                )}
                style={{ animationDelay: '50ms' }}
                >
                  <p className="text-xs text-text-muted mb-1">Objectif</p>
                  <Badge
                    variant={
                      goal === 'bulk' ? 'success' : goal === 'cut' ? 'warning' : 'info'
                    }
                  >
                    {goalConfig[goal].label}
                  </Badge>
                </div>
              </div>

              {/* Calories summary */}
              <div className="grid grid-cols-2 gap-4 mb-6">
                <div className={cn(
                  'p-4 rounded-xl',
                  'bg-gradient-to-br from-accent/10 to-transparent',
                  'border border-accent/20',
                  'animate-[fadeIn_0.3s_ease-out]'
                )}
                style={{ animationDelay: '100ms' }}
                >
                  <div className="flex items-center gap-2 mb-2">
                    <Flame className="w-4 h-4 text-accent" />
                    <span className="text-xs text-text-muted">Jour training</span>
                  </div>
                  <p className="text-2xl font-bold text-text-primary">{trainingCalories} kcal</p>
                  <p className="text-xs text-text-muted mt-1">
                    P:{trainingMacros.protein}g C:{trainingMacros.carbs}g L:{trainingMacros.fat}g
                  </p>
                </div>
                <div className={cn(
                  'p-4 rounded-xl',
                  'bg-surface-elevated border border-border',
                  'animate-[fadeIn_0.3s_ease-out]'
                )}
                style={{ animationDelay: '150ms' }}
                >
                  <div className="flex items-center gap-2 mb-2">
                    <Clock className="w-4 h-4 text-text-muted" />
                    <span className="text-xs text-text-muted">Jour repos</span>
                  </div>
                  <p className="text-2xl font-bold text-text-primary">{restCalories} kcal</p>
                  <p className="text-xs text-text-muted mt-1">
                    P:{restMacros.protein}g C:{restMacros.carbs}g L:{restMacros.fat}g
                  </p>
                </div>
              </div>

              {/* Meals summary */}
              <div className="mb-6 animate-[fadeIn_0.3s_ease-out]" style={{ animationDelay: '200ms' }}>
                <p className="text-sm font-semibold text-text-secondary mb-3 flex items-center gap-2">
                  <Utensils className="w-4 h-4" />
                  {meals.length} Repas - {totalFoods} aliments
                </p>
                <div className="flex flex-wrap gap-2">
                  {meals.map((meal) => (
                    <Badge key={meal.id} variant="accent">
                      {meal.name} ({meal.foods.length})
                    </Badge>
                  ))}
                </div>
              </div>

              {/* Supplements summary */}
              {supplements.length > 0 && (
                <div className="animate-[fadeIn_0.3s_ease-out]" style={{ animationDelay: '250ms' }}>
                  <p className="text-sm font-semibold text-text-secondary mb-3 flex items-center gap-2">
                    <Pill className="w-4 h-4" />
                    {supplements.length} Suppléments
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {supplements.map((supp) => (
                      <Badge key={supp.id} variant="info">
                        {supp.name}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Navigation */}
          <div className="flex items-center justify-between mt-8">
            <button
              onClick={handleBack}
              disabled={currentStep === 0}
              className={cn(
                'flex items-center gap-2 h-11 px-5 rounded-xl font-medium',
                'transition-all duration-200',
                currentStep === 0
                  ? 'text-text-muted cursor-not-allowed'
                  : 'text-text-secondary hover:text-text-primary hover:bg-surface-elevated'
              )}
            >
              <ArrowLeft className="w-4 h-4" />
              Précédent
            </button>

            <button
              onClick={handleNext}
              disabled={!canProceed()}
              className={cn(
                'group flex items-center gap-2 h-11 px-6 rounded-xl font-semibold text-white',
                'transition-all duration-300',
                canProceed()
                  ? 'bg-gradient-to-r from-success to-[#4ade80] hover:shadow-[0_0_25px_rgba(34,197,94,0.35)]'
                  : 'bg-surface-elevated text-text-muted cursor-not-allowed'
              )}
            >
              {currentStep === steps.length - 1 ? (
                <>
                  <Check className="w-5 h-5" />
                  Créer le plan
                </>
              ) : (
                <>
                  Suivant
                  <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
