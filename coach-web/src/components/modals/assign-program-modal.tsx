import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { X, Dumbbell, Check, Loader2, Plus } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useStudentsStore } from '@/store/students-store'
import { useProgramsStore } from '@/store/programs-store'
import { Badge } from '@/components/ui'
import type { Student } from '@/types'

interface AssignProgramModalProps {
  isOpen: boolean
  onClose: () => void
  student: Student
}

const goalConfig = {
  bulk: { label: 'Masse', color: 'success' },
  cut: { label: 'Sèche', color: 'warning' },
  maintain: { label: 'Maintien', color: 'info' },
  strength: { label: 'Force', color: 'default' },
  endurance: { label: 'Endurance', color: 'info' },
  recomp: { label: 'Recomp', color: 'success' },
  other: { label: 'Autre', color: 'default' },
} as const

export function AssignProgramModal({ isOpen, onClose, student }: AssignProgramModalProps) {
  const navigate = useNavigate()
  const { assignProgram } = useStudentsStore()
  const { programs, assignToStudent, unassignFromStudent } = useProgramsStore()

  const [selectedProgramId, setSelectedProgramId] = useState<string | undefined>(student.assignedProgramId)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleSubmit = async () => {
    setIsSubmitting(true)

    await new Promise(resolve => setTimeout(resolve, 500))

    // Retirer l'ancien programme si existant
    if (student.assignedProgramId && student.assignedProgramId !== selectedProgramId) {
      unassignFromStudent(student.assignedProgramId, student.id)
    }

    // Assigner le nouveau programme
    assignProgram(student.id, selectedProgramId)
    if (selectedProgramId) {
      assignToStudent(selectedProgramId, student.id)
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
            <div className="w-10 h-10 rounded-xl bg-accent/10 flex items-center justify-center">
              <Dumbbell className="w-5 h-5 text-accent" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-text-primary">Assigner un programme</h2>
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
          {/* Option: Aucun programme */}
          <button
            onClick={() => setSelectedProgramId(undefined)}
            className={cn(
              'w-full flex items-center justify-between p-4 rounded-xl transition-all duration-200',
              'border',
              !selectedProgramId
                ? 'bg-accent/10 border-accent'
                : 'bg-surface-elevated border-border hover:border-accent/30'
            )}
          >
            <span className="font-medium text-text-secondary">Aucun programme</span>
            {!selectedProgramId && (
              <div className="w-6 h-6 rounded-full bg-accent flex items-center justify-center">
                <Check className="w-4 h-4 text-white" />
              </div>
            )}
          </button>

          {programs.map((program) => (
            <button
              key={program.id}
              onClick={() => setSelectedProgramId(program.id)}
              className={cn(
                'w-full flex items-center justify-between p-4 rounded-xl transition-all duration-200',
                'border text-left',
                selectedProgramId === program.id
                  ? 'bg-accent/10 border-accent'
                  : 'bg-surface-elevated border-border hover:border-accent/30'
              )}
            >
              <div>
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-semibold text-text-primary">{program.name}</span>
                  <Badge
                    variant={goalConfig[program.goal].color as 'success' | 'warning' | 'info'}
                    className="text-xs"
                  >
                    {goalConfig[program.goal].label}
                  </Badge>
                </div>
                <p className="text-sm text-text-muted">
                  {program.durationWeeks} semaines - {program.days.length} jours
                </p>
              </div>
              {selectedProgramId === program.id && (
                <div className="w-6 h-6 rounded-full bg-accent flex items-center justify-center">
                  <Check className="w-4 h-4 text-white" />
                </div>
              )}
            </button>
          ))}

          {/* Créer un nouveau programme */}
          <button
            onClick={() => {
              onClose()
              navigate('/programs/create')
            }}
            className={cn(
              'w-full flex items-center justify-center gap-2 p-4 rounded-xl transition-all duration-200',
              'border-2 border-dashed border-border',
              'text-text-muted hover:text-accent hover:border-accent/50 hover:bg-accent/5'
            )}
          >
            <Plus className="w-5 h-5" />
            <span className="font-medium">Créer un nouveau programme</span>
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
              'bg-gradient-to-r from-accent to-[#ff8f5c]',
              'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
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
