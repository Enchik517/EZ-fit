-- Создаем функцию для удаления пользователя
create or replace function public.delete_user()
returns void
language plpgsql
security definer
as $$
begin
  -- Проверяем, что пользователь авторизован
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  -- Удаляем профиль пользователя (каскадное удаление сработает для остальных таблиц)
  delete from auth.users where id = auth.uid();
end;
$$; 