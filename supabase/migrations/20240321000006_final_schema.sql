-- Включаем расширение для UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Удаляем существующие таблицы и политики
DROP POLICY IF EXISTS "Users can insert their own survey data." ON user_surveys;
DROP POLICY IF EXISTS "Users can update their own survey data." ON user_surveys;
DROP POLICY IF EXISTS "Users can read their own survey data." ON user_surveys;
DROP POLICY IF EXISTS "Users can delete their own survey data." ON user_surveys;
DROP TABLE IF EXISTS chat_messages;
DROP TABLE IF EXISTS user_surveys;
DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS exercises;
DROP TABLE IF EXISTS workout_logs;

-- Создаем таблицу профилей пользователей
CREATE TABLE user_profiles (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL UNIQUE,
  full_name text,
  birth_date timestamptz,
  age integer,
  gender text,
  height decimal,
  weight decimal,
  fitness_level text,
  weekly_workouts text,
  workout_duration text,
  goals text[],
  equipment text[],
  injuries text[],
  has_completed_survey boolean DEFAULT false,
  username text,
  avatar_url text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- Создаем таблицу для хранения результатов опроса
CREATE TABLE user_surveys (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  survey_data jsonb NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  UNIQUE(user_id)
);

-- Создаем таблицу упражнений
CREATE TABLE exercises (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name text NOT NULL,
  description text,
  muscle_group text NOT NULL,
  equipment text[],
  difficulty text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Создаем таблицу логов тренировок
CREATE TABLE workout_logs (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  workout_date date NOT NULL,
  workout_name text NOT NULL,
  exercises jsonb NOT NULL,
  duration interval NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Создаем таблицу для сообщений чата
CREATE TABLE chat_messages (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  content text NOT NULL,
  is_user boolean DEFAULT true,
  image_url text,
  chat_id text DEFAULT 'default',
  status text DEFAULT 'sent' CHECK (status IN ('sent', 'processing', 'completed', 'error')),
  error_message text,
  ai_response_id text,
  metadata jsonb,
  created_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamptz DEFAULT timezone('utc'::text, now()),
  processed_at timestamptz
);

-- Включаем RLS для всех таблиц
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Политики для user_profiles
CREATE POLICY "Users can view their own profile."
  ON user_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile."
  ON user_profiles FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile."
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own profile."
  ON user_profiles FOR DELETE
  USING (auth.uid() = user_id);

-- Политики для user_surveys
CREATE POLICY "Users can insert their own survey data."
  ON user_surveys FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own survey data."
  ON user_surveys FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can read their own survey data."
  ON user_surveys FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own survey data."
  ON user_surveys FOR DELETE
  USING (auth.uid() = user_id);

-- Политики для exercises (публичный доступ на чтение)
CREATE POLICY "Exercises are viewable by everyone."
  ON exercises FOR SELECT
  USING (true);

CREATE POLICY "Only authenticated users can create exercises."
  ON exercises FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Политики для workout_logs
CREATE POLICY "Users can view their own workout logs."
  ON workout_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout logs."
  ON workout_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workout logs."
  ON workout_logs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own workout logs."
  ON workout_logs FOR DELETE
  USING (auth.uid() = user_id);

-- Политики для chat_messages
CREATE POLICY "Users can view their own messages"
  ON chat_messages FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own messages"
  ON chat_messages FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own messages"
  ON chat_messages FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages"
  ON chat_messages FOR DELETE
  USING (auth.uid() = user_id);

-- Индексы для оптимизации
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_user_surveys_user_id ON user_surveys(user_id);
CREATE INDEX idx_workout_logs_user_id ON workout_logs(user_id);
CREATE INDEX idx_workout_logs_date ON workout_logs(workout_date);
CREATE INDEX idx_exercises_muscle_group ON exercises(muscle_group);
CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_chat_id ON chat_messages(chat_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX idx_chat_messages_status ON chat_messages(status);

-- Функция для удаления пользователя
CREATE OR REPLACE FUNCTION delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

-- Даем доступ к функции аутентифицированным пользователям
GRANT EXECUTE ON FUNCTION delete_user() TO authenticated; 