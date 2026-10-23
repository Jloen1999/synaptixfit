# 0004. Sustituir Supabase por un backend y una autenticación propios

* **Estado:** Aprobado (la parte de IA la sustituye la ADR 0008: DeepSeek en lugar de Gemini)
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
Con Supabase el cliente accedía directamente a las tablas protegidas por RLS, las reglas de negocio vivían en 30+ funciones y triggers SQL (XP, sincronización retos/entregas, ACWR, RGPD…) y las claves de Gemini y del proxy de R2 viajaban en el cliente. El esquema acumulaba 62 migraciones con valores contradictorios (tres vocabularios de visibilidad, CHECK duplicados, triggers que se contradecían).

## Decisión
- Backend propio (ADR 0003) como única puerta a los datos. La autorización se hace en los casos de uso (propiedad del recurso y rol), no con RLS.
- Autenticación propia: email y contraseña (BCrypt) y Google Sign-In (verificación del ID token con las claves públicas de Google). Tokens de acceso JWT HS256 de 15 min y tokens de refresco rotatorios de 30 días guardados como hash; reutilizar un token revocado cierra todas las sesiones.
- Gemini y Cloudflare R2 solo se llaman desde el backend (R2 con URLs prefirmadas por su API S3); desaparece el Worker proxy.
- Esquema consolidado y normalizado en `V1__baseline_schema.sql` + catálogo en `V2__seed_catalog.sql`. Las reglas de negocio pasan al dominio Java (`docs/01-architecture/data_model.md`).
- Se elimina la cola offline del cliente: con un backend que valida y aplica reglas, las escrituras diferidas sin validar generaban conflictos. El cliente muestra el estado de conexión y permite reintentar.
- La migración de datos desde Supabase se describe en `docs/04-guides/data_migration.md` (los hashes BCrypt de Supabase Auth se reutilizan).

## Consecuencias
* **Positivas:** ningún secreto en el cliente; reglas en un único sitio y con tests; esquema coherente.
* **Negativas:** se pierde Realtime (el muro social se actualiza al refrescar o sondeando con `since`) y la recuperación de contraseña por email gestionada (pendiente de implementar con un servicio de correo).
