import { create } from 'zustand'
import type { DietPlan, FoodEntry, MealPlan, SupplementEntry, Macros } from '@/types'
import { generateId } from '@/lib/utils'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth-store'

interface NutritionState {
  dietPlans: DietPlan[]
  isLoading: boolean
  error: string | null
  fetchDietPlans: () => Promise<void>
  addDietPlan: (plan: Omit<DietPlan, 'id' | 'createdAt' | 'updatedAt' | 'assignedStudentIds'>) => Promise<string>
  updateDietPlan: (id: string, updates: Partial<DietPlan>) => Promise<void>
  deleteDietPlan: (id: string) => Promise<void>
  duplicateDietPlan: (id: string) => Promise<string | null>
  getDietPlanById: (id: string) => DietPlan | undefined
  assignToStudent: (planId: string, studentId: string) => Promise<void>
  unassignFromStudent: (planId: string, studentId: string) => Promise<void>
}

// Food catalog for meal creation
export const foodCatalog: { category: string; foods: Omit<FoodEntry, 'id' | 'quantity'>[] }[] = [
  {
    category: 'Protéines',
    foods: [
      { name: 'Blanc de poulet', calories: 165, macros: { protein: 31, carbs: 0, fat: 3.6 }, unit: '100g' },
      { name: 'Steak haché 5%', calories: 137, macros: { protein: 26, carbs: 0, fat: 5 }, unit: '100g' },
      { name: 'Saumon', calories: 208, macros: { protein: 20, carbs: 0, fat: 13 }, unit: '100g' },
      { name: 'Œuf entier', calories: 155, macros: { protein: 13, carbs: 1.1, fat: 11 }, unit: '100g' },
      { name: 'Blanc d\'œuf', calories: 52, macros: { protein: 11, carbs: 0.7, fat: 0.2 }, unit: '100g' },
      { name: 'Thon en boîte', calories: 116, macros: { protein: 26, carbs: 0, fat: 1 }, unit: '100g' },
      { name: 'Crevettes', calories: 99, macros: { protein: 24, carbs: 0.2, fat: 0.3 }, unit: '100g' },
      { name: 'Fromage blanc 0%', calories: 45, macros: { protein: 8, carbs: 4, fat: 0 }, unit: '100g' },
      { name: 'Whey protein', calories: 120, macros: { protein: 24, carbs: 3, fat: 1.5 }, unit: '30g' },
    ],
  },
  {
    category: 'Glucides',
    foods: [
      { name: 'Riz blanc', calories: 130, macros: { protein: 2.7, carbs: 28, fat: 0.3 }, unit: '100g' },
      { name: 'Riz complet', calories: 111, macros: { protein: 2.6, carbs: 23, fat: 0.9 }, unit: '100g' },
      { name: 'Pâtes', calories: 131, macros: { protein: 5, carbs: 25, fat: 1.1 }, unit: '100g' },
      { name: 'Patate douce', calories: 86, macros: { protein: 1.6, carbs: 20, fat: 0.1 }, unit: '100g' },
      { name: 'Pomme de terre', calories: 77, macros: { protein: 2, carbs: 17, fat: 0.1 }, unit: '100g' },
      { name: 'Avoine', calories: 389, macros: { protein: 17, carbs: 66, fat: 7 }, unit: '100g' },
      { name: 'Pain complet', calories: 247, macros: { protein: 13, carbs: 41, fat: 3.4 }, unit: '100g' },
      { name: 'Banane', calories: 89, macros: { protein: 1.1, carbs: 23, fat: 0.3 }, unit: '100g' },
    ],
  },
  {
    category: 'Lipides',
    foods: [
      { name: 'Huile d\'olive', calories: 884, macros: { protein: 0, carbs: 0, fat: 100 }, unit: '100ml' },
      { name: 'Beurre de cacahuète', calories: 588, macros: { protein: 25, carbs: 20, fat: 50 }, unit: '100g' },
      { name: 'Avocat', calories: 160, macros: { protein: 2, carbs: 9, fat: 15 }, unit: '100g' },
      { name: 'Amandes', calories: 579, macros: { protein: 21, carbs: 22, fat: 50 }, unit: '100g' },
      { name: 'Noix', calories: 654, macros: { protein: 15, carbs: 14, fat: 65 }, unit: '100g' },
    ],
  },
  {
    category: 'Légumes',
    foods: [
      { name: 'Brocoli', calories: 34, macros: { protein: 2.8, carbs: 7, fat: 0.4 }, unit: '100g' },
      { name: 'Épinards', calories: 23, macros: { protein: 2.9, carbs: 3.6, fat: 0.4 }, unit: '100g' },
      { name: 'Haricots verts', calories: 31, macros: { protein: 1.8, carbs: 7, fat: 0.1 }, unit: '100g' },
      { name: 'Courgette', calories: 17, macros: { protein: 1.2, carbs: 3.1, fat: 0.3 }, unit: '100g' },
      { name: 'Tomate', calories: 18, macros: { protein: 0.9, carbs: 3.9, fat: 0.2 }, unit: '100g' },
    ],
  },
]

