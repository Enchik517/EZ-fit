-- Add warmUp and coolDown fields to workouts table
ALTER TABLE public.workouts
ADD COLUMN warm_up TEXT,
ADD COLUMN cool_down TEXT; 