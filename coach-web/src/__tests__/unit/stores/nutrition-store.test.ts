import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import {
  useNutritionStore,
  foodCatalog,
  supplementCatalog,
  createMealPlan,
  calculateMealMacros,
} from '@/store/nutrition-store'
import { useAuthStore } from '@/store/auth-store'

// Mock the supabase module
const mockFrom = vi.fn()

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: vi.fn().mockResolvedValue({ data: { session: null }, error: null }),
      signInWithPassword: vi.fn(),
      signUp: vi.fn(),
      signOut: vi.fn(),
      onAuthStateChange: vi.fn(() => ({
        data: { subscription: { unsubscribe: vi.fn() } },
      })),
    },
    from: (table: string) => mockFrom(table),
  },
}))

// Mock generateId for predictable tests
vi.mock('@/lib/utils', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/lib/utils')>()
  let counter = 0
  return {
    ...actual,
    generateId: vi.fn(() => `generated-id-${++counter}`),
  }
})

// Create chainable mock for Supabase queries
function createChainableMock(resolvedValue: any = { data: null, error: null }) {
  const createMock = (): any => {
    const mock: any = {}
    mock.select = vi.fn(() => mock)
    mock.insert = vi.fn(() => mock)
    mock.update = vi.fn(() => mock)
    mock.delete = vi.fn(() => mock)
    mock.eq = vi.fn(() => mock)
    mock.single = vi.fn().mockResolvedValue(resolvedValue)
    mock.order = vi.fn(() => mock)
    mock.limit = vi.fn(() => mock)
    mock.in = vi.fn(() => mock)
    mock.not = vi.fn(() => mock)
    // Make the mock itself a promise for terminal methods
    mock.then = (resolve: any) => resolve(resolvedValue)
    return mock
  }
  return createMock()
}

// Helper to reset store state
function resetStore() {
  useNutritionStore.setState({
    dietPlans: [],
    isLoading: false,
    error: null,
  })
}

// Mock coach for authenticated operations
const mockCoach = {
  id: 'coach-123',
  name: 'Test Coach',
  email: 'coach@test.com',
}

