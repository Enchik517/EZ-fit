-- Drop existing tables if they exist
DROP TABLE IF EXISTS public.workout_logs CASCADE;
DROP TABLE IF EXISTS public.completed_workouts CASCADE;
DROP TABLE IF EXISTS public.scheduled_workouts CASCADE;
DROP TABLE IF EXISTS public.workouts CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;

-- Create workouts table
CREATE TABLE IF NOT EXISTS public.workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    name TEXT NOT NULL,
    description TEXT,
    difficulty TEXT,
    category TEXT,
    focus TEXT,
    duration INTEGER,
    exercises JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- Create workout_logs table
CREATE TABLE IF NOT EXISTS public.workout_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    workout_name TEXT NOT NULL,
    workout_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL,
    exercises JSONB NOT NULL,
    notes TEXT,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- Create completed_workouts table
CREATE TABLE IF NOT EXISTS public.completed_workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    date TEXT NOT NULL,
    workout_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
    UNIQUE(user_id, date, workout_name)
);

-- Create scheduled_workouts table
CREATE TABLE IF NOT EXISTS public.scheduled_workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    workout JSONB NOT NULL,
    date TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
    UNIQUE(user_id, date)
);

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    full_name TEXT,
    age INTEGER,
    gender TEXT,
    height DECIMAL,
    weight DECIMAL,
    fitness_level TEXT,
    weekly_workouts INTEGER,
    workout_duration INTEGER,
    goals TEXT[],
    equipment TEXT[],
    injuries TEXT[],
    has_completed_survey BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- Add RLS policies
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completed_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Policies for workouts
CREATE POLICY "Users can view their own workouts"
    ON public.workouts FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workouts"
    ON public.workouts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policies for workout_logs
CREATE POLICY "Users can view their own workout logs"
    ON public.workout_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout logs"
    ON public.workout_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policies for completed_workouts
CREATE POLICY "Users can view their own completed workouts"
    ON public.completed_workouts FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own completed workouts"
    ON public.completed_workouts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policies for scheduled_workouts
CREATE POLICY "Users can view their own scheduled workouts"
    ON public.scheduled_workouts FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own scheduled workouts"
    ON public.scheduled_workouts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policies for user_profiles
CREATE POLICY "Users can view their own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id); 