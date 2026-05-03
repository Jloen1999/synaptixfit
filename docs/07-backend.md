# 07 - Backend (Servicios y Lógica del Servidor)

**Proyecto:** SynaptixFit  
**Versión:** 1.1  
**Fecha:** 03-05-2026  
**Referencia:** [03-architecture.md](03-architecture.md) (secciones 8.2 y 8.3)

---

## 1. Arquitectura Backend

SynaptixFit utiliza un backend gestionado (Supabase) con la siguiente división:

| Capa | Tecnología | Responsabilidad |
|------|-----------|----------------|
| Base de datos | Supabase PostgreSQL | Almacén relacional + RLS |
| Autenticación | Supabase Auth | JWT, registro, login, proveedores sociales |
| Tiempo real | Supabase Realtime | WebSocket para actualizaciones en vivo |
| Orquestación | Supabase Edge Functions (Deno) | Lógica de negocio sensible |
| Almacenamiento | Cloudflare R2 | Multimedia de ejercicios (videos, imágenes) |
| Acceso multimedia | Cloudflare Workers | Generación de URLs firmadas para R2 |

---

## 2. Edge Functions

### 2.1 `clonar_reto_publico`

| Propiedad | Valor |
|-----------|-------|
| **Entrada** | `reto_id` |
| **Salida** | `nuevo_reto_id` |
| **Validaciones** | Visibilidad pública, ownership, prevención de duplicado |
| **Lógica** | Copia el reto y sus hitos al perfil del usuario autenticado |

### 2.2 `publicar_logro`

| Propiedad | Valor |
|-----------|-------|
| **Entrada** | `tipo`, `referencia_id`, `mensaje` (opcional) |
| **Salida** | `publicacion_id` |
| **Validaciones** | Evento válido, ownership, preferencia `autopost_logros_habilitado` |
| **Lógica** | Crea entrada en `actividades_sociales` si el usuario tiene autopost activo |

### 2.3 `validar_reto_complejo`

| Propiedad | Valor |
|-----------|-------|
| **Entrada** | `reto`, `hitos[]`, `dependencias[]` |
| **Salida** | `valido` (bool), `errores[]` |
| **Validaciones** | Sin dependencias cíclicas, fechas coherentes, suma de pesos |

**Regla de cálculo de importancia por orden (server-side):**
- El usuario no define pesos manuales.
- La importancia de cada hito se calcula automáticamente según su posición.
- Fórmula para `n` hitos y posición `i` (1 = primer hito):
  ```
  importancia(i) = (n - i + 1) / (n × (n + 1) / 2)
  ```
- Al reordenar hitos, se recalcula el avance global del reto.

### 2.4 `recomendar_plan_entrenamiento`

| Propiedad | Valor |
|-----------|-------|
| **Entrada** | `usuario_id`, `semana` |
| **Salida** | `sesiones_recomendadas`, `carga_objetivo_min`, `intensidad`, `sugerencias[]` |
| **Validaciones** | Perfil de bienestar completo, disponibilidad mínima, límites de seguridad |
| **Lógica** | Calcula la recomendación semanal basándose en el perfil físico, disponibilidad y adherencia reciente |

### 2.5 `recalcular_plan_bienestar`

| Propiedad | Valor |
|-----------|-------|
| **Entrada** | `usuario_id`, `semana`, `metricas_adherencia` |
| **Salida** | `plan_ajustado` |
| **Validaciones** | Conservar al menos un día de descanso, ajuste progresivo de carga |
| **Lógica** | Si la adherencia baja de umbral o se reporta fatiga alta, reduce intensidad y frecuencia |

### 2.6 `recordatorios_programados` (cron)

| Propiedad | Valor |
|-----------|-------|
| **Entrada** | Ninguna (cron automático) |
| **Salida** | `metricas_envio` |
| **Validaciones** | Respeta franja de silencio, límite diario, prioridad por urgencia |
| **Lógica** | Evalúa las preferencias de cada usuario y genera notificaciones según la cola programada |

### 2.7 `resolver_media_r2_ejercicio`

