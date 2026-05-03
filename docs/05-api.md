# 05 - Especificación de API

**Proyecto:** SynaptixFit  
**Versión:** 1.1  
**Fecha:** 03-05-2026  
**Referencia:** [03-architecture.md](03-architecture.md) (sección 8)

---

## 1. Convenciones Generales

| Aspecto | Convención |
|---------|-----------|
| Protocolo | HTTPS |
| Base URL | `https://{SUPABASE_URL}/functions/v1` |
| Formato | JSON (Content-Type: application/json) |
| Autenticación | Bearer Token (Supabase JWT) |
| Paginación | `?pagina={n}&tamanio={n}` (por defecto: página 1, tamaño 20) |
| Idioma de rutas | Español (kebab-case) |
| Versionado | Sin versionado explícito en MVP (v1 implícito) |

### 1.1 Headers obligatorios

```http
Authorization: Bearer {jwt_token}
Content-Type: application/json
apikey: {SUPABASE_ANON_KEY}
```

### 1.2 Códigos de respuesta

| Código | Significado | Acción del cliente |
|--------|-----------|-------------------|
| `200` | Operación exitosa | Procesar respuesta |
| `201` | Recurso creado | Navegar a detalle |
| `400` | Validación fallida | Mostrar error inline |
| `401` | Token expirado / inválido | Redirigir a login |
| `403` | Sin permisos (RLS) | Mostrar "Sin acceso" |
| `404` | Recurso no encontrado | Mostrar "No encontrado" |
| `409` | Conflicto (duplicado) | Informar al usuario |
| `500` | Error interno del servidor | Retry con backoff exponencial |

### 1.3 Formato de error estándar

```json
{
  "error": true,
  "codigo": "VALIDACION_FALLIDA",
  "mensaje": "La suma de pesos de hitos debe ser exactamente 100%",
  "detalles": {
    "campo": "hitos",
    "valor_actual": 85
  }
}
```

---

## 2. Módulo de Autenticación

### 2.1 Registro de usuario

```
POST /auth/registro
```

**Request:**
```json
{
  "email": "estudiante@universidad.com",
  "password": "MiPassword123",
  "nombre_completo": "Juan López"
}
```

**Response (201):**
```json
{
  "usuario_id": "uuid",
  "email": "estudiante@universidad.com",
  "token": "eyJhbGci...",
  "requiere_onboarding": true
}
```

### 2.2 Inicio de sesión

```
POST /auth/login
```

**Request:**
```json
{
  "email": "estudiante@universidad.com",
  "password": "MiPassword123"
}
```

**Response (200):**
```json
{
  "usuario_id": "uuid",
  "token": "eyJhbGci...",
  "perfil": { "nombre_completo": "Juan López", "nivel": 3, "racha_actual": 7 }
}
```

### 2.3 Cerrar sesión

```
POST /auth/logout
```

---

## 3. Módulo de Perfil de Usuario

### 3.1 Obtener perfil

```
GET /usuarios/{usuarioId}/perfil
```

**Response (200):**
```json
{
  "id": "uuid",
  "nombre_completo": "Juan López",
  "email": "estudiante@universidad.com",
  "url_avatar": "https://r2.dev/avatars/uuid.webp",
  "biografia": "Estudiante de Ingeniería...",
  "nivel": 3,
  "xp_total": 2450,
  "racha_actual": 7,
  "perfil_visibilidad": "publico",
  "sesiones_recientes": [],
  "insignias": []
}
```

### 3.2 Actualizar perfil

```
PATCH /usuarios/{usuarioId}/perfil
```

**Request:**
```json
{
  "nombre_completo": "Juan López García",
  "biografia": "Ingeniería Informática, 3er año",
  "perfil_visibilidad": "solo_amigos"
}
```

### 3.3 Subir avatar

```
POST /usuarios/{usuarioId}/avatar
Content-Type: multipart/form-data
```

### 3.4 Guardar perfil físico (onboarding)

```
POST /usuarios/perfil-fisico
```

**Request:**
```json
{
  "peso_kg": 75.5,
  "altura_cm": 178,
  "nivel_condicion": "intermedio",
  "objetivo_principal": "fuerza",
  "dias_disponibles": 4,
  "tiempo_por_sesion_min": 60
}
```

