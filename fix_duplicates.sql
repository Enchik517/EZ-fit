-- Create a function to remove duplicates from workout_history
CREATE OR REPLACE FUNCTION fix_workout_history_duplicates()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    duplicate_count INTEGER;
BEGIN
    WITH duplicates AS (
        SELECT user_id, workout_id, COUNT(*) as count
        FROM workout_history
        GROUP BY user_id, workout_id
        HAVING COUNT(*) > 1
    ),
    to_keep AS (
        SELECT DISTINCT ON (wh.user_id, wh.workout_id) wh.id
        FROM workout_history wh
        JOIN duplicates d ON wh.user_id = d.user_id AND wh.workout_id = d.workout_id
        ORDER BY wh.user_id, wh.workout_id, wh.created_at DESC
    )
    SELECT COUNT(*) INTO duplicate_count
    FROM workout_history wh
    JOIN duplicates d ON wh.user_id = d.user_id AND wh.workout_id = d.workout_id
    WHERE wh.id NOT IN (SELECT id FROM to_keep);
    
    -- Delete all duplicates except the most recent one
    DELETE FROM workout_history wh
    USING duplicates d
    WHERE wh.user_id = d.user_id 
    AND wh.workout_id = d.workout_id
    AND wh.id NOT IN (
        SELECT DISTINCT ON (user_id, workout_id) id
        FROM workout_history
        ORDER BY user_id, workout_id, created_at DESC
    );
    
    -- Log the operation to debug_logs if the table exists
    BEGIN
        INSERT INTO debug_logs (user_id, action, details)
        VALUES (auth.uid(), 'fix_workout_history_duplicates', jsonb_build_object('deleted_count', duplicate_count));
    EXCEPTION WHEN OTHERS THEN
        -- If debug_logs table doesn't exist, just ignore
        NULL;
    END;
    
    RETURN duplicate_count;
END;
$$;

-- Create a function to remove duplicates from favorite_workouts
CREATE OR REPLACE FUNCTION fix_favorite_workouts_duplicates()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    duplicate_count INTEGER;
BEGIN
    WITH duplicates AS (
        SELECT user_id, workout_id, COUNT(*) as count
        FROM favorite_workouts
        GROUP BY user_id, workout_id
        HAVING COUNT(*) > 1
    ),
    to_keep AS (
        SELECT DISTINCT ON (fw.user_id, fw.workout_id) fw.id
        FROM favorite_workouts fw
        JOIN duplicates d ON fw.user_id = d.user_id AND fw.workout_id = d.workout_id
        ORDER BY fw.user_id, fw.workout_id, fw.created_at DESC
    )
    SELECT COUNT(*) INTO duplicate_count
    FROM favorite_workouts fw
    JOIN duplicates d ON fw.user_id = d.user_id AND fw.workout_id = d.workout_id
    WHERE fw.id NOT IN (SELECT id FROM to_keep);
    
    -- Delete all duplicates except the most recent one
    DELETE FROM favorite_workouts fw
    USING duplicates d
    WHERE fw.user_id = d.user_id 
    AND fw.workout_id = d.workout_id
    AND fw.id NOT IN (
        SELECT DISTINCT ON (user_id, workout_id) id
        FROM favorite_workouts
        ORDER BY user_id, workout_id, created_at DESC
    );
    
    -- Log the operation to debug_logs if the table exists
    BEGIN
        INSERT INTO debug_logs (user_id, action, details)
        VALUES (auth.uid(), 'fix_favorite_workouts_duplicates', jsonb_build_object('deleted_count', duplicate_count));
    EXCEPTION WHEN OTHERS THEN
        -- If debug_logs table doesn't exist, just ignore
        NULL;
    END;
    
    RETURN duplicate_count;
END;
$$;

-- Create a function to check for any orphaned records
CREATE OR REPLACE FUNCTION check_orphaned_records()
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    result JSONB;
BEGIN
    WITH orphaned_history AS (
        SELECT COUNT(*) as count
        FROM workout_history wh
        LEFT JOIN workouts w ON wh.workout_id = w.id
        WHERE w.id IS NULL
    ),
    orphaned_favorites AS (
        SELECT COUNT(*) as count
        FROM favorite_workouts fw
        LEFT JOIN workouts w ON fw.workout_id = w.id
        WHERE w.id IS NULL
    )
    SELECT jsonb_build_object(
        'orphaned_history', (SELECT count FROM orphaned_history),
        'orphaned_favorites', (SELECT count FROM orphaned_favorites)
    ) INTO result;
    
    -- Log the operation to debug_logs if the table exists
    BEGIN
        INSERT INTO debug_logs (user_id, action, details)
        VALUES (auth.uid(), 'check_orphaned_records', result);
    EXCEPTION WHEN OTHERS THEN
        -- If debug_logs table doesn't exist, just ignore
        NULL;
    END;
    
    RETURN result;
END;
$$;

-- Create a trigger function to automatically log workout history inserts
CREATE OR REPLACE FUNCTION log_workout_history_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Log the operation to debug_logs if the table exists
    BEGIN
        INSERT INTO debug_logs (user_id, action, details)
        VALUES (
            NEW.user_id, 
            'workout_history_auto_insert', 
            jsonb_build_object(
                'workout_id', NEW.workout_id,
                'workout_name', NEW.workout_name,
                'created_at', NEW.created_at
            )
        );
    EXCEPTION WHEN OTHERS THEN
        -- If debug_logs table doesn't exist, just ignore
        NULL;
    END;
    
    RETURN NEW;
END;
$$;

-- Create a trigger function to automatically log favorite workouts inserts
CREATE OR REPLACE FUNCTION log_favorite_workout_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Log the operation to debug_logs if the table exists
    BEGIN
        INSERT INTO debug_logs (user_id, action, details)
        VALUES (
            NEW.user_id, 
            'favorite_workout_auto_insert', 
            jsonb_build_object(
                'workout_id', NEW.workout_id,
                'workout_name', NEW.workout_name,
                'created_at', NEW.created_at
            )
        );
    EXCEPTION WHEN OTHERS THEN
        -- If debug_logs table doesn't exist, just ignore
        NULL;
    END;
    
    RETURN NEW;
END;
$$;

-- Create triggers for automatic logging
DROP TRIGGER IF EXISTS workout_history_insert_trigger ON workout_history;
CREATE TRIGGER workout_history_insert_trigger
AFTER INSERT ON workout_history
FOR EACH ROW
EXECUTE FUNCTION log_workout_history_insert();

DROP TRIGGER IF EXISTS favorite_workout_insert_trigger ON favorite_workouts;
CREATE TRIGGER favorite_workout_insert_trigger
AFTER INSERT ON favorite_workouts
FOR EACH ROW
EXECUTE FUNCTION log_favorite_workout_insert(); 