-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.user_profiles;

-- Create new policies with correct permissions
CREATE POLICY "Enable insert for authenticated users"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable select for users based on user_id"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Enable update for users based on user_id"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable delete for users based on user_id"
    ON public.user_profiles FOR DELETE
    USING (auth.uid() = id); 