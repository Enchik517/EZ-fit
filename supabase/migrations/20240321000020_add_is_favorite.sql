-- Add is_favorite column to workouts table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'workouts' 
        AND column_name = 'is_favorite'
    ) THEN
        ALTER TABLE public.workouts 
        ADD COLUMN is_favorite BOOLEAN DEFAULT false;
    END IF;
END $$; 