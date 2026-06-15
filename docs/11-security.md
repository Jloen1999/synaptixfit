# 11 - Seguridad

**Proyecto:** SynaptixFit  
**Versión:** 1.3  
**Fecha:** 14-06-2026  
**Referencia:** [03-architecture.md](03-architecture.md) (sección 7), [04-data-model.md](04-data-model.md) (RLS)

---

## 1. Modelo de Autenticación

### 1.1 Proveedor

| Aspecto | Detalle |
|---------|--------|
| Servicio | Supabase Auth |
| Métodos | Email/password + proveedores OAuth (Google, etc.) |
| Token | JWT (JSON Web Token) |
| Expiración | 1 hora (configurable con refresh token) |
| Almacenamiento en cliente | Secure Storage (no SharedPreferences) |

### 1.2 Flujo de autenticación

```mermaid
sequenceDiagram
    participant U as Usuario
    participant A as Flutter App
    participant S as Supabase Auth
    participant DB as PostgreSQL

    U->>A: Ingresa credenciales
    A->>S: POST /auth/login
    S->>S: Valida credenciales
    S->>A: JWT Token + Refresh Token
    A->>A: Almacena en Secure Storage
    A->>DB: Queries con Bearer Token
    DB->>DB: Aplica RLS con auth.uid()
    DB->>A: Datos filtrados por permisos
```

### 1.3 Reglas de contraseña

- Mínimo 8 caracteres.
- Al menos 1 letra mayúscula.
- Al menos 1 número.
- Sin espacios al inicio ni al final.

---

## 2. Row-Level Security (RLS)

### 2.1 Principio general

Todas las tablas tienen RLS habilitado. Ninguna query puede ejecutarse sin pasar por las políticas de acceso.

### 2.2 Modelo de visibilidad

SynaptixFit implementa un modelo de visibilidad por recurso con tres niveles:

```mermaid
flowchart TD
    R["Recurso con visibilidad"] --> P1{"¿Es propietario?"}
    P1 -- Sí --> ALLOW0["✅ Lectura + Escritura"]
    P1 -- No --> P2{"¿Relación bloqueada?"}
    P2 -- Sí --> DENYB["❌ Denegar"]
    P2 -- No --> P3{"¿Público?"}
    P3 -- Sí --> ALLOW1["✅ Solo lectura"]
    P3 -- No --> P4{"¿Solo amigos + amistad aceptada?"}
    P4 -- Sí --> ALLOW2["✅ Solo lectura"]
    P4 -- No --> DENY["❌ Denegar"]
```

### 2.3 Matriz de políticas de acceso

| Tabla | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `usuarios` | Propio + públicos | — | Solo propio + admin | — |
| `partes_cuerpo` | Todos (catálogo público) | — | — | — |
| `musculos` | Todos (catálogo público) | — | — | — |
| `equipamientos` | Todos (catálogo público) | — | — | — |
| `ejercicios` | Todos (catálogo público) | — | — | — |
| `ejercicio_musculo_objetivo` | Todos (catálogo público) | — | — | — |
| `ejercicio_musculo_secundario` | Todos (catálogo público) | — | — | — |
| `ejercicio_parte_cuerpo` | Todos (catálogo público) | — | — | — |
| `ejercicio_equipamiento` | Todos (catálogo público) | — | — | — |
| `rutinas` | Propio + según visibilidad | Solo propio | Solo propio | Solo propio |
| `seleccion_de_ejercicios` | Hereda de `rutinas` | Hereda | Hereda | Hereda |
| `sesiones_registradas` | Propio + públicos | Solo propio | Propio | Propio |
| `retos` | Propio + según visibilidad | Solo propio | Solo propio | Solo propio |
| `hitos_de_reto` | Hereda de `retos` | Hereda | Hereda | Hereda |
| `progreso_de_reto` | Propio + públicos | Solo propio | Solo propio | Solo propio |
| `notificaciones` | Solo propio | Funciones admin | Solo propio | Solo propio |
| `horarios_academicos` | Solo propio | Solo propio | Solo propio | Solo propio |
| `asignaturas` | Solo propio | Solo propio | Solo propio | Solo propio |
| `universidades` | Todos (catálogo público) | Solo authenticated (seed) | — | — |
| `centros` | Todos (catálogo público) | Solo authenticated (seed) | — | — |
| `carreras` | Todos (catálogo público) | Solo authenticated (seed) | — | — |
| `asignaturas_catalogo` | Todos (catálogo público) | Solo authenticated (seed) | — | — |
| `profesores_asignatura` | Todos (catálogo público) | Solo authenticated (seed) | — | — |
| `prerrequisitos_asignatura` | Todos (catálogo público) | Solo authenticated (seed) | — | — |
| `criterios_evaluacion` | Todos (catálogo público) | Solo authenticated (seed) | — | — |
| `bibliografia_asignatura` | Todos (catálogo público) | Solo authenticated (seed) | — | — |
| `usuario_carreras` | Solo propio | Solo propio | — | Solo propio |
| `planes_estudio` | Propio + según visibilidad | Solo propio | Solo propio | Solo propio |
| `apuntes` | Propio + según visibilidad | Solo propio | Solo propio | Solo propio |
| `perfil_academico_usuario` | Solo propio | Solo propio | Solo propio | Solo propio |
| `carga_academica_semanal` | Solo propio | Solo propio | Solo propio | Solo propio |
| `perfil_bienestar_usuario` | Solo propio | Solo propio | Solo propio | — |
| `historial_peso` | Solo propio | Solo propio | — | — |
| `plan_entrenamiento_semanal` | Solo propio | Solo propio | Solo propio | Solo propio |
| `actividades_sociales` | Propio + públicos | Solo propio | — | — |
| `interacciones_sociales` | Según visibilidad de actividad | Autenticado | — | Solo propio |
| `amistades` | Solo propio | Solo propio | Solo propio | Solo propio |
| `preferencias_notificacion` | Solo propio | Solo propio | Solo propio | — |

