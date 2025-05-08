-- Add is_completed column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'workout_logs' 
        AND column_name = 'is_completed'
    ) THEN
        ALTER TABLE public.workout_logs 
        ADD COLUMN is_completed BOOLEAN DEFAULT false;
    END IF;
END $$; 