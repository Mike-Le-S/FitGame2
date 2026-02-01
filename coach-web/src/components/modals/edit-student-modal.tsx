import { useState, useEffect } from 'react'
import { X, Save, Loader2 } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useStudentsStore } from '@/store/students-store'
import type { Goal, Student } from '@/types'

interface EditStudentModalProps {
  isOpen: boolean
  onClose: () => void
  student: Student
}

const goalOptions: { value: Goal; label: string; color: string }[] = [
  { value: 'bulk', label: 'Prise de masse', color: 'bg-success/10 text-success border-success/30' },
  { value: 'cut', label: 'Sèche', color: 'bg-warning/10 text-warning border-warning/30' },
  { value: 'maintain', label: 'Maintien', color: 'bg-info/10 text-info border-info/30' },
]

export function EditStudentModal({ isOpen, onClose, student }: EditStudentModalProps) {
  const { updateStudent } = useStudentsStore()

  const [isSubmitting, setIsSubmitting] = useState(false)
  const [formData, setFormData] = useState({
    name: student.name,
    email: student.email,
    goal: student.goal,
  })

  useEffect(() => {
    if (isOpen) {
      setFormData({
        name: student.name,
        email: student.email,
        goal: student.goal,
      })
    }
  }, [isOpen, student])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)

    await new Promise(resolve => setTimeout(resolve, 500))

    updateStudent(student.id, {
      name: formData.name,
      email: formData.email,
      goal: formData.goal,
    })

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
          <div>
            <h2 className="text-lg font-semibold text-text-primary">Modifier le profil</h2>
            <p className="text-sm text-text-muted">{student.name}</p>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface-elevated transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          <div className="space-y-2">
            <label className="text-sm font-medium text-text-secondary">
              Nom complet <span className="text-error">*</span>
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              className={cn(
                'w-full h-11 px-4 rounded-xl',
                'bg-surface-elevated border border-border',
                'text-text-primary placeholder:text-text-muted',
                'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                'transition-all duration-200'
              )}
            />
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium text-text-secondary">
              Email <span className="text-error">*</span>
            </label>
            <input
              type="email"
              required
              value={formData.email}
              onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
              className={cn(
                'w-full h-11 px-4 rounded-xl',
                'bg-surface-elevated border border-border',
                'text-text-primary placeholder:text-text-muted',
                'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                'transition-all duration-200'
              )}
            />
          </div>

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
                  Sauvegarde...
                </>
              ) : (
                <>
                  <Save className="w-4 h-4" />
                  Enregistrer
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
