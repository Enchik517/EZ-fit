-- Удаляем старые таблицы, если они существуют
DROP TABLE IF EXISTS public.exercise_ratings CASCADE;
DROP TABLE IF EXISTS public.exercise_history CASCADE;

-- Создание таблицы exercise_ratings
CREATE TABLE IF NOT EXISTS public.exercise_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    exercise_id TEXT NOT NULL, -- Текстовый ID вместо UUID
    base_rating DECIMAL NOT NULL DEFAULT 50.0,
    current_rating DECIMAL NOT NULL DEFAULT 50.0,
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    user_preference INTEGER NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, exercise_id)
);

-- Создание таблицы exercise_history 
CREATE TABLE IF NOT EXISTS public.exercise_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    exercise_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Индексы для производительности
CREATE INDEX IF NOT EXISTS idx_exercise_ratings_user_id ON exercise_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_ratings_exercise_id ON exercise_ratings(exercise_id);
CREATE INDEX IF NOT EXISTS idx_exercise_history_user_id ON exercise_history(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_history_exercise_id ON exercise_history(exercise_id);

-- Row Level Security
ALTER TABLE public.exercise_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_history ENABLE ROW LEVEL SECURITY;

-- Политики доступа
CREATE POLICY "Users can only access their own exercise ratings"
  ON public.exercise_ratings
  FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own exercise history"
  ON public.exercise_history
  FOR ALL
  USING (auth.uid() = user_id); 