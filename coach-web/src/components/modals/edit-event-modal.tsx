import { useState, useEffect } from 'react'
import { X, Calendar, Loader2, Dumbbell, Apple, MessageSquare, Trash2, Save } from 'lucide-react'
import { format } from 'date-fns'
import { fr } from 'date-fns/locale'
import { cn } from '@/lib/utils'
import { useEventsStore } from '@/store/events-store'
import { useStudentsStore } from '@/store/students-store'
import type { CalendarEvent } from '@/types'

interface EditEventModalProps {
  isOpen: boolean
  onClose: () => void
  event: CalendarEvent | null
}

type EventType = CalendarEvent['type']

const eventTypeOptions: { value: EventType; label: string; icon: React.ElementType; color: string }[] = [
  { value: 'workout', label: 'Entraînement', icon: Dumbbell, color: 'bg-accent/10 text-accent border-accent/30' },
  { value: 'nutrition', label: 'Nutrition', icon: Apple, color: 'bg-success/10 text-success border-success/30' },
  { value: 'check-in', label: 'Check-in', icon: MessageSquare, color: 'bg-info/10 text-info border-info/30' },
]

export function EditEventModal({ isOpen, onClose, event }: EditEventModalProps) {
  const { updateEvent, deleteEvent } = useEventsStore()
  const { students } = useStudentsStore()

  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [formData, setFormData] = useState({
    title: '',
    type: 'workout' as EventType,
    date: '',
    time: '',
    studentId: '',
    notes: '',
  })

  useEffect(() => {
    if (event) {
      setFormData({
        title: event.title,
        type: event.type,
        date: event.date,
        time: event.time || '09:00',
        studentId: event.studentId || '',
        notes: event.description || '',
      })
    }
  }, [event])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!event) return

    setIsSubmitting(true)
    try {
      await updateEvent(event.id, {
        title: formData.title,
        type: formData.type,
        date: formData.date,
        time: formData.time,
        studentId: formData.studentId || undefined,
        description: formData.notes || undefined,
      })
      onClose()
    } catch (error) {
      console.error('Error updating event:', error)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleDelete = async () => {
    if (!event) return

    setIsDeleting(true)
    try {
      await deleteEvent(event.id)
      setShowDeleteConfirm(false)
      onClose()
    } catch (error) {
      console.error('Error deleting event:', error)
    } finally {
      setIsDeleting(false)
    }
  }

  if (!isOpen || !event) return null

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
              <Calendar className="w-5 h-5 text-accent" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-text-primary">Modifier l'événement</h2>
              <p className="text-sm text-text-muted capitalize">
                {format(new Date(formData.date), 'EEEE d MMMM', { locale: fr })}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface-elevated transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {showDeleteConfirm ? (
          <div className="p-6">
            <div className="text-center py-4">
              <div className="w-16 h-16 mx-auto rounded-full bg-error/10 flex items-center justify-center mb-4">
                <Trash2 className="w-8 h-8 text-error" />
              </div>
              <h3 className="text-lg font-semibold text-text-primary mb-2">
                Supprimer cet événement ?
              </h3>
              <p className="text-text-muted mb-6">
                Cette action est irréversible. L'événement "{event.title}" sera définitivement supprimé.
              </p>
              <div className="flex items-center gap-3">
                <button
                  onClick={() => setShowDeleteConfirm(false)}
                  className={cn(
                    'flex-1 h-11 rounded-xl font-medium',
                    'bg-surface-elevated border border-border',
                    'text-text-secondary hover:text-text-primary',
                    'transition-all duration-200'
                  )}
                >
                  Annuler
                </button>
                <button
                  onClick={handleDelete}
                  disabled={isDeleting}
                  className={cn(
                    'flex-1 flex items-center justify-center gap-2 h-11 rounded-xl font-semibold text-white',
                    'bg-gradient-to-r from-error to-[#f87171]',
                    'hover:shadow-[0_0_25px_rgba(239,68,68,0.35)]',
                    'disabled:opacity-50 disabled:cursor-not-allowed',
                    'transition-all duration-300'
                  )}
                >
                  {isDeleting ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin" />
                      Suppression...
                    </>
                  ) : (
                    <>
                      <Trash2 className="w-4 h-4" />
                      Supprimer
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="p-6 space-y-5">
            {/* Type */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-text-secondary">
                Type d'événement <span className="text-error">*</span>
              </label>
              <div className="grid grid-cols-3 gap-2">
                {eventTypeOptions.map((option) => (
                  <button
                    key={option.value}
                    type="button"
                    onClick={() => setFormData(prev => ({ ...prev, type: option.value }))}
                    className={cn(
                      'flex flex-col items-center gap-2 py-4 px-3 rounded-xl text-sm font-medium border transition-all duration-200',
                      formData.type === option.value
                        ? option.color
                        : 'bg-surface-elevated border-border text-text-secondary hover:border-text-muted'
                    )}
                  >
                    <option.icon className="w-5 h-5" />
                    {option.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Title */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-text-secondary">
                Titre <span className="text-error">*</span>
              </label>
              <input
                type="text"
                required
                value={formData.title}
                onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
                placeholder="Ex: Push A - Marie"
                className={cn(
                  'w-full h-11 px-4 rounded-xl',
                  'bg-surface-elevated border border-border',
                  'text-text-primary placeholder:text-text-muted',
                  'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                  'transition-all duration-200'
                )}
              />
            </div>

            {/* Student */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-text-secondary">
                Élève
              </label>
              <select
                value={formData.studentId}
                onChange={(e) => setFormData(prev => ({ ...prev, studentId: e.target.value }))}
                className={cn(
                  'w-full h-11 px-4 rounded-xl appearance-none',
                  'bg-surface-elevated border border-border',
                  'text-text-primary',
                  'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                  'transition-all duration-200'
                )}
              >
                <option value="">Sélectionner un élève</option>
                {students.map((student) => (
                  <option key={student.id} value={student.id}>
                    {student.name}
                  </option>
                ))}
              </select>
            </div>

            {/* Date & Time */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-secondary">
                  Date <span className="text-error">*</span>
                </label>
                <input
                  type="date"
                  required
                  value={formData.date}
                  onChange={(e) => setFormData(prev => ({ ...prev, date: e.target.value }))}
                  className={cn(
                    'w-full h-11 px-4 rounded-xl',
                    'bg-surface-elevated border border-border',
                    'text-text-primary',
                    'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                    'transition-all duration-200'
                  )}
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-text-secondary">
                  Heure <span className="text-error">*</span>
                </label>
                <input
                  type="time"
                  required
                  value={formData.time}
                  onChange={(e) => setFormData(prev => ({ ...prev, time: e.target.value }))}
                  className={cn(
                    'w-full h-11 px-4 rounded-xl',
                    'bg-surface-elevated border border-border',
                    'text-text-primary',
                    'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                    'transition-all duration-200'
                  )}
                />
              </div>
            </div>

            {/* Notes */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-text-secondary">
                Notes (optionnel)
              </label>
              <textarea
                value={formData.notes}
                onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
                placeholder="Notes supplémentaires..."
                rows={3}
                className={cn(
                  'w-full px-4 py-3 rounded-xl resize-none',
                  'bg-surface-elevated border border-border',
                  'text-text-primary placeholder:text-text-muted',
                  'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                  'transition-all duration-200'
                )}
              />
            </div>

            {/* Actions */}
            <div className="flex items-center justify-between pt-4">
              <button
                type="button"
                onClick={() => setShowDeleteConfirm(true)}
                className={cn(
                  'flex items-center gap-2 h-11 px-4 rounded-xl font-medium',
                  'bg-error/10 text-error border border-error/30',
                  'hover:bg-error/20 hover:shadow-[0_0_15px_rgba(239,68,68,0.2)]',
                  'transition-all duration-200'
                )}
              >
                <Trash2 className="w-4 h-4" />
                Supprimer
              </button>

              <div className="flex items-center gap-3">
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
                  disabled={isSubmitting || !formData.title}
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
                      Enregistrement...
                    </>
                  ) : (
                    <>
                      <Save className="w-4 h-4" />
                      Enregistrer
                    </>
                  )}
                </button>
              </div>
            </div>
          </form>
        )}
      </div>
    </div>
  )
}