---

## 4. Módulo Académico

### 4.1 Obtener horario académico semanal

```
GET /horario-academico/{usuarioId}/semana/{inicioSemana}
```

**Response (200):**
```json
{
  "usuario_id": "uuid",
  "inicio_semana": "2026-04-20",
  "bloques": [
    {
      "id": "uuid",
      "asignatura_id": "uuid",
      "nombre_asignatura": "Cálculo II",
      "hora_inicio": "2026-04-21T09:00:00Z",
      "hora_fin": "2026-04-21T11:00:00Z",
      "ubicacion": "Aula 301",
      "tiene_conflicto": false
    }
  ],
  "conflictos": [],
  "sugerencias_ia": []
}
```

### 4.2 Guardar horario académico

```
POST /horario-academico/guardar
```

### 4.3 Plan semanal integrado

```
GET /plan-semanal/integrado/{usuarioId}/{inicioSemana}
```

---

## 5. Módulo de Ejercicios y Rutinas

### 5.1 Buscar ejercicios

El catálogo de ejercicios está normalizado en 3FN con tablas maestras (`partes_cuerpo`, `musculos`, `equipamientos`) y relaciones N:M. El frontend consulta la vista `v_ejercicios_completos` que pre-calcula los arrays de catálogos.

```
GET /v_ejercicios_completos?select=*&nombre=ilike.%{texto}%&dificultad=eq.{nivel}&limit={n}&offset={m}
```

**Response (200):**
```json
{
  "ejercicios": [
    {
      "id": "uuid",
      "exercise_db_id": "0001",
      "nombre": "Press de banca con barra",
      "url_gif": "https://r2.dev/ejercicios/360/0001.gif",
      "dificultad": "medio",
      "partes_cuerpo": ["Pecho"],
      "musculos_objetivo": ["Pectoral mayor"],
      "musculos_secundarios": ["Deltoides anterior", "Tríceps braquial"],
      "equipamientos": ["Barra", "Banco plano"]
    }
  ],
  "total": 142,
  "pagina": 1
}
```

**Filtros por catálogo:** Se consultan las tablas de relación N:M para filtrar:
```
GET /ejercicio_musculo_objetivo?select=ejercicio_id&musculo_id=eq.{id}
GET /ejercicio_parte_cuerpo?select=ejercicio_id&parte_cuerpo_id=eq.{id}
GET /ejercicio_equipamiento?select=ejercicio_id&equipamiento_id=eq.{id}
```

**Catálogos disponibles:**
```
GET /partes_cuerpo?select=id,nombre
GET /musculos?select=id,nombre
GET /equipamientos?select=id,nombre
```

### 5.2 Obtener detalle de ejercicio

```
GET /v_ejercicios_completos?id=eq.{ejercicioId}&limit=1
```

**Response (200):**
```json
{
  "id": "uuid",
  "exercise_db_id": "0001",
  "nombre": "Press de banca con barra",
  "url_gif": "https://r2.dev/ejercicios/360/0001.gif",
  "dificultad": "medio",
  "descripcion": "Ejercicio compuesto para tren superior. Trabaja principalmente el pectoral mayor...",
  "instrucciones": [
    "Acuéstate en el banco plano con los pies apoyados en el suelo.",
    "Agarra la barra con un ancho ligeramente mayor que los hombros.",
    "Baja la barra controladamente hasta el pecho.",
    "Empuja la barra hacia arriba extendiendo los codos."
  ],
  "partes_cuerpo": ["Pecho"],
  "musculos_objetivo": ["Pectoral mayor"],
  "musculos_secundarios": ["Deltoides anterior", "Tríceps braquial"],
  "equipamientos": ["Barra", "Banco plano"]
}
```

