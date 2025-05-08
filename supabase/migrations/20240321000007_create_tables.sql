-- Создаем таблицу профилей пользователей
create table if not exists public.user_profiles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users on delete cascade not null unique,
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
  has_completed_survey boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Создаем таблицу упражнений
create table if not exists public.exercises (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  description text,
  muscle_group text not null,
  equipment text[],
  difficulty text not null,
  created_at timestamptz default now()
);

-- Создаем таблицу логов тренировок
create table if not exists public.workout_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users on delete cascade not null,
  workout_date date not null,
  workout_name text not null,
  exercises jsonb not null,
  duration interval not null,
  notes text,
  created_at timestamptz default now()
);

-- Создаем таблицу чата
create table if not exists public.chat_messages (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users on delete cascade not null,
  content text not null,
  is_user boolean default true,
  image_url text,
  chat_id text default 'default',
  status text default 'sent' check (status in ('sent', 'processing', 'completed', 'error')),
  error_message text,
  metadata jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Включаем RLS
alter table public.user_profiles enable row level security;
alter table public.exercises enable row level security;
alter table public.workout_logs enable row level security;
alter table public.chat_messages enable row level security;

-- Создаем политики
create policy "Users can view own profile" 
  on public.user_profiles for select using (auth.uid() = user_id);
create policy "Users can update own profile" 
  on public.user_profiles for update using (auth.uid() = user_id);
create policy "Users can insert own profile" 
  on public.user_profiles for insert with check (auth.uid() = user_id);

create policy "Exercises viewable by everyone" 
  on public.exercises for select using (true);
create policy "Only auth users create exercises" 
  on public.exercises for insert with check (auth.role() = 'authenticated');

create policy "Users can view own logs" 
  on public.workout_logs for select using (auth.uid() = user_id);
create policy "Users can insert own logs" 
  on public.workout_logs for insert with check (auth.uid() = user_id);
create policy "Users can update own logs" 
  on public.workout_logs for update using (auth.uid() = user_id);
create policy "Users can delete own logs" 
  on public.workout_logs for delete using (auth.uid() = user_id);

create policy "Users can view own messages" 
  on public.chat_messages for select using (auth.uid() = user_id);
create policy "Users can insert own messages" 
  on public.chat_messages for insert with check (auth.uid() = user_id);
create policy "Users can update own messages" 
  on public.chat_messages for update using (auth.uid() = user_id);
create policy "Users can delete own messages" 
  on public.chat_messages for delete using (auth.uid() = user_id); 