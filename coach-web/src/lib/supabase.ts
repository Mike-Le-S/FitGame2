import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Type for the profile from database
export interface Profile {
  id: string
  email: string
  full_name: string
  avatar_url: string | null
  role: 'athlete' | 'coach'
  coach_id: string | null
  total_sessions: number
  current_streak: number
  weight_unit: 'kg' | 'lbs'
  language: 'fr' | 'en'
  goal?: 'lose' | 'maintain' | 'gain' | 'bulk' | 'cut' | 'performance'
  notifications_enabled: boolean
  created_at: string
  updated_at: string
}

// Type for the coach details from database
export interface CoachDetails {
  id: string
  business_name: string | null
  specialization: string | null
  credentials: string | null
  two_factor_enabled: boolean
  theme: 'dark' | 'light' | 'auto'
  accent_color: string
  created_at: string
  updated_at: string
}
