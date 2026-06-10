-- REPAIR: Fix migration tracking after modifying 0001
-- 1. Check current state
SELECT version, left(name, 80) as name
FROM supabase_migrations.schema_migrations
ORDER BY version;

-- 2. Remove entries that need to be re-applied (0001 was modified)
DELETE FROM supabase_migrations.schema_migrations
WHERE name = '20260419_0001_init_schema.sql';

-- If you see duplicate version errors for 20260421, also fix those:
DELETE FROM supabase_migrations.schema_migrations
WHERE version = '20260421' AND name LIKE '20260421_0003%';

-- Then re-run: supabase db push
