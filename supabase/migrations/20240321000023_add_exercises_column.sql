-- Drop existing exercises column if exists
ALTER TABLE workouts DROP COLUMN IF EXISTS exercises;

-- Add exercises column as JSONB
ALTER TABLE workouts ADD COLUMN exercises JSONB DEFAULT '[]'::jsonb;

-- Add constraint to ensure exercises is an array
ALTER TABLE workouts 
ADD CONSTRAINT workouts_exercises_check 
CHECK (jsonb_typeof(exercises) = 'array');

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_workouts_exercises ON workouts USING GIN (exercises); 