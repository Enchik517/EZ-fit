-- Создаем таблицы
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

create table if not exists public.exercises (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  description text,
  muscle_group text not null,
  equipment text[],
  difficulty text not null,
  created_at timestamptz default now()
);

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

create table if not exists public.workouts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  description text,
  difficulty text,
  category text,
  focus text,
  duration integer,
  exercises jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.scheduled_workouts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users on delete cascade not null,
  workout jsonb not null,
  date text not null,
  created_at timestamptz default now(),
  unique(user_id, date)
);

create table if not exists public.completed_workouts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users on delete cascade not null,
  date text not null,
  workout_name text not null,
  created_at timestamptz default now(),
  unique(user_id, date, workout_name)
);

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
alter table public.workouts enable row level security;
alter table public.scheduled_workouts enable row level security;
alter table public.completed_workouts enable row level security;
alter table public.chat_messages enable row level security;

-- Политики безопасности для user_profiles
create policy "Users can view own profile" 
  on public.user_profiles for select using (auth.uid() = user_id);
create policy "Users can update own profile" 
  on public.user_profiles for update using (auth.uid() = user_id);
create policy "Users can insert own profile" 
  on public.user_profiles for insert with check (auth.uid() = user_id);

-- Политики для exercises
create policy "Exercises viewable by everyone" 
  on public.exercises for select using (true);
create policy "Only auth users create exercises" 
  on public.exercises for insert with check (auth.role() = 'authenticated');

-- Политики для workout_logs
create policy "Users can view own logs" 
  on public.workout_logs for select using (auth.uid() = user_id);
create policy "Users can insert own logs" 
  on public.workout_logs for insert with check (auth.uid() = user_id);
create policy "Users can update own logs" 
  on public.workout_logs for update using (auth.uid() = user_id);
create policy "Users can delete own logs" 
  on public.workout_logs for delete using (auth.uid() = user_id);

-- Политики для workouts
create policy "Users can view own workouts" 
  on public.workouts for select using (auth.uid() = user_id);
create policy "Users can insert own workouts" 
  on public.workouts for insert with check (auth.uid() = user_id);
create policy "Users can update own workouts" 
  on public.workouts for update using (auth.uid() = user_id);
create policy "Users can delete own workouts" 
  on public.workouts for delete using (auth.uid() = user_id);

-- Политики для scheduled_workouts
create policy "Users can view own scheduled" 
  on public.scheduled_workouts for select using (auth.uid() = user_id);
create policy "Users can insert own scheduled" 
  on public.scheduled_workouts for insert with check (auth.uid() = user_id);
create policy "Users can update own scheduled" 
  on public.scheduled_workouts for update using (auth.uid() = user_id);
create policy "Users can delete own scheduled" 
  on public.scheduled_workouts for delete using (auth.uid() = user_id);

-- Политики для completed_workouts
create policy "Users can view own completed" 
  on public.completed_workouts for select using (auth.uid() = user_id);
create policy "Users can insert own completed" 
  on public.completed_workouts for insert with check (auth.uid() = user_id);
create policy "Users can delete own completed" 
  on public.completed_workouts for delete using (auth.uid() = user_id);

-- Политики для chat_messages
create policy "Users can view own messages" 
  on public.chat_messages for select using (auth.uid() = user_id);
create policy "Users can insert own messages" 
  on public.chat_messages for insert with check (auth.uid() = user_id);
create policy "Users can update own messages" 
  on public.chat_messages for update using (auth.uid() = user_id);
create policy "Users can delete own messages" 
  on public.chat_messages for delete using (auth.uid() = user_id);

-- Создаем функцию для удаления пользователя
create or replace function delete_user()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

-- Даем доступ к функции
grant execute on function delete_user() to authenticated; 