| Propiedad | Valor |
|-----------|-------|
| **Entrada** | `ejercicio_id` |
| **Salida** | `url_firmada`, `expira_en` |
| **Validaciones** | Objeto existente en R2, permisos de lectura del usuario |

### 2.8 `importar_catalogo_exercisedb`

| Propiedad | Valor |
|-----------|-------|
| **Entrada** | `version`, `lote`, `dry_run` (bool), `dataset_path` |
| **Salida** | `resumen_importacion`, `errores_mapeo` |
| **Validaciones** | Integridad referencial (`exercises`, `muscles`, `equipments`, `bodyParts`), deduplicación por `exercise_db_id`, licencia admitida |
| **Fuente** | Dataset oficial ExerciseDB (AscendAPI) distribuido via Kaggle |

---

## 3. Stored Procedures (PostgreSQL)

### 3.1 `detectar_conflictos_de_horario`

Detecta solapamientos entre bloques de estudio y sesiones de entrenamiento en una semana dada.

**Parámetros:** `p_usuario_id UUID`, `p_inicio_semana DATE`  
**Retorno:** Tabla con `id_conflicto`, `id_bloque_estudio`, `id_sesion_entrenamiento`, `mensaje_conflicto`

### 3.2 `calcular_progreso_de_reto`

Calcula el progreso global de un reto (simple o complejo con ponderación por pesos de hitos).

**Parámetros:** `p_reto_id UUID`  
**Retorno:** `DOUBLE PRECISION` (0.0 a 1.0)

### 3.3 `otorgar_xp`

Incrementa XP del usuario y sube de nivel si alcanza el umbral (1000 × nivel actual).

**Parámetros:** `p_usuario_id UUID`, `p_cantidad_xp INT`  
**Retorno:** Tabla con `nuevo_nivel`, `nueva_xp`, `sube_nivel`

---

## 4. Canales Realtime (Supabase)

Todas las tablas del catálogo de ejercicios tienen Supabase Realtime activado mediante `ALTER PUBLICATION supabase_realtime ADD TABLE`. El frontend Flutter consume estos eventos vía `.stream()` desde el provider `ejerciciosProvider`.

| Canal / Tabla | Eventos | Uso en frontend |
|---------------|---------|-----------------|
| `ejercicios` | INSERT, UPDATE, DELETE | Refresco automático del explorador y detalle de ejercicios |
| `partes_cuerpo` | INSERT, UPDATE, DELETE | Sincronización de catálogo de partes del cuerpo |
| `musculos` | INSERT, UPDATE, DELETE | Sincronización de catálogo de músculos |
| `equipamientos` | INSERT, UPDATE, DELETE | Sincronización de catálogo de equipamientos |
| `ejercicio_musculo_objetivo` | INSERT, UPDATE, DELETE | Actualización de relaciones N:M en vivo |
| `ejercicio_musculo_secundario` | INSERT, UPDATE, DELETE | Actualización de relaciones N:M en vivo |
| `ejercicio_parte_cuerpo` | INSERT, UPDATE, DELETE | Actualización de relaciones N:M en vivo |
| `ejercicio_equipamiento` | INSERT, UPDATE, DELETE | Actualización de relaciones N:M en vivo |

**Canales definidos en la arquitectura original (pendientes de activación en frontend):**

| Canal | Evento | Tabla | Uso |
|-------|--------|-------|-----|
| `canal_muro` | INSERT | `actividades_sociales` | Refresco del feed social |
| `canal_retos_usuario` | UPDATE | `retos`, `hitos_de_reto` | Progreso en tiempo real |
| `canal_amistades` | UPDATE | `amistades` | Solicitudes, aceptaciones, bloqueos |
| `canal_notificaciones_usuario` | INSERT | `notificaciones` | Centro de avisos |
| `canal_bienestar_usuario` | UPDATE | `plan_entrenamiento_semanal` | Adherencia semanal |

---

## 5. Repositorios de Dominio

Contratos de la capa de infraestructura que conectan Flutter con el backend:

