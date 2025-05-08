-- Drop the table if it exists
DROP TABLE IF EXISTS public.debug_logs;

-- Create the debug_logs table
CREATE TABLE public.debug_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.debug_logs ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all access
CREATE POLICY "Enable all access to debug_logs"
    ON public.debug_logs FOR ALL
    USING (true);

-- Create index for faster querying
CREATE INDEX debug_logs_user_id_idx ON public.debug_logs(user_id);
CREATE INDEX debug_logs_action_idx ON public.debug_logs(action);
CREATE INDEX debug_logs_created_at_idx ON public.debug_logs(created_at);

-- Create a function to log actions
CREATE OR REPLACE FUNCTION log_debug_action(
    p_user_id UUID,
    p_action TEXT,
    p_details JSONB
) RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO public.debug_logs (user_id, action, details)
    VALUES (p_user_id, p_action, p_details)
    RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create helper views to analyze common issues

-- View for workout history logging
CREATE OR REPLACE VIEW debug_workout_history_logs AS
SELECT *
FROM public.debug_logs
WHERE action LIKE 'workout_history%'
ORDER BY created_at DESC;

-- View for favorite workouts logging
CREATE OR REPLACE VIEW debug_favorite_workout_logs AS
SELECT *
FROM public.debug_logs
WHERE action LIKE 'favorite_workout%'
ORDER BY created_at DESC;

-- Check for duplicate entries in workout history
CREATE OR REPLACE VIEW duplicate_workout_history AS
SELECT 
    user_id, 
    workout_id, 
    COUNT(*) as entry_count
FROM public.workout_history
GROUP BY user_id, workout_id
HAVING COUNT(*) > 1;

-- Check for duplicate entries in favorite workouts
CREATE OR REPLACE VIEW duplicate_favorite_workouts AS
SELECT 
    user_id, 
    workout_id, 
    COUNT(*) as entry_count
FROM public.favorite_workouts
GROUP BY user_id, workout_id
HAVING COUNT(*) > 1; 