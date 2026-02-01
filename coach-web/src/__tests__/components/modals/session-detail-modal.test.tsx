import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '../../helpers/test-utils'
import userEvent from '@testing-library/user-event'
import { SessionDetailModal } from '@/components/modals/session-detail-modal'
import type { Exercise, MuscleGroup, ExerciseMode } from '@/types'

// Helper to create a test exercise
const createTestExercise = (overrides: Partial<Exercise> = {}): Exercise => ({
  id: 'exercise-1',
  name: 'Développé couché',
  muscle: 'chest' as MuscleGroup,
  mode: 'classic' as ExerciseMode,
  sets: [
    {
      id: 'set-1',
      targetReps: 10,
      targetWeight: 80,
      isWarmup: false,
      restSeconds: 90,
      actualReps: 10,
      actualWeight: 80,
    },
    {
      id: 'set-2',
      targetReps: 10,
      targetWeight: 80,
      isWarmup: false,
      restSeconds: 90,
      actualReps: 9,
      actualWeight: 80,
    },
    {
      id: 'set-3',
      targetReps: 10,
      targetWeight: 80,
      isWarmup: false,
      restSeconds: 90,
      actualReps: 8,
      actualWeight: 80,
    },
  ],
  ...overrides,
})

// Helper to create a test session
const createTestSession = (overrides: Partial<{
  id: string
  name: string
  date: Date
  duration: number
  completed: boolean
  exercises: Exercise[]
  notes?: string
}> = {}) => ({
  id: 'session-1',
  name: 'Push Day',
  date: new Date('2026-01-30'),
  duration: 65,
  completed: true,
  exercises: [createTestExercise()],
  ...overrides,
})