| # | Repositorio | Métodos principales |
|---|-------------|-------------------|
| 1 | `RepositorioPlanesEstudio` | `crearPlan`, `actualizarPlan`, `eliminarPlan`, `listarPlanesVisibles` |
| 2 | `RepositorioApuntes` | `crearApunte`, `actualizarApunte`, `eliminarApunte`, `listarApuntesVisibles` |
| 3 | `RepositorioAcademico` | `crearAsignatura`, `archivarAsignatura`, `crearEvaluacion`, `registrarCalificacion`, `listarAsignaturasConProgreso` |
| 4 | `RepositorioRetos` | `crearRetoSimple`, `crearRetoComplejo`, `reordenarHitos`, `actualizarProgreso`, `pausar`, `reprogramar`, `completar`, `clonarPublico` |
| 5 | `RepositorioBienestar` | `guardarPerfil`, `generarPlanSemanal`, `confirmarPlan`, `recalcularPlan`, `crearRutina`, `listarCatalogo`, `seleccionarEjercicios`, `completarRutina` |
| 6 | `RepositorioMuro` | `listarMuro`, `darMeGusta`, `quitarMeGusta` |
| 7 | `RepositorioNotificaciones` | `actualizarPreferencias`, `obtenerPreferencias`, `previsualizarPlanEnvio` |
| 8 | `RepositorioAnalitica` | `obtenerResumenSemanal`, `detectarSobrecarga`, `sugerirAjustes` |
| 9 | `RepositorioSincronizacion` | `encolarOperacionLocal`, `sincronizarPendientes`, `resolverConflicto` |

---

## 6. Cloudflare Workers

### 6.1 `firmar_url_r2`

Genera URLs firmadas con expiración temporal para acceso controlado a multimedia en R2.

```
Entrada: r2_object_key, duracion_segundos (default: 3600)
Salida: url_firmada, expira_en
```

**Configuración:** `wrangler.toml` en `backend/cloudflare/workers/firmar_url_r2/`.

---

## 7. Autenticación (Google y Correo/Contraseña)

SynaptixFit utiliza **Supabase Auth** para gestionar de forma robusta la identidad de los usuarios, combinando **Google (SSO + People API)** y **Correo/Contraseña**.

Una particularidad del flujo es que **la contraseña de correo no se exige en el primer contacto**. Para minimizar la fricción en la entrada, se prioriza el inicio de sesión OAuth o acceso sin contraseña (Magic Link/OTP), y el usuario **establece su contraseña más adelante desde la Configuración del Perfil**.

### 7.1 Flujos de Autenticación

**A. Flujo con Google (Google People API)**
1. El usuario selecciona "Iniciar sesión con Google" en la aplicación móvil o web.
2. La aplicación cliente inicia el flujo OAuth usando el SDK de Supabase (`supabase.auth.signInWithOAuth`).
3. Google solicita los permisos definidos (por defecto `email`, `profile`, `openid` y `https://www.googleapis.com/auth/contacts.readonly`).
4. Tras la autorización, Supabase verifica el JWT y crea o enlaza el usuario en `auth.users`.
5. Los metadatos de Google (`user_metadata`) alimentan el perfil inicial.

**B. Flujo con Correo y Establecimiento de Contraseña en Perfil**
1. El usuario elige ingresar o registrarse con su correo electrónico.
2. Supabase envía un código de verificación (OTP) o un enlace mágico (Magic Link) al correo.
3. Al hacer clic o introducir el código, se completa la autenticación principal.
4. **Configuración de Contraseña:** Una vez autenticado, el usuario se dirige a la vista de **Perfil > Configuración** donde establece una contraseña permanente llamando a `supabase.auth.updateUser({ password: '...' })`.
5. En futuros inicios de sesión, el usuario podrá usar directamente el formulario de "Correo y Contraseña" sin requerir revisión del correo electrónico.

### 7.2 Requisitos del Backend
Para que este flujo funcione, el administrador debe:
* Configurar el proyecto en **Google Cloud Console**.
* Habilitar la **Google People API**.
* Configurar en **Supabase Dashboard** las credenciales de OAuth obtenidas (Client ID y Client Secret).

*(Para pasos de configuración detallada, referirse al documento `08-installation.md`).*

---

**Documento compilado:** 19-04-2026  
**Última revisión:** v1.0
