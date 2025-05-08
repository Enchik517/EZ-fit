ALTER TABLE public.user_profiles
ADD COLUMN workout_streak INTEGER DEFAULT 0,
ADD COLUMN last_workout_date DATE; 