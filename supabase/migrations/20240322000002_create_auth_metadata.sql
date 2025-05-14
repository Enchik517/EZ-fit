-- Create auth_metadata table
CREATE TABLE IF NOT EXISTS public.auth_metadata (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    google_data JSONB,
    apple_data JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create trigger to update updated_at
CREATE OR REPLACE FUNCTION update_auth_metadata_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_auth_metadata_updated_at
  BEFORE UPDATE ON public.auth_metadata
  FOR EACH ROW
  EXECUTE PROCEDURE update_auth_metadata_updated_at_column();

-- Set up Row Level Security
ALTER TABLE public.auth_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own auth_metadata"
  ON public.auth_metadata FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own auth_metadata"
  ON public.auth_metadata FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own auth_metadata"
  ON public.auth_metadata FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id); 