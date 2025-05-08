-- Check if messages table exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'messages'
    ) THEN
        -- Create messages table if it doesn't exist
        CREATE TABLE public.messages (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id),
            content TEXT,
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
        CREATE INDEX IF NOT EXISTS messages_user_id_idx ON public.messages(user_id);
        CREATE INDEX IF NOT EXISTS messages_chat_id_idx ON public.messages(chat_id);
        CREATE INDEX IF NOT EXISTS messages_created_at_idx ON public.messages(created_at);
    ELSE
        -- Check and fix RLS policies
        ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

        -- Drop existing policies if they exist
        DROP POLICY IF EXISTS "Users can view their own messages" ON public.messages;
        DROP POLICY IF EXISTS "Users can insert their own messages" ON public.messages;
        DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;
        DROP POLICY IF EXISTS "Users can delete their own messages" ON public.messages;

        -- Recreate policies
        CREATE POLICY "Users can view their own messages"
            ON public.messages FOR SELECT
            USING (auth.uid() = user_id);

        CREATE POLICY "Users can insert their own messages"
            ON public.messages FOR INSERT
            WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can update their own messages"
            ON public.messages FOR UPDATE
            USING (auth.uid() = user_id);

        CREATE POLICY "Users can delete their own messages"
            ON public.messages FOR DELETE
            USING (auth.uid() = user_id);

        -- Check and add missing indexes
        CREATE INDEX IF NOT EXISTS messages_user_id_idx ON public.messages(user_id);
        CREATE INDEX IF NOT EXISTS messages_chat_id_idx ON public.messages(chat_id);
        CREATE INDEX IF NOT EXISTS messages_created_at_idx ON public.messages(created_at);
    END IF;
END $$; 