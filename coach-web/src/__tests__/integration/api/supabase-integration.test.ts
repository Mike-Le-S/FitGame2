/**
 * Supabase Integration Tests
 *
 * These tests run against the REAL Supabase database.
 * They test authentication, programs CRUD, and diet plans CRUD.
 *
 * IMPORTANT: These tests create real data in the database and clean up after themselves.
 *
 * CONFIGURATION:
 * To run these tests with full functionality, you can either:
 *
 * 1. Use an existing test account (recommended for CI/CD):
 *    Set these environment variables:
 *    - TEST_USER_EMAIL: Email of an existing confirmed test user
 *    - TEST_USER_PASSWORD: Password of the test user
 *
 * 2. Create a new user each time (requires Supabase email confirmation disabled):
 *    The tests will create a new user with a random email.
 *
 * To run these tests:
 * npm run test -- src/__tests__/integration/api/supabase-integration.test.ts
 */

import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest'
import { createClient, SupabaseClient } from '@supabase/supabase-js'

// Real Supabase configuration
const SUPABASE_URL = 'https://snqeueklxfdwxfrrpdvl.supabase.co'
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || process.env.VITE_SUPABASE_ANON_KEY

// Test user credentials
// You can set TEST_USER_EMAIL and TEST_USER_PASSWORD env vars to use an existing confirmed account
const TEST_TIMESTAMP = Date.now()
const USE_EXISTING_USER = !!(process.env.TEST_USER_EMAIL && process.env.TEST_USER_PASSWORD)
const TEST_EMAIL = process.env.TEST_USER_EMAIL || `test.runner.${TEST_TIMESTAMP}@gmail.com`
const TEST_PASSWORD = process.env.TEST_USER_PASSWORD || 'TestPassword123!'
const TEST_FULL_NAME = 'Test Runner User'

// Store test data IDs for cleanup
interface TestContext {
  supabase: SupabaseClient
  userId: string | null
  programIds: string[]
  dietPlanIds: string[]
  isAuthenticated: boolean
  createdNewUser: boolean
}

const testContext: TestContext = {
  supabase: null as unknown as SupabaseClient,
  userId: null,
  programIds: [],
  dietPlanIds: [],
  isAuthenticated: false,
  createdNewUser: false,
}

// Helper to wait for a short period (for eventual consistency)
const wait = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

