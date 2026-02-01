import { X, Dumbbell, Clock, Calendar, FileText } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Badge } from '@/components/ui'
import type { Exercise, MuscleGroup, ExerciseMode } from '@/types'

interface SessionData {
  id: string
  name: string
  date: Date
  duration: number
  completed: boolean
  exercises: Exercise[]
  notes?: string
}

interface SessionDetailModalProps {
  isOpen: boolean
  onClose: () => void
  session: SessionData | null
}

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

const modeLabels: Record<ExerciseMode, string> = {
  classic: 'Classic',
  rpt: 'Reverse Pyramid',
  pyramidal: 'Pyramidal',
  dropset: 'Drop Set',
}

function formatSessionDate(date: Date): string {
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))

  if (days === 0) return "Aujourd'hui"
  if (days === 1) return 'Hier'
  if (days < 7) return `Il y a ${days} jours`

  return date.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
}

export function SessionDetailModal({ isOpen, onClose, session }: SessionDetailModalProps) {
  if (!isOpen || !session) return null

  const workingSets = session.exercises.reduce((acc, ex) => {
    return acc + ex.sets.filter(s => !s.isWarmup).length
  }, 0)

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={onClose}
      />

      <div className={cn(
        'relative w-full max-w-2xl mx-4 max-h-[85vh] flex flex-col',
        'bg-surface border border-border rounded-2xl',
        'shadow-2xl animate-[fadeIn_0.2s_ease-out]'
      )}>
        {/* Header */}
        <div className="flex items-start justify-between p-6 border-b border-border">
          <div className="flex items-start gap-4">
            <div className={cn(
              'w-12 h-12 rounded-xl flex items-center justify-center',
              session.completed ? 'bg-accent/10' : 'bg-warning/10'
            )}>
              <Dumbbell className={cn(
                'w-6 h-6',
                session.completed ? 'text-accent' : 'text-warning'
              )} />
            </div>
            <div>
              <div className="flex items-center gap-3 mb-1">
                <h2 className="text-xl font-bold text-text-primary">{session.name}</h2>
                <Badge variant={session.completed ? 'success' : 'warning'}>
                  {session.completed ? 'Complétée' : 'Manquée'}
                </Badge>
              </div>
              <div className="flex items-center gap-4 text-sm text-text-muted">
                <span className="flex items-center gap-1.5">
                  <Calendar className="w-4 h-4" />
                  {formatSessionDate(session.date)}
                </span>
                {session.completed && (
                  <span className="flex items-center gap-1.5">
                    <Clock className="w-4 h-4" />
                    {session.duration} min
                  </span>
                )}
              </div>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface-elevated transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Stats bar */}
        <div className="flex items-center gap-6 px-6 py-4 border-b border-border bg-surface-elevated/50">
          <div className="text-center">
            <p className="text-2xl font-bold text-text-primary">{session.exercises.length}</p>
            <p className="text-xs text-text-muted">Exercices</p>
          </div>
          <div className="w-px h-10 bg-border" />
          <div className="text-center">
            <p className="text-2xl font-bold text-text-primary">{workingSets}</p>
            <p className="text-xs text-text-muted">Séries</p>
          </div>
          {session.completed && (
            <>
              <div className="w-px h-10 bg-border" />
              <div className="text-center">
                <p className="text-2xl font-bold text-accent">{session.duration}</p>
                <p className="text-xs text-text-muted">Minutes</p>
              </div>
            </>
          )}
        </div>

        {/* Exercises list */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {session.exercises.map((exercise) => {
            const workingSetsForExercise = exercise.sets.filter(s => !s.isWarmup)

            return (
              <div
                key={exercise.id}
                className="p-4 rounded-xl bg-surface-elevated border border-border/50"
              >
                {/* Exercise header */}
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <h4 className="font-semibold text-text-primary">{exercise.name}</h4>
                    <Badge variant="default" className="text-xs">
                      {muscleLabels[exercise.muscle]}
                    </Badge>
                  </div>
                  <span className="text-xs text-text-muted px-2 py-1 rounded-md bg-surface">
                    {modeLabels[exercise.mode]}
                  </span>
                </div>

                {/* Sets table */}
                <div className="rounded-lg overflow-hidden border border-border/50">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="bg-surface">
                        <th className="py-2 px-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">
                          Série
                        </th>
                        <th className="py-2 px-3 text-center text-xs font-medium text-text-muted uppercase tracking-wider">
                          Reps
                        </th>
                        <th className="py-2 px-3 text-center text-xs font-medium text-text-muted uppercase tracking-wider">
                          Poids
                        </th>
                        {session.completed && (
                          <th className="py-2 px-3 text-center text-xs font-medium text-text-muted uppercase tracking-wider">
                            Réalisé
                          </th>
                        )}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border/50">
                      {workingSetsForExercise.map((set, index) => (
                        <tr key={set.id} className="hover:bg-surface/50 transition-colors">
                          <td className="py-2.5 px-3 text-text-secondary">
                            {index + 1}
                          </td>
                          <td className="py-2.5 px-3 text-center font-medium text-text-primary">
                            {set.targetReps}
                          </td>
                          <td className="py-2.5 px-3 text-center font-medium text-text-primary">
                            {set.targetWeight} kg
                          </td>
                          {session.completed && (
                            <td className="py-2.5 px-3 text-center">
                              {set.actualReps !== undefined && set.actualWeight !== undefined ? (
                                <span className={cn(
                                  'font-medium',
                                  set.actualReps >= set.targetReps
                                    ? 'text-success'
                                    : 'text-warning'
                                )}>
                                  {set.actualReps} × {set.actualWeight} kg
                                </span>
                              ) : (
                                <span className="text-text-muted">-</span>
                              )}
                            </td>
                          )}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Exercise notes */}
                {exercise.notes && (
                  <div className="mt-3 p-3 rounded-lg bg-surface text-sm text-text-muted">
                    <span className="text-text-secondary font-medium">Note :</span> {exercise.notes}
                  </div>
                )}
              </div>
            )
          })}
        </div>

        {/* Session notes */}
        {session.notes && (
          <div className="px-6 py-4 border-t border-border">
            <div className="flex items-start gap-3 p-4 rounded-xl bg-surface-elevated">
              <FileText className="w-5 h-5 text-text-muted flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-text-secondary mb-1">Notes de séance</p>
                <p className="text-sm text-text-muted">{session.notes}</p>
              </div>
            </div>
          </div>
        )}

        {/* Footer */}
        <div className="flex items-center justify-end p-6 border-t border-border">
          <button
            onClick={onClose}
            className={cn(
              'h-11 px-6 rounded-xl font-medium',
              'bg-surface-elevated border border-border',
              'text-text-secondary hover:text-text-primary hover:border-text-muted',
              'transition-all duration-200'
            )}
          >
            Fermer
          </button>
        </div>
      </div>
    </div>
  )
}
