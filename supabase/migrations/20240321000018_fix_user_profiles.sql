-- Drop existing table
DROP TABLE IF EXISTS public.user_profiles CASCADE;

-- Create user_profiles table with correct structure
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    full_name TEXT NOT NULL,
    birth_date TIMESTAMPTZ NOT NULL,
    gender TEXT NOT NULL DEFAULT 'not specified',
    height DECIMAL NOT NULL DEFAULT 170,
    weight DECIMAL NOT NULL DEFAULT 70,
    fitness_level TEXT NOT NULL DEFAULT 'beginner',
    weekly_workouts TEXT NOT NULL DEFAULT '3-4',
    workout_duration TEXT NOT NULL DEFAULT '30-45',
    goals TEXT[] NOT NULL DEFAULT ARRAY['general fitness'],
    equipment TEXT[] NOT NULL DEFAULT ARRAY['none'],
    injuries TEXT[],
    has_completed_survey BOOLEAN DEFAULT false,
    sync_with_health BOOLEAN DEFAULT false,
    notes TEXT,
    username TEXT,
    avatar_url TEXT,
    workout_streak INTEGER DEFAULT 0,
    last_workout_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Enable insert for registration"
    ON public.user_profiles FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Enable select for own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Enable update for own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Enable delete for own profile"
    ON public.user_profiles FOR DELETE
    USING (auth.uid() = id);

-- Create indexes
CREATE INDEX idx_user_profiles_fitness_level ON public.user_profiles(fitness_level); 