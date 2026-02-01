import { useState } from 'react'
import { useParams, Link, Navigate, useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Dumbbell,
  Calendar,
  Users,
  Zap,
  Edit3,
  Copy,
  Trash2,
  ChevronDown,
  ChevronUp,
  Clock,
  Target,
  MoreHorizontal,
  FileDown,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Badge, Avatar } from '@/components/ui'
import { useProgramsStore } from '@/store/programs-store'
import { useStudentsStore } from '@/store/students-store'
import { useAuthStore } from '@/store/auth-store'
import { formatDate, cn } from '@/lib/utils'
import { exportProgramToPDF } from '@/lib/pdf-export'
import { goalConfig } from '@/constants/goals'
import type { MuscleGroup, ExerciseMode } from '@/types'

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
  classic: 'Classique',
  rpt: 'RPT',
  pyramidal: 'Pyramidal',
  dropset: 'Dropset',
}

const dayNames = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']

export function ProgramDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { getProgramById, deleteProgram, duplicateProgram } = useProgramsStore()
  const { students } = useStudentsStore()
  const { coach } = useAuthStore()

  const [expandedDayId, setExpandedDayId] = useState<string | null>(null)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [showMenu, setShowMenu] = useState(false)

  const program = getProgramById(id!)

  if (!program) {
    return <Navigate to="/programs" replace />
  }

  const assignedStudents = students.filter(s =>
    program.assignedStudentIds.includes(s.id)
  )

  const totalExercises = program.days.reduce((acc, d) => acc + d.exercises.length, 0)
  const trainingDays = program.days.filter(d => !d.isRestDay).length

  const handleDuplicate = () => {
    setShowMenu(false)
    const newId = duplicateProgram(program.id)
    if (newId) {
      navigate(`/programs/${newId}`)
    }
  }

  const handleExportPDF = () => {
    setShowMenu(false)
    exportProgramToPDF(program, coach?.name)
  }

  const handleDelete = () => {
    deleteProgram(program.id)
    navigate('/programs')
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
                    onClick={() => {
                      setShowMenu(false)
                      // TODO: Navigate to edit mode
                    }}
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
          to="/programs"
          className={cn(
            'inline-flex items-center gap-2 text-sm mb-6',
            'text-text-secondary hover:text-accent transition-colors'
          )}
        >
          <ArrowLeft className="w-4 h-4" />
          Retour aux programmes
        </Link>

        {/* Program Header */}
        <div className={cn(
          'relative p-6 rounded-2xl mb-6 overflow-hidden',
          'bg-surface border border-border'
        )}>
          <div className="absolute top-0 right-0 w-96 h-96 bg-accent/5 rounded-full blur-[100px]" />

          <div className="relative flex items-start gap-6">
            <div className={cn(
              'w-20 h-20 rounded-2xl flex items-center justify-center',
              'bg-gradient-to-br from-accent/20 to-accent/5'
            )}>
              <Dumbbell className="w-10 h-10 text-accent" />
            </div>

            <div className="flex-1">
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-2xl font-bold text-text-primary">{program.name}</h1>
                <Badge variant={goalConfig[program.goal].color as 'success' | 'warning' | 'info'}>
                  {goalConfig[program.goal].label}
                </Badge>
              </div>
              {program.description && (
                <p className="text-text-secondary mb-4 max-w-2xl">{program.description}</p>
              )}

              <div className="flex items-center gap-6">
                {[
                  { icon: Calendar, label: 'Durée', value: `${program.durationWeeks} semaines` },
                  { icon: Target, label: 'Jours', value: `${trainingDays} entraînements` },
                  { icon: Dumbbell, label: 'Exercices', value: `${totalExercises} au total` },
                  { icon: Users, label: 'Élèves', value: `${assignedStudents.length} assignés` },
                ].map((stat) => (
                  <div key={stat.label} className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-surface-elevated flex items-center justify-center">
                      <stat.icon className="w-5 h-5 text-text-muted" />
                    </div>
                    <div>
                      <p className="text-xs text-text-muted">{stat.label}</p>
                      <p className="font-semibold text-text-primary">{stat.value}</p>
                    </div>
                  </div>
                ))}
                {program.deloadFrequency && (
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-warning/10 flex items-center justify-center">
                      <Zap className="w-5 h-5 text-warning" />
                    </div>
                    <div>
                      <p className="text-xs text-text-muted">Deload</p>
                      <p className="font-semibold text-text-primary">
                        Toutes les {program.deloadFrequency} sem
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-6">
          {/* Days List */}
          <div className="col-span-2 space-y-4">
            <h3 className="text-lg font-semibold text-text-primary mb-4">
              Programme d'entraînement
            </h3>

            {program.days.map((day, index) => (
              <div
                key={day.id}
                className={cn(
                  'rounded-2xl overflow-hidden',
                  'bg-surface border border-border',
                  'animate-[fadeIn_0.3s_ease-out]'
                )}
                style={{ animationDelay: `${index * 50}ms` }}
              >
                <button
                  onClick={() => setExpandedDayId(expandedDayId === day.id ? null : day.id)}
                  className={cn(
                    'w-full flex items-center justify-between p-5',
                    'hover:bg-surface-elevated/50 transition-colors'
                  )}
                >
                  <div className="flex items-center gap-4">
                    <div className={cn(
                      'w-12 h-12 rounded-xl flex items-center justify-center text-lg font-bold',
                      day.isRestDay
                        ? 'bg-surface-elevated text-text-muted'
                        : 'bg-accent/10 text-accent'
                    )}>
                      {index + 1}
                    </div>
                    <div className="text-left">
                      <h4 className="font-semibold text-text-primary">{day.name}</h4>
                      <p className="text-sm text-text-muted">
                        {dayNames[day.dayOfWeek]}
                        {!day.isRestDay && ` - ${day.exercises.length} exercices`}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    {day.isRestDay ? (
                      <Badge variant="default">
                        <Clock className="w-3 h-3 mr-1" />
                        Repos
                      </Badge>
                    ) : (
                      <div className="flex -space-x-1">
                        {day.exercises.slice(0, 3).map((ex) => (
                          <div
                            key={ex.id}
                            className="w-6 h-6 rounded-full bg-accent/20 border-2 border-surface flex items-center justify-center"
                            title={ex.name}
                          >
                            <span className="text-[10px] text-accent font-bold">
                              {muscleLabels[ex.muscle].charAt(0)}
                            </span>
                          </div>
                        ))}
                        {day.exercises.length > 3 && (
                          <div className="w-6 h-6 rounded-full bg-surface-elevated border-2 border-surface flex items-center justify-center">
                            <span className="text-[10px] text-text-muted">
                              +{day.exercises.length - 3}
                            </span>
                          </div>
                        )}
                      </div>
                    )}
                    {expandedDayId === day.id ? (
                      <ChevronUp className="w-5 h-5 text-text-muted" />
                    ) : (
                      <ChevronDown className="w-5 h-5 text-text-muted" />
                    )}
                  </div>
                </button>

                {expandedDayId === day.id && !day.isRestDay && (
                  <div className="border-t border-border p-5 animate-[fadeIn_0.2s_ease-out]">
                    <div className="space-y-3">
                      {day.exercises.map((exercise, exIndex) => (
                        <div
                          key={exercise.id}
                          className={cn(
                            'flex items-center justify-between p-4 rounded-xl',
                            'bg-surface-elevated'
                          )}
                        >
                          <div className="flex items-center gap-4">
                            <span className="w-6 h-6 rounded-full bg-accent/10 flex items-center justify-center text-xs font-bold text-accent">
                              {exIndex + 1}
                            </span>
                            <div>
                              <p className="font-medium text-text-primary">{exercise.name}</p>
                              <div className="flex items-center gap-2 mt-1">
                                <Badge variant="default" className="text-xs">
                                  {muscleLabels[exercise.muscle]}
                                </Badge>
                                <Badge variant="accent" className="text-xs">
                                  {modeLabels[exercise.mode]}
                                </Badge>
                              </div>
                            </div>
                          </div>
                          <div className="text-right">
                            <p className="text-sm font-semibold text-text-primary">
                              {exercise.sets.length} séries
                            </p>
                            <p className="text-xs text-text-muted">
                              {exercise.sets[0]?.targetReps || 10} reps
                            </p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Assigned Students */}
            <div className="p-5 rounded-2xl bg-surface border border-border">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-sm font-semibold text-text-secondary flex items-center gap-2">
                  <Users className="w-4 h-4 text-accent" />
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
                    Aucun élève assigné à ce programme
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
                  <span className="text-text-primary">{formatDate(program.createdAt)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-text-muted">Modifié le</span>
                  <span className="text-text-primary">{formatDate(program.updatedAt)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-text-muted">Jours de repos</span>
                  <span className="text-text-primary">
                    {program.days.filter(d => d.isRestDay).length} jour{program.days.filter(d => d.isRestDay).length > 1 ? 's' : ''}
                  </span>
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
                <h3 className="text-lg font-semibold text-text-primary">Supprimer le programme</h3>
                <p className="text-sm text-text-muted">Cette action est irréversible</p>
              </div>
            </div>
            <p className="text-text-secondary mb-6">
              Êtes-vous sûr de vouloir supprimer "{program.name}" ?
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
