-- Add cascade delete for messages table
ALTER TABLE IF EXISTS public.messages
    DROP CONSTRAINT IF EXISTS messages_user_id_fkey,
    ADD CONSTRAINT messages_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE; 