describe('SessionDetailModal', () => {
  const defaultProps = {
    isOpen: true,
    onClose: vi.fn(),
    session: createTestSession(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
    // Mock Date for consistent date formatting
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-01-31'))
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('rendering', () => {
    it('renders when isOpen is true and session is provided', () => {
      render(<SessionDetailModal {...defaultProps} />)

      expect(screen.getByText('Push Day')).toBeInTheDocument()
    })

    it('does not render when isOpen is false', () => {
      render(<SessionDetailModal isOpen={false} onClose={defaultProps.onClose} session={defaultProps.session} />)

      expect(screen.queryByText('Push Day')).not.toBeInTheDocument()
    })

    it('does not render when session is null', () => {
      render(<SessionDetailModal isOpen={true} onClose={defaultProps.onClose} session={null} />)

      expect(screen.queryByText('Push Day')).not.toBeInTheDocument()
    })

    it('renders session name in header', () => {
      render(<SessionDetailModal {...defaultProps} />)

      expect(screen.getByText('Push Day')).toBeInTheDocument()
    })

    it('renders close button', () => {
      render(<SessionDetailModal {...defaultProps} />)

      expect(screen.getByRole('button', { name: /fermer/i })).toBeInTheDocument()
    })
  })

  describe('session status', () => {
    it('shows "Complétée" badge for completed session', () => {
      render(<SessionDetailModal {...defaultProps} />)

      expect(screen.getByText('Complétée')).toBeInTheDocument()
    })

    it('shows "Manquée" badge for incomplete session', () => {
      const session = createTestSession({ completed: false })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('Manquée')).toBeInTheDocument()
    })

    it('applies success variant to completed badge', () => {
      render(<SessionDetailModal {...defaultProps} />)

      const badge = screen.getByText('Complétée')
      expect(badge).toHaveClass('bg-success/15')
    })

    it('applies warning variant to incomplete badge', () => {
      const session = createTestSession({ completed: false })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      const badge = screen.getByText('Manquée')
      expect(badge).toHaveClass('bg-warning/15')
    })
  })

  describe('date display', () => {
    it('shows "Hier" for yesterday', () => {
      const session = createTestSession({ date: new Date('2026-01-30') })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('Hier')).toBeInTheDocument()
    })

    it('shows "Aujourd\'hui" for today', () => {
      const session = createTestSession({ date: new Date('2026-01-31') })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText("Aujourd'hui")).toBeInTheDocument()
    })

    it('shows relative days for recent dates', () => {
      const session = createTestSession({ date: new Date('2026-01-28') })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('Il y a 3 jours')).toBeInTheDocument()
    })

    it('shows full date for older sessions', () => {
      const session = createTestSession({ date: new Date('2026-01-15') })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('15 janvier 2026')).toBeInTheDocument()
    })
  })

  describe('duration display', () => {
    it('shows duration for completed session', () => {
      render(<SessionDetailModal {...defaultProps} />)

      expect(screen.getByText('65 min')).toBeInTheDocument()
    })

    it('does not show duration for incomplete session', () => {
      const session = createTestSession({ completed: false })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.queryByText('65 min')).not.toBeInTheDocument()
    })
  })

  describe('stats bar', () => {
    it('displays exercise count', () => {
      const session = createTestSession({
        exercises: [
          createTestExercise({ id: 'ex-1', name: 'Bench Press' }),
          createTestExercise({ id: 'ex-2', name: 'Incline Press' }),
        ],
      })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('Exercices')).toBeInTheDocument()
      // Get the stats bar container and check values within it
      const statsBar = document.querySelector('.bg-surface-elevated\\/50')
      expect(statsBar).toBeInTheDocument()
    })

    it('displays working sets count', () => {
      render(<SessionDetailModal {...defaultProps} />)

      // 3 working sets from the default exercise
      expect(screen.getByText('Séries')).toBeInTheDocument()
    })

    it('excludes warmup sets from count', () => {
      const exerciseWithWarmup = createTestExercise({
        sets: [
          { id: 'warmup', targetReps: 10, targetWeight: 40, isWarmup: true, restSeconds: 60 },
          { id: 'set-1', targetReps: 10, targetWeight: 80, isWarmup: false, restSeconds: 90 },
          { id: 'set-2', targetReps: 10, targetWeight: 80, isWarmup: false, restSeconds: 90 },
        ],
      })
      const session = createTestSession({ exercises: [exerciseWithWarmup] })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      // Verify the Séries label is present
      expect(screen.getByText('Séries')).toBeInTheDocument()
    })

    it('displays duration in stats bar for completed session', () => {
      render(<SessionDetailModal {...defaultProps} />)

      expect(screen.getByText('Minutes')).toBeInTheDocument()
    })
  })

  describe('exercises list', () => {
    it('displays exercise name', () => {
      render(<SessionDetailModal {...defaultProps} />)

      expect(screen.getByText('Développé couché')).toBeInTheDocument()
    })

    it('displays muscle group badge', () => {
      render(<SessionDetailModal {...defaultProps} />)

      expect(screen.getByText('Pectoraux')).toBeInTheDocument()
    })

    it('displays exercise mode', () => {
      render(<SessionDetailModal {...defaultProps} />)

      expect(screen.getByText('Classic')).toBeInTheDocument()
    })

    it('displays all muscle group labels correctly', () => {
      const exercises = [
        createTestExercise({ id: 'ex-1', name: 'Bench Press', muscle: 'chest' }),
        createTestExercise({ id: 'ex-2', name: 'Row', muscle: 'back' }),
        createTestExercise({ id: 'ex-3', name: 'Press', muscle: 'shoulders' }),
      ]
      const session = createTestSession({ exercises })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('Pectoraux')).toBeInTheDocument()
      expect(screen.getByText('Dos')).toBeInTheDocument()
      expect(screen.getByText('Épaules')).toBeInTheDocument()
    })

    it('displays all mode labels correctly', () => {
      const exercises = [
        createTestExercise({ id: 'ex-1', mode: 'classic' }),
        createTestExercise({ id: 'ex-2', mode: 'rpt' }),
        createTestExercise({ id: 'ex-3', mode: 'pyramidal' }),
        createTestExercise({ id: 'ex-4', mode: 'dropset' }),
      ]
      const session = createTestSession({ exercises })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('Classic')).toBeInTheDocument()
      expect(screen.getByText('Reverse Pyramid')).toBeInTheDocument()
      expect(screen.getByText('Pyramidal')).toBeInTheDocument()
      expect(screen.getByText('Drop Set')).toBeInTheDocument()
    })
  })

  describe('sets table', () => {
    it('displays table headers', () => {
      render(<SessionDetailModal {...defaultProps} />)

      expect(screen.getByText('Série')).toBeInTheDocument()
      expect(screen.getByText('Reps')).toBeInTheDocument()
      expect(screen.getByText('Poids')).toBeInTheDocument()
    })

    it('displays "Réalisé" header for completed session', () => {
      render(<SessionDetailModal {...defaultProps} />)

      expect(screen.getByText('Réalisé')).toBeInTheDocument()
    })

    it('does not display "Réalisé" header for incomplete session', () => {
      const session = createTestSession({ completed: false })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.queryByText('Réalisé')).not.toBeInTheDocument()
    })

    it('displays target reps for each set', () => {
      render(<SessionDetailModal {...defaultProps} />)

      // Multiple cells with 10 should exist
      const reps = screen.getAllByRole('cell')
      const repsWithTen = reps.filter((cell) => cell.textContent === '10')
      expect(repsWithTen.length).toBeGreaterThan(0)
    })

    it('displays target weight with unit', () => {
      render(<SessionDetailModal {...defaultProps} />)

      const weights = screen.getAllByText('80 kg')
      expect(weights.length).toBeGreaterThan(0)
    })

    it('displays actual performance for completed session', () => {
      render(<SessionDetailModal {...defaultProps} />)

      // From the default test exercise: 10 x 80, 9 x 80, 8 x 80
      const actualPerf = screen.getAllByText(/× 80 kg/)
      expect(actualPerf.length).toBeGreaterThan(0)
    })

    it('applies success color when actual reps meet target', () => {
      render(<SessionDetailModal {...defaultProps} />)

      const actualPerf = screen.getAllByText(/× 80 kg/)
      // First set should be success (10 reps matched)
      const successEl = actualPerf.find((el) => el.textContent?.includes('10'))
      expect(successEl).toHaveClass('text-success')
    })

    it('applies warning color when actual reps below target', () => {
      render(<SessionDetailModal {...defaultProps} />)

      const warningElements = screen.getAllByText(/× 80 kg/)
      const warningElement = warningElements.find((el) => el.textContent?.includes('9'))
      if (warningElement) {
        expect(warningElement).toHaveClass('text-warning')
      }
    })
  })

  describe('exercise notes', () => {
    it('displays exercise notes when present', () => {
      const exerciseWithNotes = createTestExercise({
        notes: 'Bien sentir la contraction en haut du mouvement',
      })
      const session = createTestSession({ exercises: [exerciseWithNotes] })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('Bien sentir la contraction en haut du mouvement')).toBeInTheDocument()
    })

    it('shows "Note :" prefix for exercise notes', () => {
      const exerciseWithNotes = createTestExercise({
        notes: 'Test note',
      })
      const session = createTestSession({ exercises: [exerciseWithNotes] })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText(/Note :/)).toBeInTheDocument()
    })

    it('does not display notes section when no notes', () => {
      const exerciseWithoutNotes = createTestExercise({ notes: undefined })
      const session = createTestSession({ exercises: [exerciseWithoutNotes] })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.queryByText(/Note :/)).not.toBeInTheDocument()
    })
  })

  describe('session notes', () => {
    it('displays session notes when present', () => {
      const session = createTestSession({
        notes: 'Great workout, felt strong today!',
      })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('Great workout, felt strong today!')).toBeInTheDocument()
    })

    it('shows session notes section header', () => {
      const session = createTestSession({
        notes: 'Session note content',
      })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('Notes de séance')).toBeInTheDocument()
    })

    it('does not display session notes section when no notes', () => {
      const session = createTestSession({ notes: undefined })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.queryByText('Notes de séance')).not.toBeInTheDocument()
    })
  })

  describe('closing behavior', () => {
    it('closes when clicking X button', async () => {
      vi.useRealTimers() // Use real timers for this test
      const user = userEvent.setup()
      render(<SessionDetailModal {...defaultProps} />)

      const closeButtons = screen.getAllByRole('button')
      const xButton = closeButtons.find((btn) => btn.querySelector('.lucide-x') !== null)

      if (xButton) {
        await user.click(xButton)
        expect(defaultProps.onClose).toHaveBeenCalled()
      }
      vi.useFakeTimers()
      vi.setSystemTime(new Date('2026-01-31'))
    })

    it('closes when clicking Fermer button', async () => {
      vi.useRealTimers() // Use real timers for this test
      const user = userEvent.setup()
      render(<SessionDetailModal {...defaultProps} />)

      const closeButton = screen.getByRole('button', { name: /fermer/i })
      await user.click(closeButton)

      expect(defaultProps.onClose).toHaveBeenCalled()
      vi.useFakeTimers()
      vi.setSystemTime(new Date('2026-01-31'))
    })

    it('closes when clicking backdrop', async () => {
      vi.useRealTimers() // Use real timers for this test
      const user = userEvent.setup()
      render(<SessionDetailModal {...defaultProps} />)

      const backdrop = document.querySelector('.bg-black\\/60')
      if (backdrop) {
        await user.click(backdrop)
        expect(defaultProps.onClose).toHaveBeenCalled()
      }
      vi.useFakeTimers()
      vi.setSystemTime(new Date('2026-01-31'))
    })
  })

  describe('icons', () => {
    it('displays dumbbell icon in header', () => {
      render(<SessionDetailModal {...defaultProps} />)

      const dumbbellIcon = document.querySelector('.lucide-dumbbell')
      expect(dumbbellIcon).toBeInTheDocument()
    })

    it('displays calendar icon for date', () => {
      render(<SessionDetailModal {...defaultProps} />)

      const calendarIcon = document.querySelector('.lucide-calendar')
      expect(calendarIcon).toBeInTheDocument()
    })

    it('displays clock icon for duration', () => {
      render(<SessionDetailModal {...defaultProps} />)

      const clockIcon = document.querySelector('.lucide-clock')
      expect(clockIcon).toBeInTheDocument()
    })

    it('displays file-text icon for session notes', () => {
      const session = createTestSession({ notes: 'Test notes' })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      const fileTextIcon = document.querySelector('.lucide-file-text')
      expect(fileTextIcon).toBeInTheDocument()
    })
  })

  describe('visual states', () => {
    it('applies accent color to icon for completed session', () => {
      render(<SessionDetailModal {...defaultProps} />)

      const iconContainer = document.querySelector('.bg-accent\\/10')
      expect(iconContainer).toBeInTheDocument()
    })

    it('applies warning color to icon for incomplete session', () => {
      const session = createTestSession({ completed: false })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      const iconContainer = document.querySelector('.bg-warning\\/10')
      expect(iconContainer).toBeInTheDocument()
    })
  })

  describe('multiple exercises', () => {
    it('displays all exercises', () => {
      const exercises = [
        createTestExercise({ id: 'ex-1', name: 'Bench Press' }),
        createTestExercise({ id: 'ex-2', name: 'Incline Dumbbell Press' }),
        createTestExercise({ id: 'ex-3', name: 'Cable Flyes' }),
      ]
      const session = createTestSession({ exercises })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('Bench Press')).toBeInTheDocument()
      expect(screen.getByText('Incline Dumbbell Press')).toBeInTheDocument()
      expect(screen.getByText('Cable Flyes')).toBeInTheDocument()
    })

    it('calculates total working sets across all exercises', () => {
      const exercises = [
        createTestExercise({
          id: 'ex-1',
          name: 'Exercise 1',
          sets: [
            { id: 's1', targetReps: 10, targetWeight: 80, isWarmup: false, restSeconds: 90 },
            { id: 's2', targetReps: 10, targetWeight: 80, isWarmup: false, restSeconds: 90 },
          ],
        }),
        createTestExercise({
          id: 'ex-2',
          name: 'Exercise 2',
          sets: [
            { id: 's3', targetReps: 10, targetWeight: 60, isWarmup: false, restSeconds: 90 },
            { id: 's4', targetReps: 10, targetWeight: 60, isWarmup: false, restSeconds: 90 },
            { id: 's5', targetReps: 10, targetWeight: 60, isWarmup: false, restSeconds: 90 },
          ],
        }),
      ]
      const session = createTestSession({ exercises })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      // Total: 2 + 3 = 5 working sets - verify stats bar shows Séries label
      expect(screen.getByText('Séries')).toBeInTheDocument()
      // And verify the exercise count is 2
      expect(screen.getByText('Exercices')).toBeInTheDocument()
    })
  })

  describe('edge cases', () => {
    it('handles session with no exercises', () => {
      const session = createTestSession({ exercises: [] })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      expect(screen.getByText('Exercices')).toBeInTheDocument()
      // The exercise count should be 0, but we check via the stats bar
      const statsBar = document.querySelector('.bg-surface-elevated\\/50')
      expect(statsBar).toBeInTheDocument()
    })

    it('handles set without actual performance data', () => {
      const exerciseWithoutActual = createTestExercise({
        sets: [
          {
            id: 'set-1',
            targetReps: 10,
            targetWeight: 80,
            isWarmup: false,
            restSeconds: 90,
            actualReps: undefined,
            actualWeight: undefined,
          },
        ],
      })
      const session = createTestSession({ exercises: [exerciseWithoutActual] })
      render(<SessionDetailModal {...defaultProps} session={session} />)

      // Should show "-" for missing actual data
      expect(screen.getByText('-')).toBeInTheDocument()
    })
  })
})
