-- Add chat_id column to chat_messages
ALTER TABLE chat_messages 
ADD COLUMN chat_id TEXT DEFAULT 'default';

-- Create index for chat_id
CREATE INDEX idx_chat_messages_chat_id ON chat_messages(chat_id); 