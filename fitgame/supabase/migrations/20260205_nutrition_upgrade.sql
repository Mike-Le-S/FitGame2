-- ============================================
-- Nutrition Upgrade Migration
-- ============================================

-- 1. Daily nutrition logs (tracking what user actually ate)
CREATE TABLE IF NOT EXISTS daily_nutrition_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  date DATE NOT NULL,
  diet_plan_id UUID REFERENCES diet_plans ON DELETE SET NULL,
  meals JSONB NOT NULL DEFAULT '[]',
  calories_consumed INT DEFAULT 0,
  calories_burned INT,
  calories_burned_predicted INT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- 2. User favorite foods
CREATE TABLE IF NOT EXISTS user_favorite_foods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  food_data JSONB NOT NULL,
  use_count INT DEFAULT 1,
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Meal templates (saved meals for quick adding)
CREATE TABLE IF NOT EXISTS meal_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  name VARCHAR(100) NOT NULL,
  foods JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Community foods (crowdsourced nutrition data)
CREATE TABLE IF NOT EXISTS community_foods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  barcode VARCHAR(50) UNIQUE,
  name VARCHAR(200) NOT NULL,
  brand VARCHAR(100),
  nutrition_per_100g JSONB NOT NULL,
  image_url TEXT,
  contributed_by UUID REFERENCES auth.users,
  verified BOOLEAN DEFAULT FALSE,
  use_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- Row Level Security
-- ============================================

ALTER TABLE daily_nutrition_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorite_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_foods ENABLE ROW LEVEL SECURITY;

-- Daily nutrition logs: users access own data only
CREATE POLICY "Users can select own nutrition logs" ON daily_nutrition_logs
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own nutrition logs" ON daily_nutrition_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own nutrition logs" ON daily_nutrition_logs
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own nutrition logs" ON daily_nutrition_logs
  FOR DELETE USING (auth.uid() = user_id);

-- Favorite foods: users access own data only
CREATE POLICY "Users can select own favorite foods" ON user_favorite_foods
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own favorite foods" ON user_favorite_foods
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own favorite foods" ON user_favorite_foods
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own favorite foods" ON user_favorite_foods
  FOR DELETE USING (auth.uid() = user_id);

-- Meal templates: users access own data only
CREATE POLICY "Users can select own meal templates" ON meal_templates
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own meal templates" ON meal_templates
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own meal templates" ON meal_templates
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own meal templates" ON meal_templates
  FOR DELETE USING (auth.uid() = user_id);

-- Community foods: everyone reads, authenticated users insert
CREATE POLICY "Anyone can read community foods" ON community_foods
  FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert community foods" ON community_foods
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Contributors can update own community foods" ON community_foods
  FOR UPDATE USING (auth.uid() = contributed_by);

-- ============================================
-- Indexes for performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_daily_nutrition_logs_user_date
  ON daily_nutrition_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_user_favorite_foods_user
  ON user_favorite_foods(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_templates_user
  ON meal_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_community_foods_barcode
  ON community_foods(barcode);