describe('useNutritionStore', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    resetStore()
    // Set up authenticated coach
    useAuthStore.setState({
      coach: mockCoach,
      token: 'mock-token',
      isAuthenticated: true,
      isLoading: false,
    })
  })

  afterEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({
      coach: null,
      token: null,
      isAuthenticated: false,
      isLoading: true,
    })
  })

  describe('initial state', () => {
    it('should have correct initial state', () => {
      resetStore()
      const state = useNutritionStore.getState()
      expect(state.dietPlans).toEqual([])
      expect(state.isLoading).toBe(false)
      expect(state.error).toBeNull()
    })
  })

  describe('foodCatalog', () => {
    it('should have all food categories', () => {
      const categories = foodCatalog.map(c => c.category)
      expect(categories).toContain('Protéines')
      expect(categories).toContain('Glucides')
      expect(categories).toContain('Lipides')
      expect(categories).toContain('Légumes')
    })

    it('should have foods in each category', () => {
      foodCatalog.forEach(category => {
        expect(category.foods.length).toBeGreaterThan(0)
      })
    })

    it('should have valid food structure', () => {
      const proteins = foodCatalog.find(c => c.category === 'Protéines')
      expect(proteins).toBeDefined()
      expect(proteins!.foods[0]).toHaveProperty('name')
      expect(proteins!.foods[0]).toHaveProperty('calories')
      expect(proteins!.foods[0]).toHaveProperty('macros')
      expect(proteins!.foods[0]).toHaveProperty('unit')
    })

    it('should have correct macro structure', () => {
      const proteins = foodCatalog.find(c => c.category === 'Protéines')
      expect(proteins!.foods[0].macros).toHaveProperty('protein')
      expect(proteins!.foods[0].macros).toHaveProperty('carbs')
      expect(proteins!.foods[0].macros).toHaveProperty('fat')
    })
  })

  describe('supplementCatalog', () => {
    it('should have supplements', () => {
      expect(supplementCatalog.length).toBeGreaterThan(0)
    })

    it('should have valid supplement structure', () => {
      expect(supplementCatalog[0]).toHaveProperty('name')
      expect(supplementCatalog[0]).toHaveProperty('dosage')
      expect(supplementCatalog[0]).toHaveProperty('timing')
    })

    it('should have valid timing values', () => {
      const validTimings = ['morning', 'pre-workout', 'post-workout', 'evening', 'with-meal']
      supplementCatalog.forEach(supp => {
        expect(validTimings).toContain(supp.timing)
      })
    })
  })

  describe('createMealPlan', () => {
    it('should create meal plan with empty foods', () => {
      const meal = createMealPlan('Breakfast')
      expect(meal).toHaveProperty('id')
      expect(meal.name).toBe('Breakfast')
      expect(meal.foods).toEqual([])
    })

    it('should create meal plan with foods', () => {
      const foods = [
        { id: 'food-1', name: 'Eggs', calories: 155, macros: { protein: 13, carbs: 1, fat: 11 }, quantity: 100, unit: '100g' },
      ]
      const meal = createMealPlan('Breakfast', foods)
      expect(meal.foods).toEqual(foods)
    })
  })

  describe('calculateMealMacros', () => {
    it('should calculate macros correctly for single food', () => {
      const foods = [
        { id: 'food-1', name: 'Chicken', calories: 165, macros: { protein: 31, carbs: 0, fat: 3.6 }, quantity: 100, unit: '100g' },
      ]
      const result = calculateMealMacros(foods)
      expect(result.calories).toBe(165)
      expect(result.macros.protein).toBe(31)
      expect(result.macros.carbs).toBe(0)
      expect(result.macros.fat).toBe(3.6)
    })

    it('should calculate macros correctly for multiple foods', () => {
      const foods = [
        { id: 'food-1', name: 'Chicken', calories: 165, macros: { protein: 31, carbs: 0, fat: 3.6 }, quantity: 100, unit: '100g' },
        { id: 'food-2', name: 'Rice', calories: 130, macros: { protein: 2.7, carbs: 28, fat: 0.3 }, quantity: 100, unit: '100g' },
      ]
      const result = calculateMealMacros(foods)
      expect(result.calories).toBe(295)
      expect(result.macros.protein).toBe(33.7)
      expect(result.macros.carbs).toBe(28)
      expect(result.macros.fat).toBeCloseTo(3.9)
    })

    it('should scale macros based on quantity', () => {
      const foods = [
        { id: 'food-1', name: 'Chicken', calories: 165, macros: { protein: 31, carbs: 0, fat: 3.6 }, quantity: 200, unit: '100g' },
      ]
      const result = calculateMealMacros(foods)
      expect(result.calories).toBe(330)
      expect(result.macros.protein).toBe(62)
    })

    it('should return zeros for empty foods array', () => {
      const result = calculateMealMacros([])
      expect(result.calories).toBe(0)
      expect(result.macros.protein).toBe(0)
      expect(result.macros.carbs).toBe(0)
      expect(result.macros.fat).toBe(0)
    })
  })

  describe('fetchDietPlans', () => {
    it('should fetch diet plans successfully', async () => {
      const mockPlans = [
        {
          id: 'diet-1',
          name: 'Bulk Plan',
          goal: 'bulk',
          training_calories: 3000,
          rest_calories: 2500,
          training_macros: { protein: 200, carbs: 350, fat: 80 },
          rest_macros: { protein: 200, carbs: 280, fat: 75 },
          meals: [],
          supplements: [],
          notes: 'Test notes',
          created_at: '2024-01-01T00:00:00Z',
          updated_at: '2024-01-15T00:00:00Z',
        },
        {
          id: 'diet-2',
          name: 'Cut Plan',
          goal: 'cut',
          training_calories: 2200,
          rest_calories: 1800,
          training_macros: { protein: 180, carbs: 200, fat: 60 },
          rest_macros: { protein: 180, carbs: 150, fat: 55 },
          meals: [],
          supplements: [],
          notes: null,
          created_at: '2024-02-01T00:00:00Z',
          updated_at: '2024-02-10T00:00:00Z',
        },
      ]

      const mockAssignments: any[] = []

      mockFrom.mockImplementation((table) => {
        if (table === 'diet_plans') {
          const mock = createChainableMock()
          mock.order = vi.fn().mockResolvedValue({ data: mockPlans, error: null })
          return mock
        }
        if (table === 'assignments') {
          return createChainableMock({ data: mockAssignments, error: null })
        }
        return createChainableMock()
      })

      await useNutritionStore.getState().fetchDietPlans()

      const state = useNutritionStore.getState()
      expect(state.isLoading).toBe(false)
      expect(state.error).toBeNull()
      expect(state.dietPlans).toHaveLength(2)
      expect(state.dietPlans[0].name).toBe('Bulk Plan')
      expect(state.dietPlans[0].trainingCalories).toBe(3000)
      expect(state.dietPlans[0].goal).toBe('bulk')
      expect(state.dietPlans[1].name).toBe('Cut Plan')
    })

    it('should not fetch if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await useNutritionStore.getState().fetchDietPlans()

      expect(mockFrom).not.toHaveBeenCalled()
    })

    it('should handle fetch error', async () => {
      mockFrom.mockImplementation(() => {
        const mock = createChainableMock()
        mock.order = vi.fn().mockResolvedValue({
          data: null,
          error: { message: 'Database error' },
        })
        return mock
      })

      await useNutritionStore.getState().fetchDietPlans()

      const state = useNutritionStore.getState()
      expect(state.isLoading).toBe(false)
      expect(state.error).toBe('Database error')
    })

    it('should set loading state while fetching', async () => {
      mockFrom.mockImplementation(() => {
        const mock = createChainableMock()
        mock.order = vi.fn().mockResolvedValue({ data: [], error: null })
        return mock
      })

      const fetchPromise = useNutritionStore.getState().fetchDietPlans()

      expect(useNutritionStore.getState().isLoading).toBe(true)

      await fetchPromise

      expect(useNutritionStore.getState().isLoading).toBe(false)
    })
  })

  describe('addDietPlan', () => {
    it('should add diet plan successfully', async () => {
      const mockInsertedData = {
        id: 'new-diet-123',
        name: 'New Diet',
        goal: 'maintain',
        training_calories: 2500,
        rest_calories: 2200,
        training_macros: { protein: 180, carbs: 280, fat: 70 },
        rest_macros: { protein: 180, carbs: 240, fat: 65 },
        meals: [],
        supplements: [],
        notes: null,
        created_at: '2024-12-20T00:00:00Z',
        updated_at: '2024-12-20T00:00:00Z',
      }

      mockFrom.mockImplementation(() => ({
        insert: vi.fn().mockReturnThis(),
        select: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: mockInsertedData, error: null }),
      }))

      const newDietData = {
        name: 'New Diet',
        goal: 'maintain' as const,
        trainingCalories: 2500,
        restCalories: 2200,
        trainingMacros: { protein: 180, carbs: 280, fat: 70 },
        restMacros: { protein: 180, carbs: 240, fat: 65 },
        meals: [],
        supplements: [],
      }

      const newId = await useNutritionStore.getState().addDietPlan(newDietData)

      expect(newId).toBe('new-diet-123')

      const state = useNutritionStore.getState()
      expect(state.dietPlans).toHaveLength(1)
      expect(state.dietPlans[0].name).toBe('New Diet')
      expect(state.dietPlans[0].assignedStudentIds).toEqual([])
    })

    it('should throw error if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await expect(
        useNutritionStore.getState().addDietPlan({
          name: 'Test',
          goal: 'maintain',
          trainingCalories: 2500,
          restCalories: 2200,
          trainingMacros: { protein: 180, carbs: 280, fat: 70 },
          restMacros: { protein: 180, carbs: 240, fat: 65 },
          meals: [],
          supplements: [],
        })
      ).rejects.toThrow('Non authentifié')
    })

    it('should throw error if insert fails', async () => {
      mockFrom.mockImplementation(() => ({
        insert: vi.fn().mockReturnThis(),
        select: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: null, error: { message: 'Insert failed' } }),
      }))

      await expect(
        useNutritionStore.getState().addDietPlan({
          name: 'Test',
          goal: 'maintain',
          trainingCalories: 2500,
          restCalories: 2200,
          trainingMacros: { protein: 180, carbs: 280, fat: 70 },
          restMacros: { protein: 180, carbs: 240, fat: 65 },
          meals: [],
          supplements: [],
        })
      ).rejects.toThrow()
    })
  })

  describe('updateDietPlan', () => {
    beforeEach(() => {
      useNutritionStore.setState({
        dietPlans: [
          {
            id: 'diet-1',
            name: 'Original Name',
            goal: 'maintain',
            trainingCalories: 2500,
            restCalories: 2200,
            trainingMacros: { protein: 180, carbs: 280, fat: 70 },
            restMacros: { protein: 180, carbs: 240, fat: 65 },
            meals: [],
            supplements: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: [],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should update diet plan successfully', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: null }),
      }))

      await useNutritionStore.getState().updateDietPlan('diet-1', { name: 'Updated Name' })

      const state = useNutritionStore.getState()
      expect(state.dietPlans[0].name).toBe('Updated Name')
    })

    it('should update multiple fields', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: null }),
      }))

      await useNutritionStore.getState().updateDietPlan('diet-1', {
        name: 'New Name',
        goal: 'bulk',
        trainingCalories: 3000,
        restCalories: 2600,
        trainingMacros: { protein: 200, carbs: 350, fat: 80 },
        notes: 'Updated notes',
      })

      const state = useNutritionStore.getState()
      expect(state.dietPlans[0].name).toBe('New Name')
      expect(state.dietPlans[0].goal).toBe('bulk')
      expect(state.dietPlans[0].trainingCalories).toBe(3000)
      expect(state.dietPlans[0].notes).toBe('Updated notes')
    })

    it('should update meals array', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: null }),
      }))

      const newMeals = [
        { id: 'meal-1', name: 'Breakfast', foods: [] },
        { id: 'meal-2', name: 'Lunch', foods: [] },
      ]

      await useNutritionStore.getState().updateDietPlan('diet-1', { meals: newMeals })

      const state = useNutritionStore.getState()
      expect(state.dietPlans[0].meals).toHaveLength(2)
    })

    it('should update supplements array', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: null }),
      }))

      const newSupplements = [
        { id: 'supp-1', name: 'Creatine', dosage: '5g', timing: 'post-workout' as const },
      ]

      await useNutritionStore.getState().updateDietPlan('diet-1', { supplements: newSupplements })

      const state = useNutritionStore.getState()
      expect(state.dietPlans[0].supplements).toHaveLength(1)
    })

    it('should throw error if update fails', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: { message: 'Update failed' } }),
      }))

      await expect(
        useNutritionStore.getState().updateDietPlan('diet-1', { name: 'New Name' })
      ).rejects.toThrow()
    })
  })

  describe('deleteDietPlan', () => {
    beforeEach(() => {
      useNutritionStore.setState({
        dietPlans: [
          {
            id: 'diet-1',
            name: 'Diet 1',
            goal: 'maintain',
            trainingCalories: 2500,
            restCalories: 2200,
            trainingMacros: { protein: 180, carbs: 280, fat: 70 },
            restMacros: { protein: 180, carbs: 240, fat: 65 },
            meals: [],
            supplements: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: [],
          },
          {
            id: 'diet-2',
            name: 'Diet 2',
            goal: 'bulk',
            trainingCalories: 3000,
            restCalories: 2600,
            trainingMacros: { protein: 200, carbs: 350, fat: 80 },
            restMacros: { protein: 200, carbs: 300, fat: 75 },
            meals: [],
            supplements: [],
            createdAt: '2024-02-01T00:00:00Z',
            updatedAt: '2024-02-10T00:00:00Z',
            assignedStudentIds: [],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should delete diet plan successfully', async () => {
      mockFrom.mockImplementation(() => ({
        delete: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: null }),
      }))

      await useNutritionStore.getState().deleteDietPlan('diet-1')

      const state = useNutritionStore.getState()
      expect(state.dietPlans).toHaveLength(1)
      expect(state.dietPlans[0].id).toBe('diet-2')
    })

    it('should throw error if delete fails', async () => {
      mockFrom.mockImplementation(() => ({
        delete: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: { message: 'Delete failed' } }),
      }))

      await expect(
        useNutritionStore.getState().deleteDietPlan('diet-1')
      ).rejects.toThrow()
    })
  })

  describe('duplicateDietPlan', () => {
    beforeEach(() => {
      useNutritionStore.setState({
        dietPlans: [
          {
            id: 'diet-1',
            name: 'Original Diet',
            goal: 'maintain',
            trainingCalories: 2500,
            restCalories: 2200,
            trainingMacros: { protein: 180, carbs: 280, fat: 70 },
            restMacros: { protein: 180, carbs: 240, fat: 65 },
            meals: [
              {
                id: 'meal-1',
                name: 'Breakfast',
                foods: [
                  { id: 'food-1', name: 'Eggs', calories: 155, macros: { protein: 13, carbs: 1, fat: 11 }, quantity: 100, unit: '100g' },
                ],
              },
            ],
            supplements: [
              { id: 'supp-1', name: 'Creatine', dosage: '5g', timing: 'post-workout' },
            ],
            notes: 'Original notes',
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: ['student-1'],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should duplicate diet plan with new IDs', async () => {
      const mockInsertedData = {
        id: 'new-diet-123',
        name: 'Original Diet (copie)',
        goal: 'maintain',
        training_calories: 2500,
        rest_calories: 2200,
        training_macros: { protein: 180, carbs: 280, fat: 70 },
        rest_macros: { protein: 180, carbs: 240, fat: 65 },
        meals: [],
        supplements: [],
        notes: 'Original notes',
        created_at: '2024-12-20T00:00:00Z',
        updated_at: '2024-12-20T00:00:00Z',
      }

      mockFrom.mockImplementation(() => ({
        insert: vi.fn().mockReturnThis(),
        select: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: mockInsertedData, error: null }),
      }))

      const newId = await useNutritionStore.getState().duplicateDietPlan('diet-1')

      expect(newId).toBe('new-diet-123')

      const state = useNutritionStore.getState()
      expect(state.dietPlans).toHaveLength(2)
      expect(state.dietPlans[0].name).toBe('Original Diet (copie)')
      expect(state.dietPlans.some(p => p.id === 'diet-1')).toBe(true)
    })

    it('should return null if diet plan not found', async () => {
      const newId = await useNutritionStore.getState().duplicateDietPlan('non-existent')
      expect(newId).toBeNull()
    })

    it('should return null if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      const newId = await useNutritionStore.getState().duplicateDietPlan('diet-1')
      expect(newId).toBeNull()
    })
  })

  describe('getDietPlanById', () => {
    beforeEach(() => {
      useNutritionStore.setState({
        dietPlans: [
          {
            id: 'diet-1',
            name: 'Diet 1',
            goal: 'maintain',
            trainingCalories: 2500,
            restCalories: 2200,
            trainingMacros: { protein: 180, carbs: 280, fat: 70 },
            restMacros: { protein: 180, carbs: 240, fat: 65 },
            meals: [],
            supplements: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: [],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should return diet plan by id', () => {
      const plan = useNutritionStore.getState().getDietPlanById('diet-1')
      expect(plan).toBeDefined()
      expect(plan?.name).toBe('Diet 1')
    })

    it('should return undefined for non-existent id', () => {
      const plan = useNutritionStore.getState().getDietPlanById('non-existent')
      expect(plan).toBeUndefined()
    })
  })

  describe('assignToStudent', () => {
    beforeEach(() => {
      useNutritionStore.setState({
        dietPlans: [
          {
            id: 'diet-1',
            name: 'Diet 1',
            goal: 'maintain',
            trainingCalories: 2500,
            restCalories: 2200,
            trainingMacros: { protein: 180, carbs: 280, fat: 70 },
            restMacros: { protein: 180, carbs: 240, fat: 65 },
            meals: [],
            supplements: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: [],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should assign diet plan to new student', async () => {
      const insertMock = vi.fn().mockResolvedValue({ data: null, error: null })

      mockFrom.mockImplementation(() => ({
        select: vi.fn().mockReturnThis(),
        insert: insertMock,
        eq: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: null, error: null }),
      }))

      await useNutritionStore.getState().assignToStudent('diet-1', 'student-1')

      const state = useNutritionStore.getState()
      expect(state.dietPlans[0].assignedStudentIds).toContain('student-1')
    })

    it('should update existing assignment', async () => {
      const updateMock = vi.fn().mockReturnThis()
      const existingAssignment = { id: 'assignment-1' }

      mockFrom.mockImplementation(() => ({
        select: vi.fn().mockReturnThis(),
        update: updateMock,
        eq: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: existingAssignment, error: null }),
      }))

      await useNutritionStore.getState().assignToStudent('diet-1', 'student-1')

      const state = useNutritionStore.getState()
      expect(state.dietPlans[0].assignedStudentIds).toContain('student-1')
    })

    it('should not duplicate student id', async () => {
      useNutritionStore.setState({
        dietPlans: [
          {
            id: 'diet-1',
            name: 'Diet 1',
            goal: 'maintain',
            trainingCalories: 2500,
            restCalories: 2200,
            trainingMacros: { protein: 180, carbs: 280, fat: 70 },
            restMacros: { protein: 180, carbs: 240, fat: 65 },
            meals: [],
            supplements: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: ['student-1'],
          },
        ],
        isLoading: false,
        error: null,
      })

      const existingAssignment = { id: 'assignment-1' }

      mockFrom.mockImplementation(() => ({
        select: vi.fn().mockReturnThis(),
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockReturnThis(),
        single: vi.fn().mockResolvedValue({ data: existingAssignment, error: null }),
      }))

      await useNutritionStore.getState().assignToStudent('diet-1', 'student-1')

      const state = useNutritionStore.getState()
      expect(state.dietPlans[0].assignedStudentIds.filter(id => id === 'student-1')).toHaveLength(1)
    })

    it('should not assign if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await useNutritionStore.getState().assignToStudent('diet-1', 'student-1')

      expect(mockFrom).not.toHaveBeenCalled()
    })
  })

  describe('unassignFromStudent', () => {
    beforeEach(() => {
      useNutritionStore.setState({
        dietPlans: [
          {
            id: 'diet-1',
            name: 'Diet 1',
            goal: 'maintain',
            trainingCalories: 2500,
            restCalories: 2200,
            trainingMacros: { protein: 180, carbs: 280, fat: 70 },
            restMacros: { protein: 180, carbs: 240, fat: 65 },
            meals: [],
            supplements: [],
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-15T00:00:00Z',
            assignedStudentIds: ['student-1', 'student-2'],
          },
        ],
        isLoading: false,
        error: null,
      })
    })

    it('should unassign student from diet plan', async () => {
      mockFrom.mockImplementation(() => createChainableMock({ data: null, error: null }))

      await useNutritionStore.getState().unassignFromStudent('diet-1', 'student-1')

      const state = useNutritionStore.getState()
      expect(state.dietPlans[0].assignedStudentIds).toEqual(['student-2'])
      expect(state.dietPlans[0].assignedStudentIds).not.toContain('student-1')
    })

    it('should throw error if unassign fails', async () => {
      mockFrom.mockImplementation(() => ({
        update: vi.fn().mockReturnThis(),
        eq: vi.fn().mockResolvedValue({ data: null, error: { message: 'Unassign failed' } }),
      }))

      await expect(
        useNutritionStore.getState().unassignFromStudent('diet-1', 'student-1')
      ).rejects.toThrow()
    })

    it('should not unassign if not authenticated', async () => {
      useAuthStore.setState({
        coach: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
      })

      await useNutritionStore.getState().unassignFromStudent('diet-1', 'student-1')

      expect(mockFrom).not.toHaveBeenCalled()
      const state = useNutritionStore.getState()
      expect(state.dietPlans[0].assignedStudentIds).toEqual(['student-1', 'student-2'])
    })
  })
})
