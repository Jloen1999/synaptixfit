# 05 - Interacción con APIs

**Proyecto:** SynaptixFit  
**Versión:** 2.1  
**Fecha:** 24-06-2026  
**Referencia:** [03-architecture.md](03-architecture.md) (sección 8)

---

## 1. Arquitectura de Comunicación

SynaptixFit **no usa un backend REST tradicional**. No hay Edge Functions de Supabase ni servidores Node.js/Express. Toda la lógica de negocio se ejecuta en el cliente Flutter (Dart).

### 1.1 Canales de comunicación

```
┌───────────────┐     Supabase SDK (PostgREST)     ┌──────────────┐
│               │ ◄──────────────────────────────► │  Supabase    │
│               │     Auth (OAuth / Magic Link)     │  (PostgreSQL │
│               │ ◄──────────────────────────────► │   + Auth +   │
│   Flutter     │     Realtime (WebSocket)          │   Realtime)  │
│   App (Dart)  │ ◄──────────────────────────────► │              │
│               │                                   └──────────────┘
│               │     Gemini API (Dio HTTP)              ┌──────────────┐
│               │ ◄──────────────────────────────────► │  Google      │
│               │                                      │  Gemini      │
│               │     Cloudflare R2 (Worker proxy)     │  Flash API   │
│               │ ◄──────────────────────────────────► └──────────────┘
│               │                                      ┌──────────────┐
│               │                                      │  Cloudflare  │
│               │                                      │  R2 + Worker │
└───────────────┘                                      └──────────────┘
```

### 1.2 Autenticación (Supabase Auth)

La autenticación usa el SDK `supabase_flutter` directamente. No hay endpoints REST de login/registro.

| Proveedor | Método | Código en `app/lib/features/auth/` |
|-----------|--------|-----------------------------------|
| Google OAuth | `Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google)` | Flujo nativo + redirect URI |
| Magic Link (email) | `Supabase.instance.client.auth.signInWithOtp(email: email)` | Sin contraseña |
| Correo/contraseña | `auth.signInWithPassword()`, `auth.updateUser()` | Post-registro |

El estado de sesión se maneja mediante `supabase.auth.onAuthStateChange` y se persiste automáticamente.

---

## 2. Acceso a Datos (PostgREST vía Supabase SDK)

Todas las operaciones CRUD se ejecutan mediante el cliente Supabase Dart, que usa PostgREST internamente.

### 2.1 Convenciones de consulta

| Operación | Código Dart (ejemplo) |
|-----------|----------------------|
| SELECT | `supabase.from('ejercicios').select('id,nombre')` |
| INSERT | `supabase.from('rutinas').insert({'nombre': '...'})` |
| UPDATE | `supabase.from('ejercicios').update({'nombre': '...'}).eq('id', id)` |
| DELETE | `supabase.from('ejercicios').delete().eq('id', id)` |
| RPC | `supabase.rpc('funcion_pg', params: {...})` |
| Stream (Realtime) | `supabase.from('ejercicios').stream()` |

### 2.2 Vistas principales

| Vista | Propósito | Consulta típica |
|-------|-----------|----------------|
| `v_ejercicios_completos` | Catálogo con arrays de catálogos pre-calculados | `supabase.from('v_ejercicios_completos').select('*')` |
| `v_rutinas_comunidad` | Rutinas públicas con nombre de autor | `supabase.from('v_rutinas_comunidad').select('...')` |
| (otras vistas) | Según necesidad del frontend | Definidas en migraciones SQL |

### 2.3 Proveedores de datos (Riverpod)

Los providers en `app/lib/features/*/application/` encapsulan las consultas a Supabase y exponen datos reactivos:

```dart
// Ejemplo: catálogo de ejercicios en tiempo real
final ejerciciosProvider = StreamProvider<List<EjercicioDb>>((ref) {
  return supabase.from('ejercicios').stream();
});

// Ejemplo: consulta one-shot con Family
final ejercicioDetalleProvider = FutureProvider.family<EjercicioDb?, String>((ref, id) async {
  final data = await supabase
      .from('v_ejercicios_completos')
      .select('*')
      .eq('id', id)
      .single();
  return EjercicioDb.fromJson(data);
});
```

---

## 3. Motor de Recomendaciones (Dart, sin API REST)

El sistema de recomendación es un pipeline de 9 servicios Dart que se ejecuta **100% en el cliente**. No hay llamadas REST.

### 3.1 Pipeline (Fases 0-9)

| Fase | Servicio | Archivo |
|------|----------|---------|
| 0 | Sanitización de objetivo | `string_utils.dart` |
| 1 | Reglas de distribución | `recomendacion_reglas_service.dart` |
| 2 | Contexto de usuario | `recomendacion_contexto_service.dart` |
| 3 | Transiciones entre objetivos | `recomendacion_transicion_service.dart` |
| 4 | Progresión de carga | `recomendacion_progresion_service.dart` |
| 5 | Refuerzo muscular | `recomendacion_refuerzo_service.dart` |
| 6 | Peso/rep RPE | `recomendacion_peso_service.dart` |
| 7 | Validación+Fill | `recomendacion_validacion_service.dart` |
| 8 | IA (Gemini, opcional) | `recomendacion_ia_service.dart` |
| 9 | Renderizado | `recomendacion_render_service.dart` |

