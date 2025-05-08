-- Update user_profiles table structure
DROP TABLE IF EXISTS public.user_profiles CASCADE;

CREATE TABLE public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name TEXT NOT NULL,
  birth_date TIMESTAMPTZ NOT NULL,
  gender TEXT NOT NULL,
  height DECIMAL NOT NULL,
  weight DECIMAL NOT NULL,
  fitness_level TEXT NOT NULL,
  weekly_workouts TEXT NOT NULL,
  workout_duration TEXT NOT NULL,
  goals TEXT[] NOT NULL,
  equipment TEXT[] NOT NULL,
  injuries TEXT[],
  has_completed_survey BOOLEAN DEFAULT false,
  sync_with_health BOOLEAN DEFAULT false,
  notes TEXT,
  username TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for commonly queried fields
CREATE INDEX idx_user_profiles_username ON public.user_profiles(username);
CREATE INDEX idx_user_profiles_fitness_level ON public.user_profiles(fitness_level);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON public.user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Add new columns to user_profiles table
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS medical_conditions text[],
ADD COLUMN IF NOT EXISTS activity_limitations text[],
ADD COLUMN IF NOT EXISTS injury_details jsonb,
ADD COLUMN IF NOT EXISTS body_fat_percentage decimal,
ADD COLUMN IF NOT EXISTS strength_levels jsonb,
ADD COLUMN IF NOT EXISTS preferred_exercises text[],
ADD COLUMN IF NOT EXISTS excluded_exercises text[],
ADD COLUMN IF NOT EXISTS recovery_capacity text DEFAULT 'средняя',
ADD COLUMN IF NOT EXISTS pain_areas jsonb,
ADD COLUMN IF NOT EXISTS previous_surgeries text[],
ADD COLUMN IF NOT EXISTS measurement_history jsonb,
ADD COLUMN IF NOT EXISTS stress_level text DEFAULT 'средний',
ADD COLUMN IF NOT EXISTS sleep_quality text DEFAULT 'среднее',
ADD COLUMN IF NOT EXISTS average_sleep_hours integer DEFAULT 7,
ADD COLUMN IF NOT EXISTS energy_level text DEFAULT 'средний',
ADD COLUMN IF NOT EXISTS nutritional_preferences text[],
ADD COLUMN IF NOT EXISTS allergies text[],
ADD COLUMN IF NOT EXISTS mobility_issues jsonb;

-- Add comments for better documentation
COMMENT ON COLUMN public.user_profiles.injury_details IS 'Detailed information about injuries, e.g. {"колено": "травма мениска"}';
COMMENT ON COLUMN public.user_profiles.strength_levels IS 'Current strength levels for exercises, e.g. {"жим": 80, "присед": 100}';
COMMENT ON COLUMN public.user_profiles.pain_areas IS 'Areas of pain and their descriptions';
COMMENT ON COLUMN public.user_profiles.measurement_history IS 'History of various measurements over time';
COMMENT ON COLUMN public.user_profiles.mobility_issues IS 'Mobility limitations for different body parts';

-- Create indexes for commonly queried fields
CREATE INDEX IF NOT EXISTS idx_user_profiles_fitness_level ON public.user_profiles(fitness_level);
CREATE INDEX IF NOT EXISTS idx_user_profiles_recovery_capacity ON public.user_profiles(recovery_capacity);
CREATE INDEX IF NOT EXISTS idx_user_profiles_stress_level ON public.user_profiles(stress_level);
CREATE INDEX IF NOT EXISTS idx_user_profiles_sleep_quality ON public.user_profiles(sleep_quality);
CREATE INDEX IF NOT EXISTS idx_user_profiles_energy_level ON public.user_profiles(energy_level);
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON public.user_profiles(username); 