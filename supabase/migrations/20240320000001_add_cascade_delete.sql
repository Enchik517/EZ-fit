-- Добавляем каскадное удаление для всех таблиц
ALTER TABLE public.completed_workouts
    DROP CONSTRAINT IF EXISTS completed_workouts_user_id_fkey,
    ADD CONSTRAINT completed_workouts_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

ALTER TABLE public.workout_logs
    DROP CONSTRAINT IF EXISTS workout_logs_user_id_fkey,
    ADD CONSTRAINT workout_logs_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

ALTER TABLE public.workouts
    DROP CONSTRAINT IF EXISTS workouts_user_id_fkey,
    ADD CONSTRAINT workouts_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

ALTER TABLE public.scheduled_workouts
    DROP CONSTRAINT IF EXISTS scheduled_workouts_user_id_fkey,
    ADD CONSTRAINT scheduled_workouts_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

ALTER TABLE public.user_profiles
    DROP CONSTRAINT IF EXISTS user_profiles_id_fkey,
    ADD CONSTRAINT user_profiles_id_fkey 
    FOREIGN KEY (id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE; 