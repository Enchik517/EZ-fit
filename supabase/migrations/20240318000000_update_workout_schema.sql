-- Update workouts table
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS target_muscle_group text,
ADD COLUMN IF NOT EXISTS cool_down text DEFAULT '',
ADD COLUMN IF NOT EXISTS warm_up text DEFAULT '';

-- Update workout_logs table
ALTER TABLE workout_logs
DROP COLUMN IF EXISTS end_time,
ALTER COLUMN exercises TYPE jsonb USING exercises::jsonb,
ALTER COLUMN exercises SET DEFAULT '[]'::jsonb;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_workout_logs_workout_date ON workout_logs(workout_date);
CREATE INDEX IF NOT EXISTS idx_workout_logs_user_id ON workout_logs(user_id);

-- Add constraints
ALTER TABLE workout_logs
ADD CONSTRAINT workout_logs_exercises_check 
CHECK (jsonb_typeof(exercises) = 'array');

-- Update completed_workouts table
CREATE TABLE IF NOT EXISTS completed_workouts (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    date text NOT NULL,
    workout_name text NOT NULL,
    created_at timestamptz DEFAULT now(),
    UNIQUE(user_id, date, workout_name)
);

-- Create indexes for completed_workouts
CREATE INDEX IF NOT EXISTS idx_completed_workouts_user_id ON completed_workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_completed_workouts_date ON completed_workouts(date); 