// Supplement catalog
export const supplementCatalog: Omit<SupplementEntry, 'id'>[] = [
  { name: 'Créatine monohydrate', dosage: '5g', timing: 'post-workout' },
  { name: 'Omega-3', dosage: '2g', timing: 'with-meal' },
  { name: 'Vitamine D3', dosage: '2000 UI', timing: 'morning' },
  { name: 'Zinc', dosage: '15mg', timing: 'evening' },
  { name: 'Magnésium', dosage: '400mg', timing: 'evening' },
  { name: 'Caféine', dosage: '200mg', timing: 'pre-workout' },
  { name: 'Beta-alanine', dosage: '3g', timing: 'pre-workout' },
  { name: 'BCAA', dosage: '5g', timing: 'pre-workout' },
]

// Helper to create a meal plan
export function createMealPlan(name: string, foods: FoodEntry[] = []): MealPlan {
  return {
    id: generateId(),
    name,
    foods,
  }
}

// Helper to calculate macros from foods
export function calculateMealMacros(foods: FoodEntry[]): { calories: number; macros: Macros } {
  return foods.reduce(
    (acc, food) => {
      const multiplier = food.quantity / 100
      return {
        calories: acc.calories + food.calories * multiplier,
        macros: {
          protein: acc.macros.protein + food.macros.protein * multiplier,
          carbs: acc.macros.carbs + food.macros.carbs * multiplier,
          fat: acc.macros.fat + food.macros.fat * multiplier,
        },
      }
    },
    { calories: 0, macros: { protein: 0, carbs: 0, fat: 0 } }
  )
}

// Transform database row to DietPlan type
function dbToDietPlan(row: any): DietPlan {
  return {
    id: row.id,
    name: row.name,
    goal: row.goal,
    trainingCalories: row.training_calories,
    restCalories: row.rest_calories,
    trainingMacros: row.training_macros || { protein: 0, carbs: 0, fat: 0 },
    restMacros: row.rest_macros || { protein: 0, carbs: 0, fat: 0 },
    meals: row.meals || [],
    supplements: row.supplements || [],
    notes: row.notes || undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    assignedStudentIds: [], // Will be populated from assignments table
  }
}

// Transform DietPlan to database row
function dietPlanToDb(plan: Omit<DietPlan, 'id' | 'createdAt' | 'updatedAt' | 'assignedStudentIds'>, createdBy: string) {
  return {
    created_by: createdBy,
    name: plan.name,
    goal: plan.goal,
    training_calories: plan.trainingCalories,
    rest_calories: plan.restCalories,
    training_macros: plan.trainingMacros,
    rest_macros: plan.restMacros,
    meals: plan.meals,
    supplements: plan.supplements,
    notes: plan.notes || null,
  }
}

