import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import {
  ArrowLeft,
  ArrowRight,
  Check,
  Plus,
  Trash2,
  GripVertical,
  ChevronDown,
  ChevronUp,
  Dumbbell,
  Calendar,
  Zap,
  Target,
  Sparkles,
  Clock,
  Layers,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Stepper } from '@/components/shared/stepper'
import { Badge } from '@/components/ui'
import { useProgramsStore, exerciseCatalog, createExercise, createDefaultSets } from '@/store/programs-store'
import { generateId, cn } from '@/lib/utils'
import type { Goal, WorkoutDay, Exercise, MuscleGroup, ExerciseMode } from '@/types'

const steps = [
  { id: 'info', label: 'Informations' },
  { id: 'days', label: 'Jours' },
  { id: 'exercises', label: 'Exercices' },
  { id: 'recap', label: 'Récapitulatif' },
]

const dayNames = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']

const muscleLabels: Record<MuscleGroup, string> = {
  chest: 'Pectoraux',
  back: 'Dos',
  shoulders: 'Épaules',
  biceps: 'Biceps',
  triceps: 'Triceps',
  forearms: 'Avant-bras',
  quads: 'Quadriceps',
  hamstrings: 'Ischio-jambiers',
  glutes: 'Fessiers',
  calves: 'Mollets',
  abs: 'Abdominaux',
  cardio: 'Cardio',
}

const muscleIcons: Record<MuscleGroup, string> = {
  chest: '💪',
  back: '🔙',
  shoulders: '🎯',
  biceps: '💪',
  triceps: '💪',
  forearms: '🤲',
  quads: '🦵',
  hamstrings: '🦵',
  glutes: '🍑',
  calves: '🦶',
  abs: '🔥',
  cardio: '❤️',
}

const modeLabels: Record<ExerciseMode, string> = {
  classic: 'Classique',
  rpt: 'RPT',
  pyramidal: 'Pyramidal',
  dropset: 'Dropset',
}

const goalConfig = {
  bulk: { label: 'Prise de masse', color: 'success', icon: '📈' },
  cut: { label: 'Sèche', color: 'warning', icon: '🔥' },
  maintain: { label: 'Maintien', color: 'info', icon: '⚖️' },
}

