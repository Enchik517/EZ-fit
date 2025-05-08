create table "public"."user_profiles" (
  id uuid not null primary key references auth.users on delete cascade,
  full_name text not null,
  age integer not null,
  gender text not null,
  height double precision not null,
  weight double precision not null,
  fitness_level text not null,
  weekly_workouts text not null,
  workout_duration text not null,
  goals text[] not null default '{}',
  equipment text[] not null default '{}',
  injuries text[] default null,
  has_completed_survey boolean not null default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Trigger для автоматического обновления updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

create trigger update_user_profiles_updated_at
  before update on user_profiles
  for each row
  execute function update_updated_at_column();

-- RLS policies
alter table "public"."user_profiles" enable row level security;

create policy "Users can view own profile"
  on user_profiles for select
  using ( auth.uid() = id );

create policy "Users can insert own profile"
  on user_profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile"
  on user_profiles for update
  using ( auth.uid() = id ); 