import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { X, Apple, Check, Loader2, Flame, Plus } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useStudentsStore } from '@/store/students-store'
import { useNutritionStore } from '@/store/nutrition-store'
import { Badge } from '@/components/ui'
import { goalConfig } from '@/constants/goals'
import type { Student } from '@/types'

interface AssignDietModalProps {
  isOpen: boolean
  onClose: () => void
  student: Student
}

export function AssignDietModal({ isOpen, onClose, student }: AssignDietModalProps) {
  const navigate = useNavigate()
  const { assignDiet } = useStudentsStore()
  const { dietPlans, assignToStudent, unassignFromStudent } = useNutritionStore()

  const [selectedDietId, setSelectedDietId] = useState<string | undefined>(student.assignedDietId)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleSubmit = async () => {
    setIsSubmitting(true)

    await new Promise(resolve => setTimeout(resolve, 500))

    // Retirer l'ancien plan si existant
    if (student.assignedDietId && student.assignedDietId !== selectedDietId) {
      unassignFromStudent(student.assignedDietId, student.id)
    }

    // Assigner le nouveau plan
    assignDiet(student.id, selectedDietId)
    if (selectedDietId) {
      assignToStudent(selectedDietId, student.id)
    }

    setIsSubmitting(false)
    onClose()
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={onClose}
      />

      <div className={cn(
        'relative w-full max-w-lg mx-4',
        'bg-surface border border-border rounded-2xl',
        'shadow-2xl animate-[fadeIn_0.2s_ease-out]'
      )}>
        <div className="flex items-center justify-between p-6 border-b border-border">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-success/10 flex items-center justify-center">
              <Apple className="w-5 h-5 text-success" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-text-primary">Assigner un plan nutrition</h2>
              <p className="text-sm text-text-muted">{student.name}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface-elevated transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6 space-y-3 max-h-[400px] overflow-y-auto">
          {/* Option: Aucun plan */}
          <button
            onClick={() => setSelectedDietId(undefined)}
            className={cn(
              'w-full flex items-center justify-between p-4 rounded-xl transition-all duration-200',
              'border',
              !selectedDietId
                ? 'bg-success/10 border-success'
                : 'bg-surface-elevated border-border hover:border-success/30'
            )}
          >
            <span className="font-medium text-text-secondary">Aucun plan</span>
            {!selectedDietId && (
              <div className="w-6 h-6 rounded-full bg-success flex items-center justify-center">
                <Check className="w-4 h-4 text-white" />
              </div>
            )}
          </button>

          {dietPlans.map((diet) => (
            <button
              key={diet.id}
              onClick={() => setSelectedDietId(diet.id)}
              className={cn(
                'w-full flex items-center justify-between p-4 rounded-xl transition-all duration-200',
                'border text-left',
                selectedDietId === diet.id
                  ? 'bg-success/10 border-success'
                  : 'bg-surface-elevated border-border hover:border-success/30'
              )}
            >
              <div>
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-semibold text-text-primary">{diet.name}</span>
                  <Badge
                    variant={goalConfig[diet.goal].color as 'success' | 'warning' | 'info'}
                    className="text-xs"
                  >
                    {goalConfig[diet.goal].label}
                  </Badge>
                </div>
                <div className="flex items-center gap-3 text-sm text-text-muted">
                  <span className="flex items-center gap-1">
                    <Flame className="w-3 h-3" />
                    {diet.trainingCalories} kcal
                  </span>
                  <span>{diet.meals.length} repas</span>
                </div>
              </div>
              {selectedDietId === diet.id && (
                <div className="w-6 h-6 rounded-full bg-success flex items-center justify-center">
                  <Check className="w-4 h-4 text-white" />
                </div>
              )}
            </button>
          ))}

          {/* Créer un nouveau plan */}
          <button
            onClick={() => {
              onClose()
              navigate('/nutrition/create')
            }}
            className={cn(
              'w-full flex items-center justify-center gap-2 p-4 rounded-xl transition-all duration-200',
              'border-2 border-dashed border-border',
              'text-text-muted hover:text-success hover:border-success/50 hover:bg-success/5'
            )}
          >
            <Plus className="w-5 h-5" />
            <span className="font-medium">Créer un nouveau plan</span>
          </button>
        </div>

        <div className="flex items-center justify-end gap-3 p-6 border-t border-border">
          <button
            onClick={onClose}
            className={cn(
              'h-11 px-5 rounded-xl font-medium',
              'bg-surface-elevated border border-border',
              'text-text-secondary hover:text-text-primary',
              'transition-all duration-200'
            )}
          >
            Annuler
          </button>
          <button
            onClick={handleSubmit}
            disabled={isSubmitting}
            className={cn(
              'flex items-center gap-2 h-11 px-6 rounded-xl font-semibold text-white',
              'bg-gradient-to-r from-success to-[#4ade80]',
              'hover:shadow-[0_0_25px_rgba(34,197,94,0.35)]',
              'disabled:opacity-50 disabled:cursor-not-allowed',
              'transition-all duration-300'
            )}
          >
            {isSubmitting ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                Assignation...
              </>
            ) : (
              'Confirmer'
            )}
          </button>
        </div>
      </div>
    </div>
  )
}
