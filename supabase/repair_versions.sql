-- Mapea versiones viejas (YYYYMMDD) a nuevas (YYYYMMDDNNNN)
UPDATE supabase_migrations.schema_migrations
SET version = regexp_replace(name, '\.sql$', '')
WHERE version ~ '^\d{8}$';

-- Verifica el resultado
SELECT version, left(name, 80) as name
FROM supabase_migrations.schema_migrations
ORDER BY version;
