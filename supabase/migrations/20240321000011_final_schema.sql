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

-- Create tables
CREATE TABLE public.user_profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  full_name text,
  birth_date timestamptz,
  age integer,
  gender text,
  height decimal,
  weight decimal,
  fitness_level text,
  weekly_workouts text,
  workout_duration text,
  goals text[],
  equipment text[],
  injuries text[],
  has_completed_survey boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.exercises (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  muscle_group text NOT NULL,
  equipment text[],
  difficulty text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE public.workout_logs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  workout_date date NOT NULL,
  workout_name text NOT NULL,
  exercises jsonb NOT NULL,
  duration interval NOT NULL,
  notes text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE public.workouts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  difficulty text,
  category text,
  focus text,
  duration integer,
  exercises jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.scheduled_workouts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  workout jsonb NOT NULL,
  date text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, date)
);

CREATE TABLE public.completed_workouts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  date text NOT NULL,
  workout_name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, date, workout_name)
);

CREATE TABLE public.chat_messages (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  content text NOT NULL,
  is_user boolean DEFAULT true,
  image_url text,
  chat_id text DEFAULT 'default',
  status text DEFAULT 'sent' CHECK (status IN ('sent', 'processing', 'completed', 'error')),
  error_message text,
  ai_response_id text,
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  processed_at timestamptz
);

-- Create basic policies for all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completed_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all" ON public.user_profiles FOR ALL USING (true);
CREATE POLICY "Allow all" ON public.exercises FOR ALL USING (true);
CREATE POLICY "Allow all" ON public.workout_logs FOR ALL USING (true);
CREATE POLICY "Allow all" ON public.workouts FOR ALL USING (true);
CREATE POLICY "Allow all" ON public.scheduled_workouts FOR ALL USING (true);
CREATE POLICY "Allow all" ON public.completed_workouts FOR ALL USING (true);
CREATE POLICY "Allow all" ON public.chat_messages FOR ALL USING (true);

-- Create indexes
CREATE INDEX idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX idx_workout_logs_user_id ON public.workout_logs(user_id);
CREATE INDEX idx_workout_logs_date ON public.workout_logs(workout_date);
CREATE INDEX idx_exercises_muscle_group ON public.exercises(muscle_group);
CREATE INDEX idx_chat_messages_user_id ON public.chat_messages(user_id);
CREATE INDEX idx_chat_messages_chat_id ON public.chat_messages(chat_id);
CREATE INDEX idx_chat_messages_created_at ON public.chat_messages(created_at);
CREATE INDEX idx_chat_messages_status ON public.chat_messages(status);

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