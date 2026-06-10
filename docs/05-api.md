# 05 - Interacción con APIs

**Proyecto:** SynaptixFit  
**Versión:** 2.0  
**Fecha:** 08-06-2026  
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

El acceso a imágenes/videos de ejercicios se hace mediante URLs públicas de R2, servidas a través de un Worker proxy de Cloudflare.

### 4.1 Worker proxy

**Archivo:** `cloudflare/synaptixfit-r2-proxy/worker.js`

El Worker:
1. Recibe peticiones a `https://r2-proxy.synaptixfit.workers.dev/{path}`
2. Verifica origen (CORS)
3. Sirve el objeto desde R2
4. Cachea en Cloudflare CDN (TTL 24h)

### 4.2 Subida de contenido

Las imágenes/videos se suben mediante scripts Python de seeding (no desde Flutter en MVP). El formato de URL almacenado en `ejercicios.url_imagen` es la ruta relativa dentro del bucket.

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
**Última revisión:** v2.0