**Nota:** La vista `v_ejercicios_completos` ya incluye los arrays de catálogos pre-calculados desde las tablas de relación N:M. No se requieren consultas adicionales para obtener músculos, partes del cuerpo o equipamientos.
```

### 5.3 Crear rutina

```
POST /rutinas
```

**Request:**
```json
{
  "nombre": "Rutina de fuerza — Lunes",
  "descripcion": "Pecho y tríceps",
  "visibilidad": "privado",
  "ejercicios": [
    { "ejercicio_id": "uuid", "series": 4, "repeticiones": 8, "segundos_descanso": 90, "orden": 1 },
    { "ejercicio_id": "uuid", "series": 3, "repeticiones": 12, "segundos_descanso": 60, "orden": 2 }
  ]
}
```

**Response (201):**
```json
{
  "rutina_id": "uuid",
  "creado_en": "2026-04-19T10:30:00Z"
}
```

### 5.4 Registrar sesión completada

```
POST /sesiones/registro
```

**Request:**
```json
{
  "rutina_id": "uuid",
  "duracion_minutos": 55,
  "calorias_quemadas": 340,
  "rpe": 7,
  "registros_ejercicio": [
    { "ejercicio_id": "uuid", "series_completadas": 4, "repeticiones_completadas": 8 }
  ]
}
```

---

## 6. Módulo de Retos

### 6.1 Crear reto simple

```
POST /retos/simple
```

**Request:**
```json
{
  "titulo": "50 flexiones al día",
  "tipo": "fitness",
  "meta": "50 flexiones diarias durante 30 días",
  "fecha_inicio": "2026-04-20",
  "fecha_fin": "2026-05-20",
  "visibilidad": "publico"
}
```

### 6.2 Crear reto complejo

```
POST /retos/complejo
```

**Request:**
```json
{
  "titulo": "Preparar examen final Cálculo II",
  "tipo": "academic",
  "hitos": [
    { "titulo": "Repasar temas 1-3", "orden": 1 },
    { "titulo": "Resolver ejercicios tipo examen", "orden": 2 },
    { "titulo": "Examen preparatorio", "orden": 3 }
  ],
  "fecha_inicio": "2026-04-20",
  "fecha_fin": "2026-06-01",
  "visibilidad": "solo_amigos"
}
```

### 6.3 Detalle de reto

```
GET /retos/{retoId}
```

### 6.4 Registrar progreso

```
POST /retos/{retoId}/progreso
```

**Request:**
```json
{
  "hito_id": "uuid",
  "cantidad_completada": 25.5
}
```

### 6.5 Clonar reto público (RPC)

```
POST /rpc/clonar_reto_publico
```

**Request:**
```json
{
  "reto_id": "uuid"
}
```

---

## 7. Módulo Social

### 7.1 Obtener muro

```
GET /muro?periodo={today|week|month}&limite=20&cursor={cursor}
```

### 7.2 Dar/quitar me gusta

```
POST /muro/{actividadId}/me-gusta
DELETE /muro/{actividadId}/me-gusta
```

### 7.3 Comentar

```
POST /muro/{actividadId}/comentario
```

---

## 8. Módulo de Notificaciones

### 8.1 Obtener notificaciones

```
GET /notificaciones?prioridad={critical|recommended|informative}&limite=20
```

### 8.2 Marcar como leída

```
PATCH /notificaciones/{notificacionId}
```

**Request:**
```json
{
  "esta_leida": true
}
```

### 8.3 Actualizar preferencias

```
PATCH /notificaciones/preferencias
```

**Request:**
```json
{
  "recordatorio_estudio": true,
  "recordatorio_retos": true,
  "recordatorio_bienestar": true,
  "franja_silencio_inicio": "22:00",
  "franja_silencio_fin": "08:00",
  "limite_diario_envios": 10
}
```

---

## 9. Módulo de Bienestar

### 9.1 Obtener tablero del dashboard

```
GET /usuarios/{usuarioId}/tablero
```

### 9.2 Generar plan semanal recomendado

```
POST /bienestar/plan-semanal
```

**Request:**
```json
{
  "semana_inicio": "2026-04-20"
}
```

### 9.3 Obtener URL firmada de multimedia

```
GET /ejercicios/{ejercicioId}/media
```

**Response (200):**
```json
{
  "url_firmada": "https://r2.dev/...?signature=...",
  "expira_en": "2026-04-19T11:30:00Z"
}
```

---

**Documento compilado:** 19-04-2026  
**Última revisión:** v1.0  
**Referencia:** Contratos consolidados desde RFC v2.5 y especificaciones de pantallas v1.0
