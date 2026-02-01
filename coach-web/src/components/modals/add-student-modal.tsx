import { useState } from 'react'
import { X, UserPlus, Loader2 } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useStudentsStore } from '@/store/students-store'
import { useProgramsStore } from '@/store/programs-store'
import { useNutritionStore } from '@/store/nutrition-store'
import type { Goal } from '@/types'

interface AddStudentModalProps {
  isOpen: boolean
  onClose: () => void
}

const goalOptions: { value: Goal; label: string; color: string }[] = [
  { value: 'bulk', label: 'Prise de masse', color: 'bg-success/10 text-success border-success/30' },
  { value: 'cut', label: 'Sèche', color: 'bg-warning/10 text-warning border-warning/30' },
  { value: 'maintain', label: 'Maintien', color: 'bg-info/10 text-info border-info/30' },
]

export function AddStudentModal({ isOpen, onClose }: AddStudentModalProps) {
  const { addStudent } = useStudentsStore()
  const { programs, assignToStudent: assignProgramToStudent } = useProgramsStore()
  const { dietPlans, assignToStudent: assignDietToStudent } = useNutritionStore()

  const [isSubmitting, setIsSubmitting] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    goal: 'maintain' as Goal,
    assignedProgramId: '',
    assignedDietId: '',
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)

    try {
      const studentId = await addStudent({
        name: formData.name,
        email: formData.email,
        goal: formData.goal,
        assignedProgramId: formData.assignedProgramId || undefined,
        assignedDietId: formData.assignedDietId || undefined,
      })

      // Mettre à jour les assignations dans les stores programmes/nutrition
      if (formData.assignedProgramId) {
        await assignProgramToStudent(formData.assignedProgramId, studentId)
      }
      if (formData.assignedDietId) {
        await assignDietToStudent(formData.assignedDietId, studentId)
      }

      setFormData({
        name: '',
        email: '',
        goal: 'maintain',
        assignedProgramId: '',
        assignedDietId: '',
      })
      onClose()
    } catch (error: any) {
      console.error('Error adding student:', error)
      alert(error.message || 'Erreur lors de l\'ajout de l\'élève')
    } finally {
      setIsSubmitting(false)
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal */}
      <div className={cn(
        'relative w-full max-w-lg mx-4',
        'bg-surface border border-border rounded-2xl',
        'shadow-2xl',
        'animate-[fadeIn_0.2s_ease-out]'
      )}>
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-border">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-accent/10 flex items-center justify-center">
              <UserPlus className="w-5 h-5 text-accent" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-text-primary">Ajouter un élève</h2>
              <p className="text-sm text-text-muted">Créer un nouveau profil élève</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface-elevated transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          {/* Name */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-text-secondary">
              Nom complet <span className="text-error">*</span>
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              placeholder="Marie Laurent"
              className={cn(
                'w-full h-11 px-4 rounded-xl',
                'bg-surface-elevated border border-border',
                'text-text-primary placeholder:text-text-muted',
                'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                'transition-all duration-200'
              )}
            />
          </div>

          {/* Email */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-text-secondary">
              Email <span className="text-error">*</span>
            </label>
            <input
              type="email"
              required
              value={formData.email}
              onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
              placeholder="marie@email.com"
              className={cn(
                'w-full h-11 px-4 rounded-xl',
                'bg-surface-elevated border border-border',
                'text-text-primary placeholder:text-text-muted',
                'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                'transition-all duration-200'
              )}
            />
          </div>

          {/* Goal */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-text-secondary">
              Objectif <span className="text-error">*</span>
            </label>
            <div className="grid grid-cols-3 gap-2">
              {goalOptions.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => setFormData(prev => ({ ...prev, goal: option.value }))}
                  className={cn(
                    'py-3 px-4 rounded-xl text-sm font-medium border transition-all duration-200',
                    formData.goal === option.value
                      ? option.color
                      : 'bg-surface-elevated border-border text-text-secondary hover:border-text-muted'
                  )}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </div>

          {/* Assigned Program */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-text-secondary">
              Programme (optionnel)
            </label>
            <select
              value={formData.assignedProgramId}
              onChange={(e) => setFormData(prev => ({ ...prev, assignedProgramId: e.target.value }))}
              className={cn(
                'w-full h-11 px-4 rounded-xl appearance-none',
                'bg-surface-elevated border border-border',
                'text-text-primary',
                'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                'transition-all duration-200'
              )}
            >
              <option value="">Aucun programme</option>
              {programs.map((program) => (
                <option key={program.id} value={program.id}>
                  {program.name}
                </option>
              ))}
            </select>
          </div>

          {/* Assigned Diet */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-text-secondary">
              Plan nutrition (optionnel)
            </label>
            <select
              value={formData.assignedDietId}
              onChange={(e) => setFormData(prev => ({ ...prev, assignedDietId: e.target.value }))}
              className={cn(
                'w-full h-11 px-4 rounded-xl appearance-none',
                'bg-surface-elevated border border-border',
                'text-text-primary',
                'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                'transition-all duration-200'
              )}
            >
              <option value="">Aucun plan</option>
              {dietPlans.map((diet) => (
                <option key={diet.id} value={diet.id}>
                  {diet.name}
                </option>
              ))}
            </select>
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end gap-3 pt-4">
            <button
              type="button"
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
              type="submit"
              disabled={isSubmitting || !formData.name || !formData.email}
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
                  Création...
                </>
              ) : (
                <>
                  <UserPlus className="w-4 h-4" />
                  Créer l'élève
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