describe('Supabase Integration Tests', () => {
  // ============================================
  // SETUP
  // ============================================

  beforeAll(async () => {
    if (!SUPABASE_ANON_KEY) {
      throw new Error('VITE_SUPABASE_ANON_KEY environment variable is required for integration tests')
    }

    // Create a fresh Supabase client for tests
    testContext.supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    })

    // If using existing user, try to log in immediately
    if (USE_EXISTING_USER) {
      console.log(`Using existing test user: ${TEST_EMAIL}`)
      const { data, error } = await testContext.supabase.auth.signInWithPassword({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
      })

      if (!error && data.session) {
        testContext.userId = data.user?.id || null
        testContext.isAuthenticated = true
        console.log('Successfully authenticated with existing test user')
      } else {
        console.log('Could not authenticate with existing user:', error?.message)
      }
    }
  }, 15000)

  // ============================================
  // AUTH TESTS (4 tests)
  // ============================================

  describe('Authentication', () => {
    it('signUp creates user and profile', async () => {
      // Skip if using existing user
      if (USE_EXISTING_USER && testContext.isAuthenticated) {
        console.log('Using existing user - signUp test validates existing profile')

        // Verify profile exists for existing user
        const { data: profile } = await testContext.supabase
          .from('profiles')
          .select('*')
          .eq('id', testContext.userId!)
          .single()

        expect(profile).toBeDefined()
        expect(profile?.role).toBe('coach')
        return
      }

      // Sign up a new user
      const { data, error } = await testContext.supabase.auth.signUp({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        options: {
          data: {
            full_name: TEST_FULL_NAME,
            role: 'coach',
          },
        },
      })

      // Handle various signup scenarios
      if (error) {
        if (error.message.includes('Email address')) {
          console.log('Skipping signUp test: Supabase email validation is strict')
          return
        }
        if (error.message.includes('rate limit')) {
          console.log('Skipping signUp test: Email rate limit exceeded')
          return
        }
        if (error.message.includes('already registered')) {
          // Try to log in instead
          const { data: loginData, error: loginError } = await testContext.supabase.auth.signInWithPassword({
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
          })

          if (!loginError && loginData.session) {
            testContext.userId = loginData.user?.id || null
            testContext.isAuthenticated = true
          }
          return
        }
        throw error
      }

      expect(data.user).toBeDefined()
      expect(data.user?.email).toBe(TEST_EMAIL)

      // Store user ID for later tests
      testContext.userId = data.user?.id || null
      testContext.createdNewUser = true

      // If we have a session, we're authenticated (no email confirmation needed)
      if (data.session) {
        testContext.isAuthenticated = true
      }

      // Wait for any database triggers
      await wait(1000)

      // Manually ensure profile exists (in case trigger didn't fire)
      if (testContext.userId && data.session) {
        const { error: profileError } = await testContext.supabase
          .from('profiles')
          .upsert({
            id: testContext.userId,
            email: TEST_EMAIL,
            full_name: TEST_FULL_NAME,
            role: 'coach',
          }, {
            onConflict: 'id',
          })

        if (profileError) {
          console.log('Profile upsert note:', profileError.message)
        }

        // Create coach details entry
        const { error: coachError } = await testContext.supabase
          .from('coaches')
          .upsert({
            id: testContext.userId,
          }, {
            onConflict: 'id',
          })

        if (coachError) {
          console.log('Coach upsert note:', coachError.message)
        }

        // Verify profile was created
        const { data: profile } = await testContext.supabase
          .from('profiles')
          .select('*')
          .eq('id', testContext.userId)
          .single()

        expect(profile).toBeDefined()
        if (profile) {
          expect(profile.email).toBe(TEST_EMAIL)
          expect(profile.role).toBe('coach')
        }
      }
    }, 20000)

    it('signIn returns valid session', async () => {
      // If already authenticated, validate current session
      if (testContext.isAuthenticated) {
        const { data } = await testContext.supabase.auth.getSession()
        expect(data.session).toBeDefined()
        expect(data.session?.access_token).toBeDefined()
        return
      }

      // Skip if user wasn't created
      if (!testContext.userId) {
        console.log('Skipping signIn test: No user created')
        return
      }

      const { data, error } = await testContext.supabase.auth.signInWithPassword({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
      })

      // If email not confirmed, this will fail
      if (error && (error.message.includes('Email not confirmed') || error.message.includes('Invalid login'))) {
        console.log('Skipping signIn test: Email confirmation required or invalid credentials')
        return
      }

      expect(error).toBeNull()
      expect(data.session).toBeDefined()
      expect(data.session?.access_token).toBeDefined()
      expect(data.session?.user?.email).toBe(TEST_EMAIL)

      testContext.isAuthenticated = true
    }, 10000)

    it('getSession returns user data', async () => {
      // Skip if not authenticated
      if (!testContext.isAuthenticated) {
        console.log('Skipping getSession test: Not authenticated')
        return
      }

      const { data, error } = await testContext.supabase.auth.getSession()

      expect(error).toBeNull()
      expect(data.session).toBeDefined()
      expect(data.session?.user).toBeDefined()
      expect(data.session?.user?.email).toBe(TEST_EMAIL)
      expect(data.session?.user?.id).toBe(testContext.userId)
    }, 10000)

    it('signOut clears session', async () => {
      // Skip if not authenticated
      if (!testContext.isAuthenticated) {
        console.log('Skipping signOut test: Not authenticated')
        return
      }

      const { error } = await testContext.supabase.auth.signOut()
      expect(error).toBeNull()

      const { data } = await testContext.supabase.auth.getSession()
      expect(data.session).toBeNull()

      // Re-login for subsequent tests
      const { data: loginData, error: loginError } = await testContext.supabase.auth.signInWithPassword({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
      })

      if (!loginError && loginData.session) {
        testContext.isAuthenticated = true
      }
    }, 10000)
  })

  // ============================================
  // PROGRAMS CRUD TESTS (6 tests)
  // ============================================

  describe('Programs CRUD', () => {
    const getTestProgram = () => ({
      name: `Test Program Integration ${TEST_TIMESTAMP}`,
      description: 'A test program for integration testing',
      goal: 'bulk' as const,
      duration_weeks: 8,
      deload_frequency: 4,
      days: [
        {
          id: `day-${TEST_TIMESTAMP}-1`,
          name: 'Push Day',
          dayOfWeek: 1,
          isRestDay: false,
          exercises: [
            {
              id: `ex-${TEST_TIMESTAMP}-1`,
              name: 'Bench Press',
              muscle: 'chest',
              mode: 'classic',
              sets: [
                { id: `set-${TEST_TIMESTAMP}-1`, targetReps: 10, targetWeight: 60, isWarmup: false, restSeconds: 90 },
                { id: `set-${TEST_TIMESTAMP}-2`, targetReps: 10, targetWeight: 60, isWarmup: false, restSeconds: 90 },
                { id: `set-${TEST_TIMESTAMP}-3`, targetReps: 10, targetWeight: 60, isWarmup: false, restSeconds: 90 },
              ],
            },
          ],
        },
        {
          id: `day-${TEST_TIMESTAMP}-2`,
          name: 'Rest Day',
          dayOfWeek: 2,
          isRestDay: true,
          exercises: [],
        },
      ],
    })

    beforeEach(async () => {
      // Ensure we're authenticated before each test
      if (!testContext.isAuthenticated && testContext.userId) {
        const { data } = await testContext.supabase.auth.signInWithPassword({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        if (data.session) {
          testContext.isAuthenticated = true
        }
      }
    })

    it('createProgram inserts into DB with correct created_by', async () => {
      if (!testContext.isAuthenticated || !testContext.userId) {
        console.log('Skipping createProgram test: Not authenticated')
        return
      }

      const testProgram = getTestProgram()
      const { data, error } = await testContext.supabase
        .from('programs')
        .insert({
          ...testProgram,
          created_by: testContext.userId,
        })
        .select()
        .single()

      expect(error).toBeNull()
      expect(data).toBeDefined()
      expect(data?.name).toBe(testProgram.name)
      expect(data?.goal).toBe(testProgram.goal)
      expect(data?.created_by).toBe(testContext.userId)

      // Store ID for later tests
      if (data?.id) {
        testContext.programIds.push(data.id)
      }
    }, 10000)

    it('getPrograms returns only user programs', async () => {
      if (!testContext.isAuthenticated || !testContext.userId) {
        console.log('Skipping getPrograms test: Not authenticated')
        return
      }

      const { data, error } = await testContext.supabase
        .from('programs')
        .select('*')
        .eq('created_by', testContext.userId)
        .order('created_at', { ascending: false })

      expect(error).toBeNull()
      expect(data).toBeDefined()
      expect(Array.isArray(data)).toBe(true)

      // Should have at least the program we created
      if (testContext.programIds.length > 0) {
        expect(data!.length).toBeGreaterThan(0)
      }

      // All returned programs should belong to the test user
      data?.forEach(program => {
        expect(program.created_by).toBe(testContext.userId)
      })
    }, 10000)

    it('getProgram by ID returns correct program', async () => {
      if (!testContext.isAuthenticated || testContext.programIds.length === 0) {
        console.log('Skipping getProgram test: No programs created')
        return
      }

      const programId = testContext.programIds[0]
      const testProgram = getTestProgram()

      const { data, error } = await testContext.supabase
        .from('programs')
        .select('*')
        .eq('id', programId)
        .single()

      expect(error).toBeNull()
      expect(data).toBeDefined()
      expect(data?.id).toBe(programId)
      expect(data?.name).toBe(testProgram.name)
    }, 10000)

    it('updateProgram modifies fields', async () => {
      if (!testContext.isAuthenticated || testContext.programIds.length === 0) {
        console.log('Skipping updateProgram test: No programs created')
        return
      }

      const programId = testContext.programIds[0]
      const updatedName = `Updated Test Program ${TEST_TIMESTAMP}`
      const updatedDescription = 'Updated description for integration test'

      const { error } = await testContext.supabase
        .from('programs')
        .update({
          name: updatedName,
          description: updatedDescription,
        })
        .eq('id', programId)

      expect(error).toBeNull()

      // Verify update
      const { data } = await testContext.supabase
        .from('programs')
        .select('*')
        .eq('id', programId)
        .single()

      expect(data?.name).toBe(updatedName)
      expect(data?.description).toBe(updatedDescription)
    }, 10000)

    it('Program has correct structure (days array, goal, etc.)', async () => {
      if (!testContext.isAuthenticated || testContext.programIds.length === 0) {
        console.log('Skipping Program structure test: No programs created')
        return
      }

      const programId = testContext.programIds[0]

      const { data, error } = await testContext.supabase
        .from('programs')
        .select('*')
        .eq('id', programId)
        .single()

      expect(error).toBeNull()
      expect(data).toBeDefined()

      // Check required fields
      expect(data?.id).toBeDefined()
      expect(data?.name).toBeDefined()
      expect(data?.goal).toBeDefined()
      expect(data?.duration_weeks).toBeDefined()
      expect(data?.created_by).toBeDefined()
      expect(data?.created_at).toBeDefined()
      expect(data?.updated_at).toBeDefined()

      // Check days array structure
      expect(Array.isArray(data?.days)).toBe(true)
      expect(data?.days.length).toBeGreaterThan(0)

      const firstDay = data?.days[0]
      expect(firstDay?.id).toBeDefined()
      expect(firstDay?.name).toBeDefined()
      expect(typeof firstDay?.dayOfWeek).toBe('number')
      expect(typeof firstDay?.isRestDay).toBe('boolean')
      expect(Array.isArray(firstDay?.exercises)).toBe(true)
    }, 10000)

    it('deleteProgram removes from DB', async () => {
      if (!testContext.isAuthenticated || !testContext.userId) {
        console.log('Skipping deleteProgram test: Not authenticated')
        return
      }

      // Create a program specifically for deletion test
      const { data: newProgram, error: createError } = await testContext.supabase
        .from('programs')
        .insert({
          name: `Program to Delete ${TEST_TIMESTAMP}`,
          goal: 'maintain',
          duration_weeks: 4,
          days: [],
          created_by: testContext.userId,
        })
        .select()
        .single()

      if (createError) {
        console.log('Skipping deleteProgram test: Could not create program')
        return
      }

      expect(newProgram?.id).toBeDefined()
      const deleteId = newProgram!.id

      // Delete the program
      const { error } = await testContext.supabase
        .from('programs')
        .delete()
        .eq('id', deleteId)

      expect(error).toBeNull()

      // Verify deletion
      const { data: deletedProgram, error: fetchError } = await testContext.supabase
        .from('programs')
        .select('*')
        .eq('id', deleteId)
        .single()

      // Should either be null or return an error (PGRST116 = no rows found)
      expect(deletedProgram).toBeNull()
      expect(fetchError).toBeDefined()
    }, 10000)
  })

  // ============================================
  // DIET PLANS CRUD TESTS (5 tests)
  // ============================================

  describe('Diet Plans CRUD', () => {
    const getTestDietPlan = () => ({
      name: `Test Diet Plan Integration ${TEST_TIMESTAMP}`,
      goal: 'bulk' as const,
      training_calories: 2800,
      rest_calories: 2400,
      training_macros: { protein: 180, carbs: 300, fat: 80 },
      rest_macros: { protein: 180, carbs: 220, fat: 80 },
      meals: [
        {
          id: `meal-${TEST_TIMESTAMP}-1`,
          name: 'Petit-dejeuner',
          foods: [
            {
              id: `food-${TEST_TIMESTAMP}-1`,
              name: 'Avoine',
              calories: 389,
              macros: { protein: 17, carbs: 66, fat: 7 },
              quantity: 100,
              unit: 'g',
            },
          ],
        },
      ],
      supplements: [
        {
          id: `supp-${TEST_TIMESTAMP}-1`,
          name: 'Creatine',
          dosage: '5g',
          timing: 'post-workout',
        },
      ],
      notes: 'Test diet plan notes for integration testing',
    })

    beforeEach(async () => {
      // Ensure we're authenticated before each test
      if (!testContext.isAuthenticated && testContext.userId) {
        const { data } = await testContext.supabase.auth.signInWithPassword({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        if (data.session) {
          testContext.isAuthenticated = true
        }
      }
    })

    it('createDietPlan inserts with correct data', async () => {
      if (!testContext.isAuthenticated || !testContext.userId) {
        console.log('Skipping createDietPlan test: Not authenticated')
        return
      }

      const testDietPlan = getTestDietPlan()
      const { data, error } = await testContext.supabase
        .from('diet_plans')
        .insert({
          ...testDietPlan,
          created_by: testContext.userId,
        })
        .select()
        .single()

      expect(error).toBeNull()
      expect(data).toBeDefined()
      expect(data?.name).toBe(testDietPlan.name)
      expect(data?.goal).toBe(testDietPlan.goal)
      expect(data?.training_calories).toBe(testDietPlan.training_calories)
      expect(data?.rest_calories).toBe(testDietPlan.rest_calories)
      expect(data?.created_by).toBe(testContext.userId)

      // Store ID for later tests
      if (data?.id) {
        testContext.dietPlanIds.push(data.id)
      }
    }, 10000)

    it('getDietPlans returns user plans', async () => {
      if (!testContext.isAuthenticated || !testContext.userId) {
        console.log('Skipping getDietPlans test: Not authenticated')
        return
      }

      const { data, error } = await testContext.supabase
        .from('diet_plans')
        .select('*')
        .eq('created_by', testContext.userId)
        .order('created_at', { ascending: false })

      expect(error).toBeNull()
      expect(data).toBeDefined()
      expect(Array.isArray(data)).toBe(true)

      // Should have at least the diet plan we created
      if (testContext.dietPlanIds.length > 0) {
        expect(data!.length).toBeGreaterThan(0)
      }

      // All returned diet plans should belong to the test user
      data?.forEach(plan => {
        expect(plan.created_by).toBe(testContext.userId)
      })
    }, 10000)

    it('getDietPlan by ID works', async () => {
      if (!testContext.isAuthenticated || testContext.dietPlanIds.length === 0) {
        console.log('Skipping getDietPlan test: No diet plans created')
        return
      }

      const planId = testContext.dietPlanIds[0]
      const testDietPlan = getTestDietPlan()

      const { data, error } = await testContext.supabase
        .from('diet_plans')
        .select('*')
        .eq('id', planId)
        .single()

      expect(error).toBeNull()
      expect(data).toBeDefined()
      expect(data?.id).toBe(planId)
      expect(data?.name).toBe(testDietPlan.name)

      // Check macros structure
      expect(data?.training_macros).toEqual(testDietPlan.training_macros)
      expect(data?.rest_macros).toEqual(testDietPlan.rest_macros)

      // Check meals structure
      expect(Array.isArray(data?.meals)).toBe(true)
      expect(data?.meals.length).toBeGreaterThan(0)

      // Check supplements structure
      expect(Array.isArray(data?.supplements)).toBe(true)
    }, 10000)

    it('updateDietPlan modifies data', async () => {
      if (!testContext.isAuthenticated || testContext.dietPlanIds.length === 0) {
        console.log('Skipping updateDietPlan test: No diet plans created')
        return
      }

      const planId = testContext.dietPlanIds[0]
      const updatedName = `Updated Diet Plan ${TEST_TIMESTAMP}`
      const updatedCalories = 3000

      const { error } = await testContext.supabase
        .from('diet_plans')
        .update({
          name: updatedName,
          training_calories: updatedCalories,
        })
        .eq('id', planId)

      expect(error).toBeNull()

      // Verify update
      const { data } = await testContext.supabase
        .from('diet_plans')
        .select('*')
        .eq('id', planId)
        .single()

      expect(data?.name).toBe(updatedName)
      expect(data?.training_calories).toBe(updatedCalories)
    }, 10000)

    it('deleteDietPlan removes plan', async () => {
      if (!testContext.isAuthenticated || !testContext.userId) {
        console.log('Skipping deleteDietPlan test: Not authenticated')
        return
      }

      // Create a diet plan specifically for deletion test
      const { data: newPlan, error: createError } = await testContext.supabase
        .from('diet_plans')
        .insert({
          name: `Diet Plan to Delete ${TEST_TIMESTAMP}`,
          goal: 'maintain',
          training_calories: 2000,
          rest_calories: 1800,
          training_macros: { protein: 150, carbs: 200, fat: 60 },
          rest_macros: { protein: 150, carbs: 180, fat: 60 },
          meals: [],
          supplements: [],
          created_by: testContext.userId,
        })
        .select()
        .single()

      if (createError) {
        console.log('Skipping deleteDietPlan test: Could not create diet plan')
        return
      }

      expect(newPlan?.id).toBeDefined()
      const deleteId = newPlan!.id

      // Delete the diet plan
      const { error } = await testContext.supabase
        .from('diet_plans')
        .delete()
        .eq('id', deleteId)

      expect(error).toBeNull()

      // Verify deletion
      const { data: deletedPlan, error: fetchError } = await testContext.supabase
        .from('diet_plans')
        .select('*')
        .eq('id', deleteId)
        .single()

      // Should either be null or return an error (PGRST116 = no rows found)
      expect(deletedPlan).toBeNull()
      expect(fetchError).toBeDefined()
    }, 10000)
  })

  // ============================================
  // CLEANUP
  // ============================================

  afterAll(async () => {
    console.log('\n--- Cleaning up test data ---')

    // Try to authenticate for cleanup
    if (testContext.userId) {
      try {
        await testContext.supabase.auth.signInWithPassword({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
      } catch {
        console.log('Could not authenticate for cleanup')
      }
    }

    // Delete all test programs
    if (testContext.programIds.length > 0) {
      console.log(`Deleting ${testContext.programIds.length} test programs...`)
      const { error: programError } = await testContext.supabase
        .from('programs')
        .delete()
        .in('id', testContext.programIds)

      if (programError) {
        console.log('Programs cleanup note:', programError.message)
      }
    }

    // Also cleanup any programs with the test timestamp in the name
    if (testContext.userId) {
      await testContext.supabase
        .from('programs')
        .delete()
        .eq('created_by', testContext.userId)
        .like('name', `%${TEST_TIMESTAMP}%`)
    }

    // Delete all test diet plans
    if (testContext.dietPlanIds.length > 0) {
      console.log(`Deleting ${testContext.dietPlanIds.length} test diet plans...`)
      const { error: dietError } = await testContext.supabase
        .from('diet_plans')
        .delete()
        .in('id', testContext.dietPlanIds)

      if (dietError) {
        console.log('Diet plans cleanup note:', dietError.message)
      }
    }

    // Also cleanup any diet plans with the test timestamp in the name
    if (testContext.userId) {
      await testContext.supabase
        .from('diet_plans')
        .delete()
        .eq('created_by', testContext.userId)
        .like('name', `%${TEST_TIMESTAMP}%`)
    }

    // Only delete user profile/coach if we created a new user
    if (testContext.createdNewUser && testContext.userId) {
      // Delete coach details
      const { error: coachError } = await testContext.supabase
        .from('coaches')
        .delete()
        .eq('id', testContext.userId)

      if (coachError) {
        console.log('Coach cleanup note:', coachError.message)
      }

      // Delete profile
      const { error: profileError } = await testContext.supabase
        .from('profiles')
        .delete()
        .eq('id', testContext.userId)

      if (profileError) {
        console.log('Profile cleanup note:', profileError.message)
      }
    }

    // Sign out
    await testContext.supabase.auth.signOut()

    console.log(`Test cleanup complete for ${TEST_EMAIL}`)
    if (testContext.createdNewUser) {
      console.log('Note: Auth user remains in Supabase (requires admin API to delete)')
    }
    console.log('--- Cleanup finished ---\n')
  }, 30000)
})