### 2.4 Rol de administrador

El sistema define un rol `admin` en la tabla `usuarios` (columna `rol` con CHECK `IN ('usuario', 'admin')`). Los administradores tienen permisos elevados para:

| Permiso | Alcance | Implementación |
|---------|--------|---------------|
| **UPDATE en `usuarios`** | Resetear nivel, XP, racha de cualquier usuario | Política RLS: `auth.uid() = id OR EXISTS(SELECT 1 FROM usuarios u WHERE u.id = auth.uid() AND u.rol = 'admin')` |
| **Ejecutar `wipe_user_data()`** | Eliminar todo el historial de un usuario preservando datos personales | Función `SECURITY DEFINER` con verificación interna de `rol = 'admin'` |
| **Consultar cualquier usuario** | Listar usuarios para búsqueda en panel de administración | Mediante `usuarios_seleccionar` (ya visible si nivel_privacidad = 'publico') o mediante función admin con `SECURITY DEFINER` |

**Restricciones del rol admin:**
- Un administrador **no puede** hacer wipe de su propio usuario (validado en `wipe_user_data`).
- El rol `admin` solo puede ser asignado manualmente por un superadmin de Supabase (no hay endpoint público de promoción).
- Las acciones de administración deben quedar registradas en logs de auditoría (fase futura).

---

## 3. Protección de Datos Sensibles

### 3.1 Datos físicos del estudiante

| Campo | Sensibilidad | Visibilidad por defecto |
|-------|-------------|------------------------|
| `peso_kg` | Alta | `privado` (RB-20) |
| `altura_cm` | Alta | `privado` |
| `nivel_condicion` | Media | `privado` |
| `limitaciones_fisicas` | Crítica | `privado` (nunca se expone públicamente) |

### 3.2 Datos académicos sensibles

| Campo | Sensibilidad | Visibilidad por defecto |
|-------|-------------|------------------------|
| `carrera` (en `usuario_carreras`) | Media | `privado` |
| `semestre_actual` | Media | `privado` |
| `creditos_semestre_actual` | Media | `privado` |
| `nivel_estres` | Alta | `privado` |
| `horas_sueno_promedio` | Alta | `privado` |
| `contenido` (apuntes) | Media | `privado` (controlado por `visibilidad`) |
| `es_nota_rapida` | Baja | `privado` |

### 3.3 Datos del catálogo académico (públicos)

| Tabla | Sensibilidad | Visibilidad |
|-------|-------------|-------------|
| `universidades` | Pública | Todos (lectura) |
| `centros` | Pública | Todos (lectura) |
| `carreras` | Pública | Todos (lectura) |
| `asignaturas_catalogo` | Pública | Todos (lectura) |
| `profesores_asignatura` | Pública | Todos (lectura) |
| `prerrequisitos_asignatura` | Pública | Todos (lectura) |
| `criterios_evaluacion` | Pública | Todos (lectura) |
| `bibliografia_asignatura` | Pública | Todos (lectura) |

Estos datos provienen de `grados.json` (datos educativos públicos) y no contienen información personal.

### 3.3 Reglas de negocio de privacidad

- **RB-11:** Las publicaciones automáticas de logros respetan la preferencia de `autopost_logros_habilitado`.
- **RB-20:** Los datos físicos son siempre privados por defecto.
- **RF-SAF-03:** El usuario puede desactivar publicaciones automáticas de logros para reducir presión social.

---

## 4. Seguridad de Claves

| Clave | Ubicación segura | Nunca expuesta en |
|-------|-----------------|-------------------|
| `SUPABASE_ANON_KEY` | `.env` del cliente | — (es pública por diseño) |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Functions / Scripts backend | ❌ Cliente Flutter |
| `R2_SECRET_ACCESS_KEY` | Cloudflare Workers / Scripts backend | ❌ Cliente Flutter |
| JWT del usuario | Secure Storage (dispositivo) | ❌ SharedPreferences, logs |

---

## 5. URLs Firmadas (Cloudflare R2)

| Aspecto | Configuración |
|---------|--------------|
| Método | HMAC-SHA256 signature |
| Expiración | 1 hora (configurable por tipo de cliente) |
| Generación | Cloudflare Worker `firmar_url_r2` |
| Caché cliente | Riverpod con TTL = expiración - margen de 5 min |

---

## 6. Salvaguardas de Bienestar (RNF-SAF)

| Regla | Implementación |
|-------|---------------|
| RNF-SAF-01 | Evitar lenguaje punitivo en mensajes de incumplimiento |
| RNF-SAF-02 | Mecanismos para reducir presión social (ocultar rachas, desactivar autopost) |
| RNF-SAF-03 | Separación explícita entre recomendaciones de bienestar y consejo clínico |
| RF-SAF-01 | Mensajes de uso responsable ("Esta app no sustituye atención profesional") |
| RF-SAF-02 | Recursos de ayuda cuando se reporte alto estrés o bloqueo sostenido |

---

## 7. Auditoría y Trazabilidad

Eventos que deben quedar registrados (según sección 10.2 del SRS):

1. Cambio de visibilidad de cualquier recurso.
2. Eliminación de contenido.
3. Completar reto o rutina.
4. Error de acceso por permisos.
5. Alta o archivo de asignatura.
6. Registro o corrección de calificación.
7. Actualización de perfil físico.
8. Recálculo de plan de entrenamiento semanal.
9. Selección o reemplazo de ejercicios en una rutina.

---

**Documento compilado:** 14-06-2026  
**Última revisión:** v1.3 — Añadido rol admin y políticas de wipe
