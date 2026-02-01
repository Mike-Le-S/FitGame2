import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import type { Program, DietPlan, WorkoutDay, Exercise, MealPlan, SupplementEntry } from '@/types'

// Mock jsPDF
const mockText = vi.fn()
const mockSetFontSize = vi.fn()
const mockSetFont = vi.fn()
const mockSetTextColor = vi.fn()
const mockSetFillColor = vi.fn()
const mockSetDrawColor = vi.fn()
const mockRect = vi.fn()
const mockRoundedRect = vi.fn()
const mockLine = vi.fn()
const mockSave = vi.fn()
const mockAddPage = vi.fn()
const mockSplitTextToSize = vi.fn((text: string) => [text])

const mockJsPDF = vi.fn().mockImplementation(() => ({
  text: mockText,
  setFontSize: mockSetFontSize,
  setFont: mockSetFont,
  setTextColor: mockSetTextColor,
  setFillColor: mockSetFillColor,
  setDrawColor: mockSetDrawColor,
  rect: mockRect,
  roundedRect: mockRoundedRect,
  line: mockLine,
  save: mockSave,
  addPage: mockAddPage,
  splitTextToSize: mockSplitTextToSize,
  internal: {
    pageSize: {
      getWidth: () => 210,
      getHeight: () => 297,
    },
    pages: [null, {}], // First page is null, second is the actual page
  },
}))

vi.mock('jspdf', () => ({
  jsPDF: mockJsPDF,
}))

// Helper to create test program
const createTestProgram = (overrides: Partial<Program> = {}): Program => ({
  id: 'prog-1',
  name: 'Programme Force 8 Semaines',
  description: 'Un programme de force progressive pour débutants intermédiaires.',
  goal: 'strength',
  durationWeeks: 8,
  deloadFrequency: 4,
  days: [
    createTestDay({
      id: 'day-1',
      name: 'Jour 1 - Push',
      dayOfWeek: 1,
      isRestDay: false,
      exercises: [
        createTestExercise({
          id: 'ex-1',
          name: 'Développé couché',
          muscle: 'chest',
          mode: 'classic',
          sets: [
            { id: 's1', targetReps: 8, targetWeight: 80, isWarmup: false, restSeconds: 180 },
            { id: 's2', targetReps: 8, targetWeight: 80, isWarmup: false, restSeconds: 180 },
            { id: 's3', targetReps: 8, targetWeight: 80, isWarmup: false, restSeconds: 180 },
          ],
        }),
        createTestExercise({
          id: 'ex-2',
          name: 'Développé incliné haltères',
          muscle: 'chest',
          mode: 'rpt',
          notes: 'Pause 2s en bas',
          sets: [
            { id: 's4', targetReps: 10, targetWeight: 30, isWarmup: false, restSeconds: 120 },
            { id: 's5', targetReps: 10, targetWeight: 30, isWarmup: false, restSeconds: 120 },
          ],
        }),
      ],
    }),
    createTestDay({
      id: 'day-2',
      name: 'Jour 2 - Repos',
      dayOfWeek: 2,
      isRestDay: true,
      exercises: [],
    }),
  ],
  createdAt: '2024-01-15T10:00:00Z',
  updatedAt: '2024-01-20T15:30:00Z',
  assignedStudentIds: ['student-1', 'student-2'],
  ...overrides,
})

const createTestDay = (overrides: Partial<WorkoutDay> = {}): WorkoutDay => ({
  id: 'day-1',
  name: 'Jour Test',
  dayOfWeek: 1,
  isRestDay: false,
  exercises: [],
  ...overrides,
})

const createTestExercise = (overrides: Partial<Exercise> = {}): Exercise => ({
  id: 'ex-1',
  name: 'Test Exercise',
  muscle: 'chest',
  mode: 'classic',
  sets: [
    { id: 's1', targetReps: 10, targetWeight: 50, isWarmup: false, restSeconds: 90 },
  ],
  ...overrides,
})

