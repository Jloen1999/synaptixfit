# Supabase SQL

Estructura:

- `migrations/`: archivos de migracion versionados.
- `sql/schema.sql`: script completo listo para pegar en Supabase SQL Editor.

## Archivos actuales

- `migrations/20260419_0001_init_schema.sql`
- `sql/schema.sql`

## Uso rapido

1. Abrir Supabase Dashboard > SQL Editor.
2. Copiar el contenido de `sql/schema.sql`.
3. Ejecutar el script completo.

## Seeds de datos

- `python seed_ejercicios.py` para poblar el catalogo de ejercicios y relaciones.
- `python seed_usuarios.py` para crear cuentas mock de usuarios.
- `python seed_demo_data.py` para generar un conjunto demo enriquecido con usuarios, academia, retos, social y notificaciones.

## Nota

El esquema incluye:

- Tablas principales del MVP (usuarios, ejercicios, rutinas, retos, etc.).
- Indices para consultas frecuentes.
- Funciones SQL de negocio.
- Politicas RLS para acceso por usuario autenticado.
