-- Add birth_date column to user_profiles
ALTER TABLE public.user_profiles
ADD COLUMN birth_date TIMESTAMPTZ;

-- Update existing profiles to use age field for birth_date
UPDATE public.user_profiles
SET birth_date = CURRENT_DATE - (age * INTERVAL '1 year')
WHERE birth_date IS NULL AND age IS NOT NULL; 