### 3.2 Orquestador

```dart
// app/lib/features/bienestar/infrastructure/recomendacion_orquestador_service.dart
class RecomendacionOrquestadorService {
  Future<ResultadoGeneracion> ejecutar({
    required String usuarioId,
    required bool usarIa,
  }) async {
    // 1. Sanitizar objetivo
    // 2. Aplicar reglas de distribución semanal
    // 3. Obtener contexto (check-in, progreso, historial)
    // 4. Detectar transición de objetivo
    // 5. Calcular progresión
    // 6. Refuerzo muscular
    // 7. Calcular pesos/reps/RPE
    // 8. Validar y llenar
    // 9. (Opcional) Refinar con Gemini
    // 10. Renderizar resultado
  }
}
```

### 3.3 IA Gemini (refinamiento opcional)

```dart
// app/lib/features/bienestar/infrastructure/recomendacion_ia_service.dart (1047 líneas)
// 4 prompts: nuevas, comunidad, modificación, adaptación check-in
```

El servicio IA se invoca solo si `usarIa=true` y `GEMINI_API_KEY` está configurada en `.env`.

---

## 4. Multimedia (Cloudflare R2)

El acceso a archivos multimedia (GIFs de ejercicios, archivos de asignaturas) se realiza mediante URLs públicas de R2, servidas a través de un Worker proxy de Cloudflare (`synaptixfit-r2-proxy`).

### 4.1 Worker proxy (GET, PUT, DELETE)

**Archivos:**
- `cloudflare/synaptixfit-r2-proxy/worker.js` — código fuente del Worker
- `cloudflare/synaptixfit-r2-proxy/wrangler.jsonc` — configuración de despliegue (binding `R2_BUCKET`)

**Configuración de despliegue (`wrangler.jsonc`):**
```jsonc
{
  "name": "synaptixfit-r2-proxy",
  "main": "worker.js",
  "compatibility_date": "2025-06-23",
  "r2_buckets": [
    {
      "binding": "R2_BUCKET",
      "bucket_name": "synaptixfit-r2"
    }
  ],
  "observability": { "enabled": true }
}
```

El binding `R2_BUCKET` es **obligatorio** para el funcionamiento del Worker. Sin este binding, `env.R2_BUCKET` es `undefined` y todas las operaciones de subida fallan. El Worker incluye una **guarda de verificación** justo después del bloque OPTIONS:

```javascript
// Guarda: verificar que el binding R2_BUCKET existe antes de usarlo
if (!env.R2_BUCKET) {
  console.error('[synaptixfit-r2-proxy] Binding R2_BUCKET no configurado en este Worker.');
  return new Response(JSON.stringify({
    error: 'Configuración incompleta del servidor',
    message: 'El binding R2_BUCKET no está configurado...',
  }), {
    status: 503,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
```

Esta guarda **reemplaza el error 500 genérico** `Cannot read properties of undefined (reading 'put')` por un error 503 descriptivo que indica claramente qué falta configurar.

**Métodos HTTP soportados:**

| Método | Ruta | Propósito | Respuesta |
|--------|------|-----------|-----------|
| `GET` | `/{objectKey}` | Descargar archivo desde R2 | Binario con `Content-Type`, `Cache-Control: immutable`, `ETag` |
| `PUT` | `/{objectKey}` | Subir archivo a R2 | `{ success: true, key, url }` |
| `DELETE` | `/{objectKey}` | Eliminar archivo de R2 | `{ success: true, message, key }` |
| `OPTIONS` | `/*` | Preflight CORS | 204 con headers CORS |

El Worker también expone un endpoint especial con CORS abierto (`*`):
| `POST` | `/_proxy/ics` | Proxy para descargar calendarios ICS (evita CORS) | Texto del calendario |

**CORS:** Restringido para rutas R2 (origen `synaptixfit.com` + `localhost` en desarrollo). Abierto (`*`) para `/_proxy/ics`.

**Caché:** Las respuestas GET incluyen `Cache-Control: public, max-age=31536000, immutable` para aprovechar el CDN de Cloudflare.

### 4.2 Flujo completo de subida de archivos (desde Flutter)

El repositorio `ArchivosAsignaturaRepository` (`app/lib/features/academico/infrastructure/archivos_asignatura_repository.dart`) implementa el siguiente flujo para subir archivos de asignaturas a R2:

