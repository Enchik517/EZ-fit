-- Drop existing messages table if exists
DROP TABLE IF EXISTS public.messages;

-- Create messages table with correct schema
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    content TEXT NOT NULL,
    is_user BOOLEAN DEFAULT true,
    image_url TEXT,
    chat_id TEXT DEFAULT 'default',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add RLS policies
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Users can view their own messages
CREATE POLICY "Users can view their own messages"
    ON public.messages FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own messages
CREATE POLICY "Users can insert their own messages"
    ON public.messages FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own messages
CREATE POLICY "Users can update their own messages"
    ON public.messages FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own messages
CREATE POLICY "Users can delete their own messages"
    ON public.messages FOR DELETE
    USING (auth.uid() = user_id);

-- Add indexes
CREATE INDEX messages_user_id_idx ON public.messages(user_id);
CREATE INDEX messages_chat_id_idx ON public.messages(chat_id);
CREATE INDEX messages_created_at_idx ON public.messages(created_at); 