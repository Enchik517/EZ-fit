-- Drop existing table
DROP TABLE IF EXISTS public.workouts CASCADE;

-- Recreate workouts table with correct structure
CREATE TABLE public.workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    difficulty TEXT,
    category TEXT,
    focus TEXT,
    duration INTEGER,
    equipment TEXT[],
    exercises JSONB,
    target_muscles TEXT[],
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Enable user access to own workouts"
    ON public.workouts FOR ALL
    USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX idx_workouts_user_id ON public.workouts(user_id);
CREATE INDEX idx_workouts_focus ON public.workouts(focus);
CREATE INDEX idx_workouts_difficulty ON public.workouts(difficulty); 