export function ProgramCreatePage() {
  const navigate = useNavigate()
  const { addProgram } = useProgramsStore()
  const [currentStep, setCurrentStep] = useState(0)

  // Step 1: Info
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [goal, setGoal] = useState<Goal>('bulk')
  const [durationWeeks, setDurationWeeks] = useState(8)
  const [deloadFrequency, setDeloadFrequency] = useState<number | undefined>(4)

  // Step 2: Days
  const [days, setDays] = useState<WorkoutDay[]>([])

  // Step 3: Exercises - track which day is being edited
  const [editingDayId, setEditingDayId] = useState<string | null>(null)
  const [expandedMuscle, setExpandedMuscle] = useState<MuscleGroup | null>(null)

  // Focus states
  const [focusedField, setFocusedField] = useState<string | null>(null)

  const addDay = () => {
    const newDay: WorkoutDay = {
      id: generateId(),
      name: `Jour ${days.length + 1}`,
      dayOfWeek: days.length % 7,
      isRestDay: false,
      exercises: [],
    }
    setDays([...days, newDay])
  }

  const updateDay = (id: string, updates: Partial<WorkoutDay>) => {
    setDays(days.map((d) => (d.id === id ? { ...d, ...updates } : d)))
  }

  const removeDay = (id: string) => {
    setDays(days.filter((d) => d.id !== id))
    if (editingDayId === id) {
      setEditingDayId(null)
    }
  }

  const addExerciseToDay = (dayId: string, exerciseName: string, muscle: MuscleGroup) => {
    setDays(
      days.map((d) =>
        d.id === dayId
          ? { ...d, exercises: [...d.exercises, createExercise(exerciseName, muscle)] }
          : d
      )
    )
  }

  const updateExercise = (dayId: string, exerciseId: string, updates: Partial<Exercise>) => {
    setDays(
      days.map((d) =>
        d.id === dayId
          ? {
              ...d,
              exercises: d.exercises.map((e) =>
                e.id === exerciseId ? { ...e, ...updates } : e
              ),
            }
          : d
      )
    )
  }

  const removeExercise = (dayId: string, exerciseId: string) => {
    setDays(
      days.map((d) =>
        d.id === dayId
          ? { ...d, exercises: d.exercises.filter((e) => e.id !== exerciseId) }
          : d
      )
    )
  }

  const canProceed = () => {
    switch (currentStep) {
      case 0:
        return name.trim().length > 0
      case 1:
        return days.length > 0
      case 2:
        return days.every((d) => d.isRestDay || d.exercises.length > 0)
      default:
        return true
    }
  }

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1)
      // Auto-select first non-rest day when entering exercises step
      if (currentStep === 1) {
        const firstTrainingDay = days.find(d => !d.isRestDay)
        if (firstTrainingDay) {
          setEditingDayId(firstTrainingDay.id)
        }
      }
    } else {
      // Save program
      addProgram({
        name,
        description,
        goal,
        durationWeeks,
        deloadFrequency,
        days,
      })
      navigate('/programs')
    }
  }

  const handleBack = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1)
    }
  }

  const editingDay = days.find((d) => d.id === editingDayId)
  const totalExercises = days.reduce((acc, d) => acc + d.exercises.length, 0)
  const trainingDays = days.filter(d => !d.isRestDay).length

  return (
    <div className="min-h-screen">
      <Header
        title="Créer un programme"
        subtitle="Configurez votre nouveau programme d'entraînement"
      />

      <div className="p-8">
        {/* Back link */}
        <Link
          to="/programs"
          className={cn(
            'inline-flex items-center gap-2 text-sm font-medium mb-8',
            'text-text-secondary hover:text-accent transition-colors'
          )}
        >
          <ArrowLeft className="w-4 h-4" />
          Retour aux programmes
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
              {/* Header */}
              <div className="flex items-center gap-4 mb-8">
                <div className={cn(
                  'w-14 h-14 rounded-xl flex items-center justify-center',
                  'bg-gradient-to-br from-accent/20 to-accent/5'
                )}>
                  <Sparkles className="w-7 h-7 text-accent" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold text-text-primary">
                    Informations du programme
                  </h2>
                  <p className="text-sm text-text-muted">
                    Définissez les paramètres de base
                  </p>
                </div>
              </div>

              <div className="space-y-6">
                {/* Name */}
                <div className="space-y-2">
                  <label className="text-sm font-medium text-text-secondary">
                    Nom du programme
                  </label>
                  <div className="relative">
                    {focusedField === 'name' && (
                      <div className="absolute inset-0 bg-accent/10 blur-xl rounded-xl" />
                    )}
                    <input
                      type="text"
                      placeholder="Ex: Push Pull Legs, Full Body 3x..."
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
                          ? 'border-accent shadow-[0_0_0_3px_rgba(255,107,53,0.1)]'
                          : 'border-border hover:border-[rgba(255,255,255,0.12)]'
                      )}
                    />
                  </div>
                </div>

                {/* Description */}
                <div className="space-y-2">
                  <label className="text-sm font-medium text-text-secondary">
                    Description <span className="text-text-muted">(optionnel)</span>
                  </label>
                  <div className="relative">
                    {focusedField === 'description' && (
                      <div className="absolute inset-0 bg-accent/10 blur-xl rounded-xl" />
                    )}
                    <textarea
                      placeholder="Décrivez l'objectif et le déroulement du programme..."
                      value={description}
                      onChange={(e) => setDescription(e.target.value)}
                      onFocus={() => setFocusedField('description')}
                      onBlur={() => setFocusedField(null)}
                      className={cn(
                        'relative w-full h-28 px-4 py-3 rounded-xl resize-none',
                        'bg-surface-elevated border transition-all duration-300',
                        'text-text-primary placeholder:text-text-muted',
                        'focus:outline-none',
                        focusedField === 'description'
                          ? 'border-accent shadow-[0_0_0_3px_rgba(255,107,53,0.1)]'
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
                            ? 'bg-accent/10 border-accent shadow-[0_0_20px_rgba(255,107,53,0.15)]'
                            : 'bg-surface-elevated border-border hover:border-accent/30'
                        )}
                      >
                        <div className="flex items-center gap-3 mb-2">
                          <span className="text-2xl">{goalConfig[g].icon}</span>
                          <span className={cn(
                            'font-semibold transition-colors',
                            goal === g ? 'text-accent' : 'text-text-primary'
                          )}>
                            {goalConfig[g].label}
                          </span>
                        </div>
                        <p className="text-xs text-text-muted">
                          {g === 'bulk' && 'Surplus calorique, focus hypertrophie'}
                          {g === 'cut' && 'Déficit calorique, préserver la masse'}
                          {g === 'maintain' && 'Équilibre, entretien des acquis'}
                        </p>
                        {goal === g && (
                          <div className="absolute top-3 right-3">
                            <div className="w-5 h-5 rounded-full bg-accent flex items-center justify-center">
                              <Check className="w-3 h-3 text-white" />
                            </div>
                          </div>
                        )}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Duration & Deload */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-text-secondary flex items-center gap-2">
                      <Calendar className="w-4 h-4 text-text-muted" />
                      Durée (semaines)
                    </label>
                    <div className="relative">
                      {focusedField === 'duration' && (
                        <div className="absolute inset-0 bg-accent/10 blur-xl rounded-xl" />
                      )}
                      <input
                        type="number"
                        min={1}
                        max={52}
                        value={durationWeeks}
                        onChange={(e) => setDurationWeeks(parseInt(e.target.value) || 1)}
                        onFocus={() => setFocusedField('duration')}
                        onBlur={() => setFocusedField(null)}
                        className={cn(
                          'relative w-full h-12 px-4 rounded-xl',
                          'bg-surface-elevated border transition-all duration-300',
                          'text-text-primary',
                          'focus:outline-none',
                          focusedField === 'duration'
                            ? 'border-accent shadow-[0_0_0_3px_rgba(255,107,53,0.1)]'
                            : 'border-border hover:border-[rgba(255,255,255,0.12)]'
                        )}
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium text-text-secondary flex items-center gap-2">
                      <Zap className="w-4 h-4 text-text-muted" />
                      Deload <span className="text-text-muted">(toutes les X sem)</span>
                    </label>
                    <div className="relative">
                      {focusedField === 'deload' && (
                        <div className="absolute inset-0 bg-accent/10 blur-xl rounded-xl" />
                      )}
                      <input
                        type="number"
                        min={0}
                        max={12}
                        placeholder="Optionnel"
                        value={deloadFrequency || ''}
                        onChange={(e) =>
                          setDeloadFrequency(e.target.value ? parseInt(e.target.value) : undefined)
                        }
                        onFocus={() => setFocusedField('deload')}
                        onBlur={() => setFocusedField(null)}
                        className={cn(
                          'relative w-full h-12 px-4 rounded-xl',
                          'bg-surface-elevated border transition-all duration-300',
                          'text-text-primary placeholder:text-text-muted',
                          'focus:outline-none',
                          focusedField === 'deload'
                            ? 'border-accent shadow-[0_0_0_3px_rgba(255,107,53,0.1)]'
                            : 'border-border hover:border-[rgba(255,255,255,0.12)]'
                        )}
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Step 2: Days */}
          {currentStep === 1 && (
            <div
              className={cn(
                'p-8 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}
            >
              {/* Header */}
              <div className="flex items-center justify-between mb-8">
                <div className="flex items-center gap-4">
                  <div className={cn(
                    'w-14 h-14 rounded-xl flex items-center justify-center',
                    'bg-gradient-to-br from-accent/20 to-accent/5'
                  )}>
                    <Layers className="w-7 h-7 text-accent" />
                  </div>
                  <div>
                    <h2 className="text-xl font-semibold text-text-primary">
                      Jours d'entraînement
                    </h2>
                    <p className="text-sm text-text-muted">
                      {days.length} jour{days.length > 1 ? 's' : ''} configuré{days.length > 1 ? 's' : ''}
                    </p>
                  </div>
                </div>
                <button
                  onClick={addDay}
                  className={cn(
                    'flex items-center gap-2 h-11 px-5 rounded-xl font-semibold text-white',
                    'bg-gradient-to-r from-accent to-[#ff8f5c]',
                    'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
                    'transition-all duration-300'
                  )}
                >
                  <Plus className="w-5 h-5" />
                  Ajouter un jour
                </button>
              </div>

              {/* Days list */}
              <div className="space-y-3">
                {days.map((day, index) => (
                  <div
                    key={day.id}
                    className={cn(
                      'group flex items-center gap-4 p-4 rounded-xl',
                      'bg-surface-elevated border border-border',
                      'hover:border-accent/30 transition-all duration-200',
                      'animate-[fadeIn_0.3s_ease-out]'
                    )}
                    style={{ animationDelay: `${index * 50}ms` }}
                  >
                    <GripVertical className="w-5 h-5 text-text-muted cursor-grab opacity-50 group-hover:opacity-100 transition-opacity" />

                    <div className="flex-1 grid grid-cols-3 gap-4 items-center">
                      {/* Day name */}
                      <input
                        type="text"
                        value={day.name}
                        onChange={(e) => updateDay(day.id, { name: e.target.value })}
                        placeholder="Nom du jour"
                        className={cn(
                          'h-10 px-3 rounded-lg',
                          'bg-surface border border-border',
                          'text-text-primary placeholder:text-text-muted',
                          'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                          'transition-all duration-200'
                        )}
                      />

                      {/* Day of week */}
                      <select
                        value={day.dayOfWeek}
                        onChange={(e) =>
                          updateDay(day.id, { dayOfWeek: parseInt(e.target.value) })
                        }
                        className={cn(
                          'h-10 px-3 rounded-lg appearance-none cursor-pointer',
                          'bg-surface border border-border',
                          'text-text-primary',
                          'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                          'transition-all duration-200'
                        )}
                      >
                        {dayNames.map((name, i) => (
                          <option key={i} value={i}>
                            {name}
                          </option>
                        ))}
                      </select>

                      {/* Rest day toggle */}
                      <div className="flex items-center gap-3">
                        <label className="relative inline-flex items-center cursor-pointer">
                          <input
                            type="checkbox"
                            checked={day.isRestDay}
                            onChange={(e) =>
                              updateDay(day.id, { isRestDay: e.target.checked })
                            }
                            className="sr-only peer"
                          />
                          <div className={cn(
                            'w-11 h-6 rounded-full transition-all',
                            'bg-surface-elevated border border-border',
                            'peer-checked:bg-accent peer-checked:border-accent',
                            'after:content-[\'\'] after:absolute after:top-[2px] after:left-[2px]',
                            'after:bg-white after:rounded-full after:h-5 after:w-5',
                            'after:transition-all peer-checked:after:translate-x-5'
                          )} />
                        </label>
                        <span className={cn(
                          'text-sm font-medium',
                          day.isRestDay ? 'text-text-secondary' : 'text-text-muted'
                        )}>
                          Repos
                        </span>
                      </div>
                    </div>

                    {/* Delete button */}
                    <button
                      onClick={() => removeDay(day.id)}
                      className={cn(
                        'p-2 rounded-lg transition-all duration-200',
                        'text-text-muted hover:text-error hover:bg-error/10'
                      )}
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                ))}

                {days.length === 0 && (
                  <div className={cn(
                    'flex flex-col items-center justify-center py-16 rounded-xl',
                    'border-2 border-dashed border-border'
                  )}>
                    <div className="w-16 h-16 rounded-2xl bg-surface-elevated flex items-center justify-center mb-4">
                      <Calendar className="w-8 h-8 text-text-muted" />
                    </div>
                    <p className="text-text-secondary font-medium mb-1">
                      Aucun jour configuré
                    </p>
                    <p className="text-sm text-text-muted mb-6">
                      Ajoutez des jours d'entraînement pour votre programme
                    </p>
                    <button
                      onClick={addDay}
                      className={cn(
                        'flex items-center gap-2 px-5 py-2.5 rounded-xl',
                        'text-accent font-medium',
                        'bg-accent/10 hover:bg-accent/20',
                        'transition-colors duration-200'
                      )}
                    >
                      <Plus className="w-4 h-4" />
                      Ajouter un jour
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Step 3: Exercises */}
          {currentStep === 2 && (
            <div className="grid grid-cols-5 gap-6 animate-[fadeIn_0.4s_ease-out]">
              {/* Days sidebar */}
              <div className={cn(
                'col-span-2 p-6 rounded-2xl',
                'bg-surface border border-border'
              )}>
                <div className="flex items-center gap-3 mb-6">
                  <div className={cn(
                    'w-10 h-10 rounded-lg flex items-center justify-center',
                    'bg-accent/10'
                  )}>
                    <Layers className="w-5 h-5 text-accent" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-text-primary">Jours</h3>
                    <p className="text-xs text-text-muted">
                      {trainingDays} entraînement{trainingDays > 1 ? 's' : ''}
                    </p>
                  </div>
                </div>

                <div className="space-y-2">
                  {days
                    .filter((d) => !d.isRestDay)
                    .map((day, index) => (
                      <button
                        key={day.id}
                        onClick={() => setEditingDayId(day.id)}
                        className={cn(
                          'w-full flex items-center justify-between p-4 rounded-xl transition-all duration-200',
                          'animate-[fadeIn_0.3s_ease-out]',
                          editingDayId === day.id
                            ? 'bg-accent/10 border-2 border-accent shadow-[0_0_20px_rgba(255,107,53,0.1)]'
                            : 'bg-surface-elevated border border-border hover:border-accent/30'
                        )}
                        style={{ animationDelay: `${index * 50}ms` }}
                      >
                        <div className="text-left">
                          <p className={cn(
                            'font-semibold transition-colors',
                            editingDayId === day.id ? 'text-accent' : 'text-text-primary'
                          )}>
                            {day.name}
                          </p>
                          <p className="text-sm text-text-muted">
                            {day.exercises.length} exercice{day.exercises.length > 1 ? 's' : ''}
                          </p>
                        </div>
                        {day.exercises.length > 0 ? (
                          <div className="w-6 h-6 rounded-full bg-success/20 flex items-center justify-center">
                            <Check className="w-3.5 h-3.5 text-success" />
                          </div>
                        ) : (
                          <div className="w-6 h-6 rounded-full bg-warning/20 flex items-center justify-center">
                            <span className="text-xs text-warning font-bold">!</span>
                          </div>
                        )}
                      </button>
                    ))}
                </div>
              </div>

              {/* Exercise selection */}
              <div className={cn(
                'col-span-3 p-6 rounded-2xl',
                'bg-surface border border-border'
              )}>
                {editingDay ? (
                  <>
                    <div className="flex items-center gap-3 mb-6">
                      <div className={cn(
                        'w-10 h-10 rounded-lg flex items-center justify-center',
                        'bg-gradient-to-br from-accent/20 to-accent/5'
                      )}>
                        <Dumbbell className="w-5 h-5 text-accent" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-text-primary">
                          {editingDay.name}
                        </h3>
                        <p className="text-xs text-text-muted">
                          {editingDay.exercises.length} exercice{editingDay.exercises.length > 1 ? 's' : ''} ajouté{editingDay.exercises.length > 1 ? 's' : ''}
                        </p>
                      </div>
                    </div>

                    {/* Selected exercises */}
                    {editingDay.exercises.length > 0 && (
                      <div className="space-y-2 mb-6">
                        {editingDay.exercises.map((exercise, index) => (
                          <div
                            key={exercise.id}
                            className={cn(
                              'group flex items-center justify-between p-3 rounded-xl',
                              'bg-surface-elevated border border-border',
                              'hover:border-accent/30 transition-all duration-200',
                              'animate-[fadeIn_0.2s_ease-out]'
                            )}
                            style={{ animationDelay: `${index * 30}ms` }}
                          >
                            <div className="flex items-center gap-3">
                              <GripVertical className="w-4 h-4 text-text-muted cursor-grab opacity-50 group-hover:opacity-100" />
                              <div>
                                <p className="font-medium text-text-primary text-sm">
                                  {exercise.name}
                                </p>
                                <div className="flex items-center gap-2 mt-1">
                                  <Badge variant="default" className="text-xs">
                                    {muscleLabels[exercise.muscle]}
                                  </Badge>
                                  <select
                                    value={exercise.mode}
                                    onClick={(e) => e.stopPropagation()}
                                    onChange={(e) =>
                                      updateExercise(editingDay.id, exercise.id, {
                                        mode: e.target.value as ExerciseMode,
                                        sets: createDefaultSets(e.target.value as ExerciseMode),
                                      })
                                    }
                                    className={cn(
                                      'h-5 px-2 text-xs rounded',
                                      'bg-surface border border-border text-text-secondary',
                                      'focus:outline-none focus:border-accent',
                                      'cursor-pointer'
                                    )}
                                  >
                                    {Object.entries(modeLabels).map(([key, label]) => (
                                      <option key={key} value={key}>
                                        {label}
                                      </option>
                                    ))}
                                  </select>
                                  <span className="text-xs text-text-muted">
                                    {exercise.sets.length} sér.
                                  </span>
                                </div>
                              </div>
                            </div>
                            <button
                              onClick={() =>
                                removeExercise(editingDay.id, exercise.id)
                              }
                              className={cn(
                                'p-1.5 rounded-lg transition-all duration-200',
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

                    {/* Muscle groups catalog */}
                    <div className="border-t border-border pt-4">
                      <p className="text-sm font-medium text-text-secondary mb-3">
                        Ajouter un exercice
                      </p>
                      <div className="space-y-1 max-h-[300px] overflow-y-auto pr-2">
                        {(Object.keys(exerciseCatalog) as MuscleGroup[]).map(
                          (muscle) => (
                            <div key={muscle}>
                              <button
                                onClick={() =>
                                  setExpandedMuscle(
                                    expandedMuscle === muscle ? null : muscle
                                  )
                                }
                                className={cn(
                                  'w-full flex items-center justify-between p-3 rounded-lg',
                                  'transition-all duration-200',
                                  expandedMuscle === muscle
                                    ? 'bg-accent/10 text-accent'
                                    : 'hover:bg-surface-elevated text-text-primary'
                                )}
                              >
                                <div className="flex items-center gap-3">
                                  <span className="text-lg">{muscleIcons[muscle]}</span>
                                  <span className="text-sm font-medium">
                                    {muscleLabels[muscle]}
                                  </span>
                                </div>
                                {expandedMuscle === muscle ? (
                                  <ChevronUp className="w-4 h-4" />
                                ) : (
                                  <ChevronDown className="w-4 h-4 text-text-muted" />
                                )}
                              </button>
                              {expandedMuscle === muscle && (
                                <div className="pl-10 space-y-1 mt-1 mb-2 animate-[fadeIn_0.2s_ease-out]">
                                  {exerciseCatalog[muscle].map((ex) => (
                                    <button
                                      key={ex.id}
                                      onClick={() =>
                                        addExerciseToDay(
                                          editingDay.id,
                                          ex.name,
                                          muscle
                                        )
                                      }
                                      className={cn(
                                        'w-full flex items-center justify-between p-2.5 rounded-lg',
                                        'text-sm text-text-secondary',
                                        'hover:text-accent hover:bg-accent/5',
                                        'transition-all duration-150'
                                      )}
                                    >
                                      {ex.name}
                                      <Plus className="w-4 h-4" />
                                    </button>
                                  ))}
                                </div>
                              )}
                            </div>
                          )
                        )}
                      </div>
                    </div>
                  </>
                ) : (
                  <div className="flex flex-col items-center justify-center h-full py-16">
                    <div className="w-16 h-16 rounded-2xl bg-surface-elevated flex items-center justify-center mb-4">
                      <Dumbbell className="w-8 h-8 text-text-muted" />
                    </div>
                    <p className="text-text-secondary font-medium mb-1">
                      Sélectionnez un jour
                    </p>
                    <p className="text-sm text-text-muted">
                      pour ajouter des exercices
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Step 4: Recap */}
          {currentStep === 3 && (
            <div
              className={cn(
                'p-8 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}
            >
              {/* Header */}
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
                    Vérifiez votre programme avant de le créer
                  </p>
                </div>
              </div>

              {/* Info summary */}
              <div className="grid grid-cols-4 gap-4 mb-8">
                {[
                  { label: 'Nom', value: name, icon: Target },
                  { label: 'Objectif', value: goalConfig[goal].label, icon: Sparkles, badge: true, badgeVariant: goalConfig[goal].color as 'success' | 'warning' | 'info' },
                  { label: 'Durée', value: `${durationWeeks} semaines`, icon: Calendar },
                  { label: 'Exercices', value: totalExercises.toString(), icon: Dumbbell },
                ].map((item, index) => (
                  <div
                    key={item.label}
                    className={cn(
                      'p-4 rounded-xl',
                      'bg-surface-elevated border border-border',
                      'animate-[fadeIn_0.3s_ease-out]'
                    )}
                    style={{ animationDelay: `${index * 50}ms` }}
                  >
                    <div className="flex items-center gap-2 mb-2">
                      <item.icon className="w-4 h-4 text-text-muted" />
                      <p className="text-xs text-text-muted">{item.label}</p>
                    </div>
                    {item.badge ? (
                      <Badge variant={item.badgeVariant}>{item.value}</Badge>
                    ) : (
                      <p className="font-semibold text-text-primary truncate">
                        {item.value}
                      </p>
                    )}
                  </div>
                ))}
              </div>

              {/* Days summary */}
              <div>
                <h4 className="text-sm font-semibold text-text-secondary mb-4 flex items-center gap-2">
                  <Layers className="w-4 h-4" />
                  Programme ({days.length} jour{days.length > 1 ? 's' : ''})
                </h4>
                <div className="space-y-3">
                  {days.map((day, index) => (
                    <div
                      key={day.id}
                      className={cn(
                        'p-4 rounded-xl',
                        'bg-surface-elevated border border-border',
                        'animate-[fadeIn_0.3s_ease-out]'
                      )}
                      style={{ animationDelay: `${(index + 4) * 50}ms` }}
                    >
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex items-center gap-3">
                          <div className={cn(
                            'w-8 h-8 rounded-lg flex items-center justify-center text-sm font-bold',
                            day.isRestDay
                              ? 'bg-surface text-text-muted'
                              : 'bg-accent/10 text-accent'
                          )}>
                            {index + 1}
                          </div>
                          <div>
                            <h5 className="font-semibold text-text-primary">
                              {day.name}
                            </h5>
                            <span className="text-xs text-text-muted">
                              {dayNames[day.dayOfWeek]}
                            </span>
                          </div>
                        </div>
                        {day.isRestDay ? (
                          <Badge variant="default">
                            <Clock className="w-3 h-3 mr-1" />
                            Repos
                          </Badge>
                        ) : (
                          <span className="text-sm text-text-muted">
                            {day.exercises.length} exercice{day.exercises.length > 1 ? 's' : ''}
                          </span>
                        )}
                      </div>
                      {!day.isRestDay && day.exercises.length > 0 && (
                        <div className="flex flex-wrap gap-2">
                          {day.exercises.map((ex) => (
                            <Badge key={ex.id} variant="accent" className="text-xs">
                              {ex.name}
                            </Badge>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
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
                  ? 'bg-gradient-to-r from-accent to-[#ff8f5c] hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]'
                  : 'bg-surface-elevated text-text-muted cursor-not-allowed'
              )}
            >
              {currentStep === steps.length - 1 ? (
                <>
                  <Check className="w-5 h-5" />
                  Créer le programme
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