// Helper to create test diet plan
const createTestDietPlan = (overrides: Partial<DietPlan> = {}): DietPlan => ({
  id: 'diet-1',
  name: 'Plan Prise de Masse',
  goal: 'bulk',
  trainingCalories: 3000,
  restCalories: 2500,
  trainingMacros: { protein: 200, carbs: 350, fat: 80 },
  restMacros: { protein: 200, carbs: 250, fat: 85 },
  meals: [
    createTestMeal({
      id: 'meal-1',
      name: 'Petit-déjeuner',
      targetTime: '07:30',
      foods: [
        { id: 'food-1', name: 'Flocons d\'avoine', calories: 350, macros: { protein: 12, carbs: 60, fat: 7 }, quantity: 100, unit: 'g' },
        { id: 'food-2', name: 'Banane', calories: 105, macros: { protein: 1, carbs: 27, fat: 0 }, quantity: 1, unit: 'unité' },
      ],
    }),
    createTestMeal({
      id: 'meal-2',
      name: 'Déjeuner',
      targetTime: '12:30',
      foods: [
        { id: 'food-3', name: 'Poulet grillé', calories: 300, macros: { protein: 50, carbs: 0, fat: 10 }, quantity: 200, unit: 'g' },
        { id: 'food-4', name: 'Riz complet', calories: 220, macros: { protein: 5, carbs: 45, fat: 2 }, quantity: 150, unit: 'g' },
      ],
    }),
  ],
  supplements: [
    { id: 'supp-1', name: 'Whey Protein', dosage: '30g', timing: 'post-workout' },
    { id: 'supp-2', name: 'Créatine', dosage: '5g', timing: 'morning' },
  ],
  notes: 'Boire au moins 3L d\'eau par jour.',
  createdAt: '2024-01-10T08:00:00Z',
  updatedAt: '2024-01-18T14:00:00Z',
  assignedStudentIds: ['student-1'],
  ...overrides,
})

const createTestMeal = (overrides: Partial<MealPlan> = {}): MealPlan => ({
  id: 'meal-1',
  name: 'Test Meal',
  foods: [],
  ...overrides,
})

