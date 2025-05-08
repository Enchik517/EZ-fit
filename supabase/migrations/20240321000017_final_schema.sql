-- Drop existing tables
DROP TABLE IF EXISTS public.chat_messages CASCADE;
DROP TABLE IF EXISTS public.completed_workouts CASCADE;
DROP TABLE IF EXISTS public.scheduled_workouts CASCADE;
DROP TABLE IF EXISTS public.workouts CASCADE;
DROP TABLE IF EXISTS public.workout_logs CASCADE;
DROP TABLE IF EXISTS public.exercises CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables if they don't exist
DO $$ 
BEGIN
    -- Create user_profiles table
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'user_profiles') THEN
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
            created_at TIMESTAMPTZ DEFAULT now(),
            updated_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    -- Create exercises table
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'exercises') THEN
        CREATE TABLE public.exercises (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name TEXT NOT NULL,
            description TEXT,
            muscle_group TEXT NOT NULL,
            equipment TEXT[],
            difficulty TEXT NOT NULL,
            created_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    -- Create workout_logs table
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'workout_logs') THEN
        CREATE TABLE public.workout_logs (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            workout_date DATE NOT NULL,
            workout_name TEXT NOT NULL,
            exercises JSONB NOT NULL,
            duration INTERVAL NOT NULL,
            notes TEXT,
            created_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    -- Create workouts table
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'workouts') THEN
        CREATE TABLE public.workouts (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            description TEXT,
            difficulty TEXT,
            category TEXT,
            focus TEXT,
            duration INTEGER,
            exercises JSONB,
            is_favorite BOOLEAN DEFAULT false,
            created_at TIMESTAMPTZ DEFAULT now(),
            updated_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    -- Create scheduled_workouts table
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'scheduled_workouts') THEN
        CREATE TABLE public.scheduled_workouts (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            workout JSONB NOT NULL,
            date TEXT NOT NULL,
            created_at TIMESTAMPTZ DEFAULT now(),
            UNIQUE(user_id, date)
        );
    END IF;

    -- Create completed_workouts table
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'completed_workouts') THEN
        CREATE TABLE public.completed_workouts (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            date TEXT NOT NULL,
            workout_name TEXT NOT NULL,
            created_at TIMESTAMPTZ DEFAULT now(),
            UNIQUE(user_id, date, workout_name)
        );
    END IF;

    -- Create chat_messages table
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'chat_messages') THEN
        CREATE TABLE public.chat_messages (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            content TEXT NOT NULL,
            is_user BOOLEAN DEFAULT true,
            image_url TEXT,
            chat_id TEXT DEFAULT 'default',
            status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'processing', 'completed', 'error')),
            error_message TEXT,
            metadata JSONB,
            created_at TIMESTAMPTZ DEFAULT now(),
            updated_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;
END $$;

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completed_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Create policies for user_profiles
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_profiles' AND policyname = 'Enable insert for registration'
    ) THEN
        CREATE POLICY "Enable insert for registration"
            ON public.user_profiles FOR INSERT
            WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_profiles' AND policyname = 'Enable select for own profile'
    ) THEN
        CREATE POLICY "Enable select for own profile"
            ON public.user_profiles FOR SELECT
            USING (auth.uid() = id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_profiles' AND policyname = 'Enable update for own profile'
    ) THEN
        CREATE POLICY "Enable update for own profile"
            ON public.user_profiles FOR UPDATE
            USING (auth.uid() = id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_profiles' AND policyname = 'Enable delete for own profile'
    ) THEN
        CREATE POLICY "Enable delete for own profile"
            ON public.user_profiles FOR DELETE
            USING (auth.uid() = id);
    END IF;
END $$;

-- Create policies for other tables
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'exercises' AND policyname = 'Enable all for exercises'
    ) THEN
        CREATE POLICY "Enable all for exercises"
            ON public.exercises FOR ALL
            USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'workout_logs' AND policyname = 'Enable user access to own workout_logs'
    ) THEN
        CREATE POLICY "Enable user access to own workout_logs"
            ON public.workout_logs FOR ALL
            USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'workouts' AND policyname = 'Enable user access to own workouts'
    ) THEN
        CREATE POLICY "Enable user access to own workouts"
            ON public.workouts FOR ALL
            USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scheduled_workouts' AND policyname = 'Enable user access to own scheduled_workouts'
    ) THEN
        CREATE POLICY "Enable user access to own scheduled_workouts"
            ON public.scheduled_workouts FOR ALL
            USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'completed_workouts' AND policyname = 'Enable user access to own completed_workouts'
    ) THEN
        CREATE POLICY "Enable user access to own completed_workouts"
            ON public.completed_workouts FOR ALL
            USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'chat_messages' AND policyname = 'Enable user access to own chat_messages'
    ) THEN
        CREATE POLICY "Enable user access to own chat_messages"
            ON public.chat_messages FOR ALL
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- Create indexes
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_user_profiles_fitness_level') THEN
        CREATE INDEX idx_user_profiles_fitness_level ON public.user_profiles(fitness_level);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_workout_logs_user_id') THEN
        CREATE INDEX idx_workout_logs_user_id ON public.workout_logs(user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_workout_logs_date') THEN
        CREATE INDEX idx_workout_logs_date ON public.workout_logs(workout_date);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_exercises_muscle_group') THEN
        CREATE INDEX idx_exercises_muscle_group ON public.exercises(muscle_group);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_workouts_user_id') THEN
        CREATE INDEX idx_workouts_user_id ON public.workouts(user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_scheduled_workouts_user_id') THEN
        CREATE INDEX idx_scheduled_workouts_user_id ON public.scheduled_workouts(user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_completed_workouts_user_id') THEN
        CREATE INDEX idx_completed_workouts_user_id ON public.completed_workouts(user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_messages_user_id') THEN
        CREATE INDEX idx_chat_messages_user_id ON public.chat_messages(user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_messages_chat_id') THEN
        CREATE INDEX idx_chat_messages_chat_id ON public.chat_messages(chat_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_messages_created_at') THEN
        CREATE INDEX idx_chat_messages_created_at ON public.chat_messages(created_at);
    END IF;
END $$;

-- Create user deletion function
CREATE OR REPLACE FUNCTION delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

-- Grant access to function
GRANT EXECUTE ON FUNCTION delete_user() TO authenticated; 