```
1. Usuario selecciona archivo → file_picker con withData: true
2. ArchivosAsignaturaRepository.subirArchivo() recibe bytes + metadatos
3. Construye clave de objeto R2:
   usuarios/{user_id}/asignaturas/{asignatura_id}/archivos/{timestamp}_{nombre}
4. Construye URL de subida: {VITE_R2_WORKER_URL}/{objectKey}
   (URL del Worker desde app/.env)
5. Envía HTTP PUT con los bytes del archivo al Worker synaptixfit-r2-proxy
   (Dio con seguimiento de progreso)
6. El Worker recibe la petición, extrae la clave del pathname de la URL
7. El Worker usa env.R2_BUCKET.put(key, body, { httpMetadata: { contentType } })
   para almacenar en R2
8. Si el binding R2_BUCKET no existe → 503 con mensaje descriptivo
9. El Worker responde: { success: true, key, url }
10. El repositorio registra metadatos en la tabla archivos_asignatura (Supabase)
    con cloudflare_object_key, url_publica_o_firmada, tamano_bytes, tipo_mime
11. Si falla el registro en Supabase → rollback best-effort:
    DELETE al Worker para borrar el objeto de R2 ya subido
12. La URL pública se construye usando CLOUDFLARE_R2_BASE_URL (si existe)
    o la URL del Worker como fallback
```

**Convención de claves de objeto:**
```
usuarios/{user_id}/asignaturas/{asignatura_id}/archivos/{timestamp}_{nombre_archivo}
```
Ejemplo: `usuarios/abc-123/asignaturas/def-456/archivos/1719000000_apuntes_matematicas.pdf`

**Subida de contenido multimedia de ejercicios:**
Los GIFs de ejercicios (~1300 archivos, resolución 360×360) se suben mediante scripts Python de seeding (`supabase/seed_catalogo_v2.py`). El formato de URL almacenado en `ejercicios.url_imagen` usa la ruta pública de R2.

---

## 5. Catálogos y Datos Maestros

Los catálogos se consultan directamente a Supabase sin intermediarios:

| Catálogo | Tabla | Frecuencia | Caché |
|----------|-------|-----------|-------|
| Ejercicios | `ejercicios` + `v_ejercicios_completos` | Tiempo real (Stream) | Riverpod |
| Músculos | `musculos` (93 registros) | Al inicio | Provider estático |
| Partes del cuerpo | `partes_cuerpo` (13 registros) | Al inicio | Provider estático |
| Equipamientos | `equipamientos` (23 registros) | Al inicio | Provider estático |
| Universidades | `universidades` | Bajo demanda | Provider lazy |
| Carreras | `carreras` | Bajo demanda | Provider lazy |
| Asignaturas | `asignaturas` | Bajo demanda | Provider lazy |

---

## 6. Funciones RPC de Supabase

Algunas operaciones complejas se implementan como funciones PostgreSQL (RPC) ejecutadas desde Dart:

```dart
final result = await supabase.rpc('nombre_funcion', params: {
  'param1': valor1,
  'param2': valor2,
});
```

Funciones existentes (definidas en migraciones):

| Función | Propósito | Parámetros |
|---------|-----------|------------|
| `trg_dias_rutina_estado()` | Trigger: cascada de estado día→semana | (trigger, automático) |
| (otras funciones PG) | Lógica de base de datos | Según migración |

---

## 7. Comparativa: REST (obsoleto) vs Actual

| Aspecto | Enfoque antiguo (documentación previa) | Enfoque actual |
|---------|--------------------------------------|----------------|
| Backend | Edge Functions REST (Deno) | No existe; lógica en Dart cliente |
| Auth | POST /auth/login, POST /auth/registro | Supabase Auth SDK nativo |
| Rutinas | POST /rutinas (Edge Function) | `supabase.from('rutinas').insert(...)` |
| Recomendación | Edge Function `recomendar_plan_entrenamiento` | Pipeline Dart orquestado (9 servicios) |
| IA | Llamada desde Edge Function | Llamada directa Flutter → Gemini (Dio) |
| Multimedia | Edge Function genera signed URLs | R2 Worker proxy con CORS |
| Notificaciones | Edge Functions + ? | No implementado en MVP |
| Retos | POST /retos/simple, /retos/complejo | `supabase.from('retos').insert(...)` |

---

## 8. Plan de migración futura

Si en el futuro se requiere lógica centralizada (procesamiento pesado, webhooks, tareas programadas), se evaluará:

1. **Supabase Edge Functions** (Deno): para lógica que no debe ejecutarse en cliente
2. **Supabase Cron**: para recordatorios y tareas periódicas
3. **Webhooks externos**: para integraciones con servicios third-party

Por ahora, el motor de recomendaciones completo (Fases 0-9) corre en Dart y está probado.

---

**Documento compilado:** 08-06-2026  
**Última revisión:** v2.1 — Worker R2: documentado `wrangler.jsonc`, binding `R2_BUCKET`, guarda de verificación, flujo completo de subida de archivos (PUT/DELETE), y convención de claves.