describe('exportProgramToPDF', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2024-06-15T12:00:00'))
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('creates a new jsPDF instance', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram()

    exportProgramToPDF(program)

    expect(mockJsPDF).toHaveBeenCalled()
  })

  it('saves PDF with sanitized filename', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({ name: 'Mon Programme Test' })

    exportProgramToPDF(program)

    expect(mockSave).toHaveBeenCalledWith('Mon_Programme_Test_programme.pdf')
  })

  it('sanitizes special characters in filename', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({ name: 'Programme/Test:2024' })

    exportProgramToPDF(program)

    // The regex [^a-zA-Z0-9] replaces non-alphanumeric chars with '_'
    expect(mockSave).toHaveBeenCalledWith('Programme_Test_2024_programme.pdf')
  })

  it('renders program header with FitGame branding', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram()

    exportProgramToPDF(program)

    // Check accent color is set for header
    expect(mockSetFillColor).toHaveBeenCalledWith(255, 107, 53)
    // Check FitGame text is rendered
    expect(mockText).toHaveBeenCalledWith('FitGame', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith("Programme d'entraînement", expect.any(Number), expect.any(Number))
  })

  it('renders program name as title', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({ name: 'Super Programme' })

    exportProgramToPDF(program)

    expect(mockText).toHaveBeenCalledWith('Super Programme', expect.any(Number), expect.any(Number))
  })

  it('renders program metadata (goal, duration, days)', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({
      goal: 'bulk',
      durationWeeks: 12,
      days: [
        createTestDay({ isRestDay: false }),
        createTestDay({ isRestDay: false }),
        createTestDay({ isRestDay: true }),
      ],
    })

    exportProgramToPDF(program)

    // Metadata should be rendered (exact format depends on implementation)
    const textCalls = mockText.mock.calls.map(call => call[0])
    const metadataCall = textCalls.find(text =>
      typeof text === 'string' && text.includes('Objectif')
    )
    expect(metadataCall).toBeDefined()
  })

  it('renders coach name when provided', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram()

    exportProgramToPDF(program, 'Coach Martin')

    expect(mockText).toHaveBeenCalledWith(
      'Créé par: Coach Martin',
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('does not render coach name when not provided', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram()

    exportProgramToPDF(program)

    const textCalls = mockText.mock.calls.map(call => call[0])
    const coachCall = textCalls.find(text =>
      typeof text === 'string' && text.includes('Créé par')
    )
    expect(coachCall).toBeUndefined()
  })

  it('renders program description when present', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({
      description: 'Une description détaillée du programme.',
    })

    exportProgramToPDF(program)

    expect(mockSplitTextToSize).toHaveBeenCalledWith(
      'Une description détaillée du programme.',
      expect.any(Number)
    )
  })

  it('renders day headers', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({
      days: [
        createTestDay({ name: 'Jour A - Upper' }),
        createTestDay({ name: 'Jour B - Lower' }),
      ],
    })

    exportProgramToPDF(program)

    expect(mockText).toHaveBeenCalledWith('Jour A - Upper', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith('Jour B - Lower', expect.any(Number), expect.any(Number))
  })

  it('renders rest day indicator', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({
      days: [
        createTestDay({ name: 'Dimanche', isRestDay: true }),
      ],
    })

    exportProgramToPDF(program)

    expect(mockText).toHaveBeenCalledWith('Jour de repos', expect.any(Number), expect.any(Number))
  })

  it('renders exercises with muscle groups translated to French', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({
      days: [
        createTestDay({
          isRestDay: false,
          exercises: [
            createTestExercise({ name: 'Bench Press', muscle: 'chest' }),
            createTestExercise({ name: 'Squat', muscle: 'quads' }),
            createTestExercise({ name: 'Deadlift', muscle: 'back' }),
          ],
        }),
      ],
    })

    exportProgramToPDF(program)

    expect(mockText).toHaveBeenCalledWith('Pectoraux', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith('Quadriceps', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith('Dos', expect.any(Number), expect.any(Number))
  })

  it('renders exercise modes translated to French', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({
      days: [
        createTestDay({
          isRestDay: false,
          exercises: [
            createTestExercise({ mode: 'classic' }),
            createTestExercise({ mode: 'rpt' }),
            createTestExercise({ mode: 'dropset' }),
          ],
        }),
      ],
    })

    exportProgramToPDF(program)

    expect(mockText).toHaveBeenCalledWith('Classique', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith('RPT', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith('Dropset', expect.any(Number), expect.any(Number))
  })

  it('renders sets information', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({
      days: [
        createTestDay({
          isRestDay: false,
          exercises: [
            createTestExercise({
              sets: [
                { id: 's1', targetReps: 8, targetWeight: 100, isWarmup: false, restSeconds: 180 },
                { id: 's2', targetReps: 8, targetWeight: 100, isWarmup: false, restSeconds: 180 },
                { id: 's3', targetReps: 8, targetWeight: 100, isWarmup: false, restSeconds: 180 },
              ],
            }),
          ],
        }),
      ],
    })

    exportProgramToPDF(program)

    // Should render "3 x 8 @ 100kg" format
    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/3 × 8 @ 100kg/),
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('excludes warmup sets from working sets count', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({
      days: [
        createTestDay({
          isRestDay: false,
          exercises: [
            createTestExercise({
              sets: [
                { id: 's0', targetReps: 10, targetWeight: 40, isWarmup: true, restSeconds: 60 },
                { id: 's1', targetReps: 8, targetWeight: 80, isWarmup: false, restSeconds: 180 },
                { id: 's2', targetReps: 8, targetWeight: 80, isWarmup: false, restSeconds: 180 },
              ],
            }),
          ],
        }),
      ],
    })

    exportProgramToPDF(program)

    // Should only count 2 working sets, not 3
    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/2 × 8 @ 80kg/),
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('renders exercise notes when present', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({
      days: [
        createTestDay({
          isRestDay: false,
          exercises: [
            createTestExercise({
              notes: 'Tempo 3-1-1',
            }),
          ],
        }),
      ],
    })

    exportProgramToPDF(program)

    expect(mockSplitTextToSize).toHaveBeenCalledWith(
      'Note: Tempo 3-1-1',
      expect.any(Number)
    )
  })

  it('renders deload frequency when present', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({ deloadFrequency: 4 })

    exportProgramToPDF(program)

    const textCalls = mockText.mock.calls.map(call => call[0])
    const deloadCall = textCalls.find(text =>
      typeof text === 'string' && text.includes('Deload')
    )
    expect(deloadCall).toBeDefined()
  })

  it('renders footer with current date', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram()

    exportProgramToPDF(program)

    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/Généré le.*juin.*2024.*FitGame Coach/),
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('truncates long exercise names', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({
      days: [
        createTestDay({
          isRestDay: false,
          exercises: [
            createTestExercise({
              name: 'Very Long Exercise Name That Should Be Truncated For Display',
            }),
          ],
        }),
      ],
    })

    exportProgramToPDF(program)

    // Name should be truncated to 25 chars + "..."
    expect(mockText).toHaveBeenCalledWith(
      'Very Long Exercise Name T...',
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('handles program with no exercises', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({
      days: [
        createTestDay({ isRestDay: false, exercises: [] }),
      ],
    })

    expect(() => exportProgramToPDF(program)).not.toThrow()
    expect(mockSave).toHaveBeenCalled()
  })

  it('handles program with no description', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const program = createTestProgram({ description: undefined })

    expect(() => exportProgramToPDF(program)).not.toThrow()
    expect(mockSave).toHaveBeenCalled()
  })

  it('renders all goal types correctly', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const goals = ['bulk', 'cut', 'maintain', 'strength', 'endurance', 'recomp', 'other'] as const

    for (const goal of goals) {
      vi.clearAllMocks()
      const program = createTestProgram({ goal })
      exportProgramToPDF(program)
      expect(mockSave).toHaveBeenCalled()
    }
  })

  it('renders all muscle groups correctly', async () => {
    const { exportProgramToPDF } = await import('@/lib/pdf-export')
    const muscles = ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms',
      'quads', 'hamstrings', 'glutes', 'calves', 'abs', 'cardio'] as const

    const program = createTestProgram({
      days: [
        createTestDay({
          isRestDay: false,
          exercises: muscles.map((muscle, i) =>
            createTestExercise({ id: `ex-${i}`, muscle })
          ),
        }),
      ],
    })

    exportProgramToPDF(program)
    expect(mockSave).toHaveBeenCalled()
  })
})

