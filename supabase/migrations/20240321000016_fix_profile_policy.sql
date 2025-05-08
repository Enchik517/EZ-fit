-- First, drop existing policies
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable select for users based on user_id" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.user_profiles;

-- Temporarily disable RLS to clean up any existing data
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;
TRUNCATE TABLE public.user_profiles CASCADE;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create new, more permissive policies
CREATE POLICY "Enable insert for registration"
    ON public.user_profiles FOR INSERT
    WITH CHECK (true);  -- Allow any insert during registration

CREATE POLICY "Enable select for own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Enable update for own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Enable delete for own profile"
    ON public.user_profiles FOR DELETE
    USING (auth.uid() = id); 