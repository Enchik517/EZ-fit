-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing table if it exists
DROP TABLE IF EXISTS chat_messages;

-- Create chat_messages table with proper constraints
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    content TEXT NOT NULL,
    is_user BOOLEAN DEFAULT true,
    image_url TEXT,
    chat_id TEXT NOT NULL DEFAULT 'default',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_user
        FOREIGN KEY(user_id) 
        REFERENCES auth.users(id) 
        ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own messages" 
    ON chat_messages 
    FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own messages" 
    ON chat_messages 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages" 
    ON chat_messages 
    FOR DELETE 
    USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_chat_messages_user_chat 
    ON chat_messages(user_id, chat_id);

CREATE INDEX idx_chat_messages_created_at 
    ON chat_messages(created_at);

-- Create stored procedure for deleting messages
CREATE OR REPLACE FUNCTION delete_chat_messages(p_user_id UUID, p_chat_id TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM chat_messages
    WHERE user_id = p_user_id
    AND chat_id = p_chat_id;
END;
$$; 