import { create } from 'zustand'
import type { DietPlan, FoodEntry, MealPlan, SupplementEntry, Macros } from '@/types'
import { generateId } from '@/lib/utils'

interface NutritionState {
  dietPlans: DietPlan[]
  addDietPlan: (plan: Omit<DietPlan, 'id' | 'createdAt' | 'updatedAt' | 'assignedStudentIds'>) => string
  updateDietPlan: (id: string, updates: Partial<DietPlan>) => void
  deleteDietPlan: (id: string) => void
  assignToStudent: (planId: string, studentId: string) => void
  unassignFromStudent: (planId: string, studentId: string) => void
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

// Mock diet plans
const mockDietPlans: DietPlan[] = [
  {
    id: 'diet-1',
    name: 'Sèche Femme -500kcal',
    goal: 'cut',
    trainingCalories: 1800,
    restCalories: 1500,
    trainingMacros: { protein: 140, carbs: 180, fat: 50 },
    restMacros: { protein: 140, carbs: 120, fat: 50 },
    meals: [
      createMealPlan('Petit-déjeuner'),
      createMealPlan('Déjeuner'),
      createMealPlan('Collation'),
      createMealPlan('Dîner'),
    ],
    supplements: [
      { id: 's1', name: 'Omega-3', dosage: '2g', timing: 'with-meal' },
      { id: 's2', name: 'Vitamine D3', dosage: '2000 UI', timing: 'morning' },
    ],
    createdAt: '2025-01-10T00:00:00Z',
    updatedAt: '2025-01-15T00:00:00Z',
    assignedStudentIds: ['student-1'],
  },
  {
    id: 'diet-2',
    name: 'Prise de masse +300kcal',
    goal: 'bulk',
    trainingCalories: 3200,
    restCalories: 2800,
    trainingMacros: { protein: 180, carbs: 400, fat: 90 },
    restMacros: { protein: 180, carbs: 320, fat: 80 },
    meals: [
      createMealPlan('Petit-déjeuner'),
      createMealPlan('Déjeuner'),
      createMealPlan('Collation'),
      createMealPlan('Dîner'),
      createMealPlan('Avant-dodo'),
    ],
    supplements: [
      { id: 's3', name: 'Créatine monohydrate', dosage: '5g', timing: 'post-workout' },
      { id: 's4', name: 'Omega-3', dosage: '3g', timing: 'with-meal' },
    ],
    createdAt: '2025-01-08T00:00:00Z',
    updatedAt: '2025-01-12T00:00:00Z',
    assignedStudentIds: ['student-2'],
  },
  {
    id: 'diet-3',
    name: 'Maintien Athlète',
    goal: 'maintain',
    trainingCalories: 2600,
    restCalories: 2200,
    trainingMacros: { protein: 160, carbs: 300, fat: 70 },
    restMacros: { protein: 160, carbs: 230, fat: 65 },
    meals: [
      createMealPlan('Petit-déjeuner'),
      createMealPlan('Déjeuner'),
      createMealPlan('Dîner'),
    ],
    supplements: [],
    createdAt: '2025-01-01T00:00:00Z',
    updatedAt: '2025-01-01T00:00:00Z',
    assignedStudentIds: ['student-4'],
  },
]

export const useNutritionStore = create<NutritionState>((set) => ({
  dietPlans: mockDietPlans,

  addDietPlan: (planData) => {
    const id = generateId()
    const now = new Date().toISOString()
    const newPlan: DietPlan = {
      ...planData,
      id,
      createdAt: now,
      updatedAt: now,
      assignedStudentIds: [],
    }
    set((state) => ({ dietPlans: [...state.dietPlans, newPlan] }))
    return id
  },

  updateDietPlan: (id, updates) => {
    set((state) => ({
      dietPlans: state.dietPlans.map((p) =>
        p.id === id ? { ...p, ...updates, updatedAt: new Date().toISOString() } : p
      ),
    }))
  },

  deleteDietPlan: (id) => {
    set((state) => ({
      dietPlans: state.dietPlans.filter((p) => p.id !== id),
    }))
  },

  assignToStudent: (planId, studentId) => {
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

  unassignFromStudent: (planId, studentId) => {
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
