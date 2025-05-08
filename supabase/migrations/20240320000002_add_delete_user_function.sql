-- Создаем функцию для полного удаления пользователя
create or replace function delete_user_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  -- Получаем ID текущего пользователя
  v_user_id := auth.uid();
  
  -- Проверяем, что пользователь авторизован
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Удаляем данные пользователя в правильном порядке
  -- Сначала удаляем сообщения
  delete from public.messages 
  where user_id = v_user_id;
  
  -- Затем удаляем остальные данные
  delete from public.completed_workouts 
  where user_id = v_user_id;
  
  delete from public.workout_logs 
  where user_id = v_user_id;
  
  delete from public.workouts 
  where user_id = v_user_id;
  
  delete from public.scheduled_workouts 
  where user_id = v_user_id;
  
  -- Удаляем профиль пользователя
  delete from public.user_profiles 
  where id = v_user_id;
  
  -- В конце удаляем аккаунт пользователя
  delete from auth.users 
  where id = v_user_id;
end;
$$; 