export const useNutritionStore = create<NutritionState>((set, get) => ({
  dietPlans: [],
  isLoading: false,
  error: null,

  fetchDietPlans: async () => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    set({ isLoading: true, error: null })

    try {
      // Fetch diet plans created by this coach
      const { data: plans, error: plansError } = await supabase
        .from('diet_plans')
        .select('*')
        .eq('created_by', coach.id)
        .order('created_at', { ascending: false })

      if (plansError) throw plansError

      // Fetch assignments to get assigned students
      const { data: assignments, error: assignmentsError } = await supabase
        .from('assignments')
        .select('diet_plan_id, student_id')
        .eq('coach_id', coach.id)
        .not('diet_plan_id', 'is', null)
        .eq('status', 'active')

      if (assignmentsError) throw assignmentsError

      // Transform and merge data
      const transformedPlans = (plans || []).map(row => {
        const plan = dbToDietPlan(row)
        plan.assignedStudentIds = (assignments || [])
          .filter(a => a.diet_plan_id === plan.id)
          .map(a => a.student_id)
        return plan
      })

      set({ dietPlans: transformedPlans, isLoading: false })
    } catch (error: any) {
      console.error('Error fetching diet plans:', error)
      set({ error: error.message, isLoading: false })
    }
  },

  addDietPlan: async (planData) => {
    const coach = useAuthStore.getState().coach
    if (!coach) throw new Error('Non authentifié')

    const dbData = dietPlanToDb(planData, coach.id)

    const { data, error } = await supabase
      .from('diet_plans')
      .insert(dbData)
      .select()
      .single()

    if (error) throw error

    const newPlan = dbToDietPlan(data)
    newPlan.assignedStudentIds = []

    set((state) => ({ dietPlans: [newPlan, ...state.dietPlans] }))
    return newPlan.id
  },

  updateDietPlan: async (id, updates) => {
    const dbUpdates: any = {}
    if (updates.name !== undefined) dbUpdates.name = updates.name
    if (updates.goal !== undefined) dbUpdates.goal = updates.goal
    if (updates.trainingCalories !== undefined) dbUpdates.training_calories = updates.trainingCalories
    if (updates.restCalories !== undefined) dbUpdates.rest_calories = updates.restCalories
    if (updates.trainingMacros !== undefined) dbUpdates.training_macros = updates.trainingMacros
    if (updates.restMacros !== undefined) dbUpdates.rest_macros = updates.restMacros
    if (updates.meals !== undefined) dbUpdates.meals = updates.meals
    if (updates.supplements !== undefined) dbUpdates.supplements = updates.supplements
    if (updates.notes !== undefined) dbUpdates.notes = updates.notes

    const { error } = await supabase
      .from('diet_plans')
      .update(dbUpdates)
      .eq('id', id)

    if (error) throw error

    set((state) => ({
      dietPlans: state.dietPlans.map((p) =>
        p.id === id ? { ...p, ...updates, updatedAt: new Date().toISOString() } : p
      ),
    }))
  },

  deleteDietPlan: async (id) => {
    const { error } = await supabase
      .from('diet_plans')
      .delete()
      .eq('id', id)

    if (error) throw error

    set((state) => ({
      dietPlans: state.dietPlans.filter((p) => p.id !== id),
    }))
  },

  duplicateDietPlan: async (id) => {
    const plan = get().dietPlans.find((p) => p.id === id)
    if (!plan) return null

    const coach = useAuthStore.getState().coach
    if (!coach) return null

    // Create new plan with copied data
    const duplicateData = {
      name: `${plan.name} (copie)`,
      goal: plan.goal,
      trainingCalories: plan.trainingCalories,
      restCalories: plan.restCalories,
      trainingMacros: { ...plan.trainingMacros },
      restMacros: { ...plan.restMacros },
      meals: plan.meals.map((meal) => ({
        ...meal,
        id: generateId(),
        foods: meal.foods.map((food) => ({
          ...food,
          id: generateId(),
        })),
      })),
      supplements: plan.supplements.map((supp) => ({
        ...supp,
        id: generateId(),
      })),
      notes: plan.notes,
    }

    const newId = await get().addDietPlan(duplicateData)
    return newId
  },

  getDietPlanById: (id) => get().dietPlans.find((p) => p.id === id),

  assignToStudent: async (planId, studentId) => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    // Check if assignment already exists
    const { data: existing } = await supabase
      .from('assignments')
      .select('id')
      .eq('coach_id', coach.id)
      .eq('student_id', studentId)
      .eq('diet_plan_id', planId)
      .single()

    if (existing) {
      // Update existing assignment to active
      await supabase
        .from('assignments')
        .update({ status: 'active' })
        .eq('id', existing.id)
    } else {
      // Create new assignment
      const { error } = await supabase
        .from('assignments')
        .insert({
          coach_id: coach.id,
          student_id: studentId,
          diet_plan_id: planId,
          status: 'active',
        })

      if (error) throw error
    }

    set((state) => ({
      dietPlans: state.dietPlans.map((p) =>
        p.id === planId
          ? {
              ...p,
              assignedStudentIds: [...new Set([...p.assignedStudentIds, studentId])],
              updatedAt: new Date().toISOString(),
            }
          : p
      ),
    }))
  },

  unassignFromStudent: async (planId, studentId) => {
    const coach = useAuthStore.getState().coach
    if (!coach) return

    // Set assignment status to paused instead of deleting
    const { error } = await supabase
      .from('assignments')
      .update({ status: 'paused' })
      .eq('coach_id', coach.id)
      .eq('student_id', studentId)
      .eq('diet_plan_id', planId)

    if (error) throw error

    set((state) => ({
      dietPlans: state.dietPlans.map((p) =>
        p.id === planId
          ? {
              ...p,
              assignedStudentIds: p.assignedStudentIds.filter((id) => id !== studentId),
              updatedAt: new Date().toISOString(),
            }
          : p
      ),
    }))
  },
}))
