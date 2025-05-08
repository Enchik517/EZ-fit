-- Изменяем тип столбцов на массивы
ALTER TABLE "public"."user_profiles" 
  ALTER COLUMN goals TYPE text[] USING goals::text[],
  ALTER COLUMN equipment TYPE text[] USING equipment::text[],
  ALTER COLUMN injuries TYPE text[] USING CASE 
    WHEN injuries IS NULL THEN NULL 
    ELSE injuries::text[] 
  END;

-- Устанавливаем значения по умолчанию
ALTER TABLE "public"."user_profiles" 
  ALTER COLUMN goals SET DEFAULT '{}',
  ALTER COLUMN equipment SET DEFAULT '{}';

-- Обновляем существующие NULL значения на пустые массивы
UPDATE "public"."user_profiles" 
SET 
  goals = '{}' WHERE goals IS NULL,
  equipment = '{}' WHERE equipment IS NULL; 