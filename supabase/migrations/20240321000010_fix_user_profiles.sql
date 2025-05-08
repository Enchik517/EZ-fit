-- Drop existing table and its dependencies
DROP TABLE IF EXISTS public.user_profiles CASCADE;

-- Create user_profiles table with correct structure
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

-- Create indexes
CREATE INDEX idx_user_profiles_fitness_level ON public.user_profiles(fitness_level);
CREATE INDEX idx_user_profiles_username ON public.user_profiles(username); 