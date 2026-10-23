# Migrar los datos desde Supabase

> **Para quién:** quien tenga acceso a la base de datos de Supabase del proyecto y quiera llevar los datos reales al backend propio. Solo hace falta una vez.

## Pasos

1. **Prepara el destino.** Levanta PostgreSQL y aplica las migraciones arrancando el backend una vez:
   ```bash
   docker compose up -d db
   cd backend && ./mvnw spring-boot:run   # detén con Ctrl+C cuando arranque
   ```
2. **Obtén la URL de conexión de Supabase:** *Project Settings → Database → Connection string (URI)*, con la contraseña de la base de datos. Debe ser la conexión directa (puerto 5432), porque el script lee también `auth.users`.
3. **Simula** la migración para ver cuántas filas se copiarán:
   ```bash
   pip install "psycopg[binary]"
   python tools/migrate_from_supabase.py --source "<url-supabase>" \
     --target "postgresql://synaptixfit:synaptixfit@localhost:5432/synaptixfit" --dry-run
   ```
4. **Ejecuta** la migración (sin `--dry-run`). Se puede relanzar: las filas que ya existen se ignoran.
5. **Archivos de R2:** no hay que moverlos. Las claves (`cloudflare_object_key`) se conservan y el backend firma las URLs con las credenciales de R2 de `backend/.env`. Usa el mismo bucket que el Worker antiguo.

## Qué transforma el script

| Dato heredado | En el backend |
|---|---|
| `auth.users.encrypted_password` (BCrypt) | `usuarios.password_hash`: los usuarios entran con la misma contraseña |
| `auth.identities` con proveedor Google | `usuarios.google_sub`: entran con Google sin volver a registrarse |
| Cuentas sin contraseña ni Google (enlace mágico) | Credencial inutilizable; el script las lista para que restablezcan la contraseña |
| `xp_total` | `xp_nivel_actual` |
| Visibilidades `publico`/`privado`/`amigos`/`solo_amigos` | `public`/`private`/`friends` |
| Interacciones de tipo comentario | Se descartan: los comentarios viven en `comentarios_feed` |
| `ejercicios.dificultad = 'medio'` | `intermedio` |
| Tipos de entrega fuera de los válidos | `otro` |

Las columnas que solo existían en el esquema antiguo se ignoran y las nuevas toman su valor por defecto.

## Comprobación

Inicia sesión en la app con un usuario migrado y revisa que aparecen sus asignaturas, rutinas y retos. El panel de administración muestra los totales de usuarios y actividad.