describe('exportDietPlanToPDF', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2024-06-15T12:00:00'))
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('creates a new jsPDF instance', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan()

    exportDietPlanToPDF(dietPlan)

    expect(mockJsPDF).toHaveBeenCalled()
  })

  it('saves PDF with sanitized filename', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({ name: 'Plan Nutrition 2024' })

    exportDietPlanToPDF(dietPlan)

    expect(mockSave).toHaveBeenCalledWith('Plan_Nutrition_2024_nutrition.pdf')
  })

  it('renders header with green success color', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan()

    exportDietPlanToPDF(dietPlan)

    // Check success color (green) is set for header
    expect(mockSetFillColor).toHaveBeenCalledWith(34, 197, 94)
    expect(mockText).toHaveBeenCalledWith('Plan nutritionnel', expect.any(Number), expect.any(Number))
  })

  it('renders diet plan name', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({ name: 'Plan Sèche' })

    exportDietPlanToPDF(dietPlan)

    expect(mockText).toHaveBeenCalledWith('Plan Sèche', expect.any(Number), expect.any(Number))
  })

  it('renders goal translated to French', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({ goal: 'cut' })

    exportDietPlanToPDF(dietPlan)

    expect(mockText).toHaveBeenCalledWith(
      'Objectif: Sèche',
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('renders coach name when provided', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan()

    exportDietPlanToPDF(dietPlan, 'Nutritionniste Sophie')

    expect(mockText).toHaveBeenCalledWith(
      'Créé par: Nutritionniste Sophie',
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('renders training day macros box', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({
      trainingCalories: 2800,
      trainingMacros: { protein: 180, carbs: 300, fat: 75 },
    })

    exportDietPlanToPDF(dietPlan)

    expect(mockText).toHaveBeenCalledWith("JOUR D'ENTRAÎNEMENT", expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith('2800 kcal', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith(
      'P: 180g  C: 300g  F: 75g',
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('renders rest day macros box', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({
      restCalories: 2200,
      restMacros: { protein: 180, carbs: 200, fat: 80 },
    })

    exportDietPlanToPDF(dietPlan)

    expect(mockText).toHaveBeenCalledWith('JOUR DE REPOS', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith('2200 kcal', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith(
      'P: 180g  C: 200g  F: 80g',
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('renders meal names and times', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({
      meals: [
        createTestMeal({ name: 'Petit-déjeuner', targetTime: '07:00' }),
        createTestMeal({ name: 'Collation', targetTime: '10:00' }),
      ],
    })

    exportDietPlanToPDF(dietPlan)

    expect(mockText).toHaveBeenCalledWith('Petit-déjeuner', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith('07:00', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith('Collation', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith('10:00', expect.any(Number), expect.any(Number))
  })

  it('renders foods with nutritional info', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({
      meals: [
        createTestMeal({
          foods: [
            {
              id: 'f1',
              name: 'Oeufs',
              calories: 180,
              macros: { protein: 12, carbs: 1, fat: 14 },
              quantity: 3,
              unit: 'unités',
            },
          ],
        }),
      ],
    })

    exportDietPlanToPDF(dietPlan)

    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/• Oeufs/),
      expect.any(Number),
      expect.any(Number)
    )
    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/3unités.*180kcal.*P:12g C:1g F:14g/),
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('renders supplements with timing', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({
      supplements: [
        { id: 's1', name: 'Vitamine D', dosage: '2000 UI', timing: 'morning' },
        { id: 's2', name: 'BCAA', dosage: '10g', timing: 'pre-workout' },
        { id: 's3', name: 'Magnésium', dosage: '400mg', timing: 'evening' },
      ],
    })

    exportDietPlanToPDF(dietPlan)

    expect(mockText).toHaveBeenCalledWith('Suppléments', expect.any(Number), expect.any(Number))
    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/• Vitamine D/),
      expect.any(Number),
      expect.any(Number)
    )
    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/2000 UI.*Matin/),
      expect.any(Number),
      expect.any(Number)
    )
    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/10g.*Pré-entraînement/),
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('renders all supplement timing types', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const timings: Array<SupplementEntry['timing']> = [
      'morning', 'pre-workout', 'post-workout', 'evening', 'with-meal'
    ]

    const dietPlan = createTestDietPlan({
      supplements: timings.map((timing, i) => ({
        id: `s${i}`,
        name: `Supplement ${i}`,
        dosage: '10g',
        timing,
      })),
    })

    exportDietPlanToPDF(dietPlan)

    // Check each timing label appears
    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/Matin/),
      expect.any(Number),
      expect.any(Number)
    )
    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/Pré-entraînement/),
      expect.any(Number),
      expect.any(Number)
    )
    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/Post-entraînement/),
      expect.any(Number),
      expect.any(Number)
    )
    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/Soir/),
      expect.any(Number),
      expect.any(Number)
    )
    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/Avec repas/),
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('renders notes when present', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({
      notes: 'Éviter les produits laitiers si intolérance.',
    })

    exportDietPlanToPDF(dietPlan)

    expect(mockText).toHaveBeenCalledWith('Notes', expect.any(Number), expect.any(Number))
    expect(mockSplitTextToSize).toHaveBeenCalledWith(
      'Éviter les produits laitiers si intolérance.',
      expect.any(Number)
    )
  })

  it('handles diet plan with no meals', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({ meals: [] })

    expect(() => exportDietPlanToPDF(dietPlan)).not.toThrow()
    expect(mockSave).toHaveBeenCalled()
  })

  it('handles diet plan with no supplements', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({ supplements: [] })

    expect(() => exportDietPlanToPDF(dietPlan)).not.toThrow()
    expect(mockSave).toHaveBeenCalled()
  })

  it('handles diet plan with no notes', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({ notes: undefined })

    expect(() => exportDietPlanToPDF(dietPlan)).not.toThrow()
    expect(mockSave).toHaveBeenCalled()
  })

  it('renders footer with current date', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan()

    exportDietPlanToPDF(dietPlan)

    expect(mockText).toHaveBeenCalledWith(
      expect.stringMatching(/Généré le.*juin.*2024.*FitGame Coach/),
      expect.any(Number),
      expect.any(Number)
    )
  })

  it('renders all goal types correctly', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const goals = ['bulk', 'cut', 'maintain', 'strength', 'endurance', 'recomp', 'other'] as const

    for (const goal of goals) {
      vi.clearAllMocks()
      const dietPlan = createTestDietPlan({ goal })
      exportDietPlanToPDF(dietPlan)
      expect(mockSave).toHaveBeenCalled()
    }
  })

  it('handles meal without target time', async () => {
    const { exportDietPlanToPDF } = await import('@/lib/pdf-export')
    const dietPlan = createTestDietPlan({
      meals: [
        createTestMeal({ name: 'Snack', targetTime: undefined }),
      ],
    })

    expect(() => exportDietPlanToPDF(dietPlan)).not.toThrow()
    expect(mockSave).toHaveBeenCalled()
  })
})
