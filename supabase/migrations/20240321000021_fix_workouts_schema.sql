-- Add missing columns to workouts table
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS equipment text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS target_muscles text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS focus text DEFAULT '',
ADD COLUMN IF NOT EXISTS duration integer DEFAULT 0;

-- Fix completed_workouts table
DELETE FROM completed_workouts a USING completed_workouts b
WHERE a.id > b.id 
AND a.user_id = b.user_id 
AND a.date = b.date 
AND a.workout_name = b.workout_name; 