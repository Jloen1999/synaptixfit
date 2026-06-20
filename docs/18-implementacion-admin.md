# 18 — Implementación del Panel de Administración v2

**Versión:** 1.1  
**Fecha:** 15-06-2026  
**Estado:** FASE 3 COMPLETADA — 15/06/2026. Hub con 5 tabs (KPIs, Usuarios, Contenido, Ejercicios, Auditoría), 34 archivos en `admin/`, migraciones 0006, 0009 y 0010 desplegadas. Delete user (hard delete), configuración de usuario, gráfico de tendencia KPIs con `fl_chart`, filtros y ordenamiento en lista de usuarios, `errorBuilder` en todas las imágenes.  
**Propósito:** Guía de implementación por fases del panel de administración v6.8, basado en el diseño arquitectónico documentado en `03-architecture.md` y `06-frontend.md`.

---

## 1. Resumen Ejecutivo

El panel de administración v2 amplía el panel actual (v1: roles, wipe, lista básica) con 5 módulos nuevos: dashboard de métricas, moderación de contenido, catálogo de ejercicios admin, logs de auditoría y estadísticas por usuario. En total se crean **24+ archivos nuevos** y se modifican **4 existentes**, más una migración de base de datos.

### Alcance

| Componente | Archivos | Estado actual |
|------------|----------|---------------|
| Migración BD | 1 nuevo (`0009`) | ✅ Desplegada |
| Domain (DTOs) | 3 nuevos + 1 existente | ✅ Implementado (4 total) |
| Infrastructure (Repositorios) | 2 nuevos + 1 existente | ✅ Implementado (3 total) |
| Application (Providers) | 2 nuevos + 1 extendido | ✅ Implementado |
| Presentation (Widgets) | 6 widgets + 3 pantallas | ✅ Implementado (Hub con 3 tabs) |
| Routing | 1 modificación (`app_router.dart`) | ✅ `AdminHubScreen` |

### Diseño de referencia

El diseño arquitectónico completo está documentado en:
- `03-architecture.md` §4 — Árbol de carpetas `admin/`
- `04-data-model.md` §16 — Tabla `admin_auditoria`, vista `v_admin_metricas`, columnas de moderación
- `06-frontend.md` §20 — Panel de Administración con 12 sub-secciones
- `07-backend.md` — Migración 0009
- `00-plan-maestro.md` — Módulos A-E

---

## 2. Fases de Implementación

### Fase 0 — Corrección de bugs previos

**Objetivo:** Estabilizar el código admin existente antes de añadir nuevas funcionalidades.

**Duración estimada:** 0.5h

- [x] Avatar fallback en lista de usuarios y feed (manejar `url_avatar` null con placeholder)
- [x] `flutter analyze` a 0 issues en `app/`
- [x] Verificar `esAdminProvider` con rol real de BD (función `es_admin()`)
- [x] Revisar que `AdminWipeDialog` registre correctamente en `admin_auditoria` (si la tabla ya existe)

**Archivos modificados:**

| Archivo | Cambio |
|---------|--------|
| `app/lib/features/admin/presentation/admin_panel_screen.dart` | Avatar fallback |
| `app/lib/features/admin/presentation/admin_usuario_detalle.dart` | Avatar fallback en perfil |
| `app/lib/features/admin/presentation/widgets/admin_wipe_dialog.dart` | Revisar integración con `admin_auditoria` |

**Verificación:**
```bash
flutter analyze                    # 0 issues, 0 warnings
flutter test                        # Todos los tests pasando
```

---

### Fase 1 — MVP: Hub + KPIs + Paginación + Auditoría

**Objetivo:** Implementar el núcleo del panel v2: navegación por tabs, dashboard de métricas globales, lista paginada de usuarios y trazabilidad de acciones.

**Duración estimada:** 8h

#### 1.1 Migración de base de datos

- [x] Crear `supabase/migrations/20260616000009_admin_panel_v2.sql`

**Contenido de la migración:**
- **Tabla `admin_auditoria`:** `id` UUID PK, `admin_id` FK→usuarios, `target_usuario_id` FK→usuarios, `accion` TEXT CHECK (wipe/reset_xp/set_nivel/ocultar_ejercicio/moderar), `detalles` JSONB, `creado_en` TIMESTAMPTZ DEFAULT now(). Índices en `admin_id`, `target_usuario_id`, `creado_en`. RLS: SELECT + INSERT solo admin.
- **Vista `v_admin_metricas`:** 10 KPIs agregados (total_usuarios, nuevos_esta_semana, usuarios_activos_semana, sesiones_esta_semana, retos_creados_semana, publicaciones_semana, publicaciones_reportadas, comentarios_reportados, insignias_otorgadas, nivel_promedio).
- **ALTER `actividades_sociales`:** ADD `reportado` BOOLEAN DEFAULT false, `reportado_por` UUID FK→usuarios, `esta_eliminado` BOOLEAN DEFAULT false, `eliminado_por` UUID FK→usuarios, `eliminado_en` TIMESTAMPTZ.
- **ALTER `comentarios_feed`:** ADD `reportado` BOOLEAN DEFAULT false, `reportado_por` UUID FK→usuarios.
- **ALTER `ejercicios`:** ADD `activo` BOOLEAN DEFAULT true + índice.
- **RLS políticas admin:** UPDATE/DELETE en `actividades_sociales`, UPDATE en `comentarios_feed`, UPDATE en `ejercicios` usando `es_admin()`.

- [x] Desplegar migración: `supabase db push`

#### 1.2 Domain — DTOs (4 implementados de 5 planeados)

| # | Archivo | DTO | Estado |
|---|---------|-----|--------|
| 1 | `app/lib/features/admin/domain/admin_kpi_dto.dart` | `AdminMetricasGlobales` — 10 campos + `fromMap` | ✅ |
| 2 | `app/lib/features/admin/domain/admin_contenido_dto.dart` | `ContenidoReportado` | ✅ |
| 3 | `app/lib/features/admin/domain/admin_auditoria_dto.dart` | `AuditoriaRegistro` + enum `AccionAuditoria` | ✅ |
| 4 | `app/lib/features/admin/domain/admin_dto.dart` | `UsuarioAdmin` (existente, mantenido) | ✅ |
| 5 | `app/lib/features/admin/domain/admin_ejercicio_dto.dart` | `EjercicioAdmin` con campo `activo` | ✅ Fase 2 |
| 6 | `app/lib/features/admin/domain/admin_usuario_estadisticas_dto.dart` | `UsuarioEstadisticas` — RPE, volumen semanal | ✅ Fase 2 |

#### 1.3 Infrastructure — Repositorios (3 implementados de 5 planeados)

| # | Archivo | Métodos principales | Estado |
|---|---------|---------------------|--------|
| 1 | `app/lib/features/admin/infrastructure/admin_metricas_repository.dart` | `obtenerMetricasGlobales()`, `obtenerRegistrosDiarios()` | ✅ |
| 2 | `app/lib/features/admin/infrastructure/admin_auditoria_repository.dart` | `insertarAuditoria()`, `consultarLogs()` | ✅ |
| 3 | `app/lib/features/admin/infrastructure/admin_repository.dart` | `listarUsuarios()`, `obtenerDetalle()`, `resetXp()`, `setNivel()` | ✅ |
| 4 | `app/lib/features/admin/infrastructure/admin_contenido_repository.dart` | CRUD moderación publicaciones/comentarios | ✅ Fase 2 |
| 5 | `app/lib/features/admin/infrastructure/admin_ejercicio_repository.dart` | `listarEjerciciosAdmin()`, `toggleActivo()` | ✅ Fase 2 |
| 6 | `app/lib/features/admin/infrastructure/admin_usuario_stats_repository.dart` | RPE semanal, volumen, timeline por usuario | ✅ Fase 2 |

#### 1.4 Application — Providers (3 archivos: 1 extendido + 2 nuevos)

| # | Archivo | Providers / Mutaciones | Estado |
|---|---------|------------------------|--------|
| ★ | `app/lib/features/admin/application/admin_provider.dart` | **Extendido:** `esAdminProvider`, `adminUsuariosProvider`, `adminUsuarioDetalleProvider`, `resetXpUsuario()`, `setNivelUsuario()` | ✅ |
| 1 | `app/lib/features/admin/application/admin_metricas_provider.dart` | `adminMetricasProvider`, `adminRegistrosDiariosProvider` | ✅ |
| 2 | `app/lib/features/admin/application/admin_auditoria_provider.dart` | `adminAuditoriaProvider`, `registrarAuditoria()` | ✅ |
| 3 | `app/lib/features/admin/application/admin_contenido_provider.dart` | `adminContenidoReportadoProvider`, `moderarPublicacion()`, `moderarComentario()` | ✅ Fase 2 |
| 4 | `app/lib/features/admin/application/admin_ejercicio_provider.dart` | `adminEjerciciosProvider`, `adminEjercicioToggleProvider` | ✅ Fase 2 |
| 5 | `app/lib/features/admin/application/admin_usuario_stats_provider.dart` | `adminUsuarioStatsProvider`, `adminUsuarioTimelineProvider` | ✅ Fase 2 |

#### 1.5 Presentation — Widgets (6 widgets + 3 pantallas; 9 implementados de 10 planeados)

| # | Archivo | Descripción | Estado |
|---|---------|-------------|--------|
| 1 | `app/lib/features/admin/presentation/admin_hub_screen.dart` | **Nuevo.** `ConsumerStatefulWidget` con `TabController(length: 3)`: KPIs, Usuarios, Auditoría | ✅ |
| 2 | `app/lib/features/admin/presentation/admin_panel_screen.dart` | **Refactor.** Lógica de lista movida a pestaña "Usuarios" dentro del Hub, con búsqueda y acciones | ✅ |
| 3 | `app/lib/features/admin/presentation/admin_usuario_detalle.dart` | **Enriquecido.** 3 sub-pestañas con `TabBarView`: Perfil (datos + acciones admin), Estadísticas, Timeline | ✅ |
| 4 | `app/lib/features/admin/presentation/widgets/admin_kpi_dashboard.dart` | **Nuevo.** Grid 2×3 de `AdminKpiCard` | ✅ |
| 5 | `app/lib/features/admin/presentation/widgets/admin_kpi_card.dart` | **Nuevo.** Card individual con icono, valor numérico, tendencia (↑↓→) | ✅ |
| 6 | `app/lib/features/admin/presentation/widgets/admin_log_entry.dart` | **Nuevo.** Fila de log con badge de color por tipo de acción, timestamp | ✅ |
| 7 | `app/lib/features/admin/presentation/widgets/admin_auditoria_list.dart` | **Nuevo.** Lista de registros de auditoría con paginación | ✅ |
| 8 | `app/lib/features/admin/presentation/widgets/admin_paginacion_bar.dart` | **Nuevo.** Barra reutilizable con indicador de página + flechas ← → | ✅ |
| 9 | `app/lib/features/admin/presentation/widgets/admin_wipe_dialog.dart` | **Refactor.** Añadido registro en `admin_auditoria` tras confirmación | ✅ |
| 10 | `app/lib/features/admin/presentation/widgets/admin_lista_usuarios.dart` | Widget independiente para lista paginada | ✅ Fase 1 |

#### 1.6 Routing

- [x] Modificar `app/lib/core/routing/app_router.dart`: ruta `/admin` → `AdminHubScreen` (reemplaza `AdminPanelScreen`)

#### 1.7 Verificación Fase 1

```bash
flutter analyze                    # 0 issues, 0 warnings
flutter test                        # Todos los tests pasando
supabase db push                    # Migración desplegada sin errores
```

---

### Fase 2 — Completo: Moderación + Ejercicios + Gráficos + Timeline ✅ COMPLETADO — 15/06/2026

**Objetivo:** Completar los 5 tabs con funcionalidad real: moderación de contenido reportado, toggle de ejercicios activo/inactivo, gráficos de rendimiento por usuario y timeline de actividad.

**Duración estimada:** 6h

#### 2.1 Domain (3 nuevos)

| # | Archivo | DTO | Estado |
|---|---------|-----|--------|
| 1 | `app/lib/features/admin/domain/admin_ejercicio_dto.dart` | `AdminEjercicio` con campo `activo` | ✅ |
| 2 | `app/lib/features/admin/domain/admin_usuario_estadisticas_dto.dart` | `AdminUsuarioEstadisticas` + `AdminDataPoint` — RPE, volumen semanal | ✅ |
| 3 | `app/lib/features/admin/domain/admin_timeline_dto.dart` | `AdminTimelineEntry` + enum `TimelineTipoAdmin` | ✅ |

#### 2.2 Infrastructure (3 nuevos)

| # | Archivo | Métodos principales | Estado |
|---|---------|---------------------|--------|
| 1 | `app/lib/features/admin/infrastructure/admin_contenido_repository.dart` | `listarContenidoReportado()`, `aprobarContenido()`, `eliminarContenido()` | ✅ |
| 2 | `app/lib/features/admin/infrastructure/admin_ejercicio_repository.dart` | `listarEjercicios()`, `toggleActivo()` | ✅ |
| 3 | `app/lib/features/admin/infrastructure/admin_usuario_stats_repository.dart` | `obtenerRpeSemanal()`, `obtenerVolumenSemanal()`, `obtenerTimeline()` | ✅ |

#### 2.3 Application (3 nuevos)

| # | Archivo | Providers / Mutaciones | Estado |
|---|---------|------------------------|--------|
| 1 | `app/lib/features/admin/application/admin_contenido_provider.dart` | `adminContenidoReportadoProvider`, `moderarPublicacion()`, `moderarComentario()` | ✅ |
| 2 | `app/lib/features/admin/application/admin_ejercicio_provider.dart` | `adminEjerciciosProvider`, `adminEjercicioToggleProvider` | ✅ |
| 3 | `app/lib/features/admin/application/admin_usuario_stats_provider.dart` | `adminUsuarioStatsProvider`, `adminUsuarioTimelineProvider` | ✅ |

#### 2.4 Presentation — Widgets (6 nuevos + 2 modificados)

| # | Archivo | Descripción | Estado |
|---|---------|-------------|--------|
| 1 | `app/lib/features/admin/presentation/widgets/admin_contenido_card.dart` | **Nuevo.** Card de contenido reportado con botones aprobar/eliminar | ✅ |
| 2 | `app/lib/features/admin/presentation/widgets/admin_contenido_list.dart` | **Nuevo.** `ListView` paginada de publicaciones/comentarios reportados. Acciones: ocultar/restaurar, registra en `admin_auditoria` | ✅ |
| 3 | `app/lib/features/admin/presentation/widgets/admin_ejercicio_card.dart` | **Nuevo.** Card individual con nombre, grupo muscular, switch `activo`/`inactivo`. Confirmación con `AlertDialog`, registra en `admin_auditoria` | ✅ |
| 4 | `app/lib/features/admin/presentation/widgets/admin_ejercicio_list.dart` | **Nuevo.** Lista paginada de ejercicios con búsqueda por nombre/dificultad/grupo | ✅ |
| 5 | `app/lib/features/admin/presentation/widgets/admin_graficos_usuario.dart` | **Nuevo.** `LineChart` de RPE semanal + `BarChart` de volumen semanal usando `fl_chart` | ✅ |
| 6 | `app/lib/features/admin/presentation/widgets/admin_timeline_usuario.dart` | **Nuevo.** Línea de tiempo cronológica con `TimelineItem`, agrupada por día | ✅ |
| ★ | `app/lib/features/admin/presentation/admin_usuario_detalle.dart` | **Modificado.** Placeholders reemplazados por `AdminGraficosUsuario` y `AdminTimelineUsuario` reales | ✅ |
| ★ | `app/lib/features/admin/presentation/admin_hub_screen.dart` | **Modificado.** `TabController(length: 3)` → `TabController(length: 5)`; añadidos tabs Contenido y Ejercicios | ✅ |

#### 2.2 Verificación Fase 2

```bash
flutter analyze                    # 0 issues, 0 warnings
flutter test                        # Todos los tests pasando
```

---

### Fase 3 — Final: Delete User, Configuración, Gráfico KPIs ✅ COMPLETADO — 15/06/2026

**Objetivo:** Completar funcionalidades finales del panel: eliminación hard de usuarios, configuración de usuario desde admin, gráfico de tendencia en dashboard KPIs, filtros avanzados y ordenamiento.

**Duración estimada:** 3h

#### 3.1 Migración `20260616000010_admin_delete_user.sql`

- **RPC `delete_user(p_usuario_id)`:** eliminación hard de usuario con cascada FK-safe de 28+ tablas:
  - Elimina historial (sesiones, rutinas, retos, interacciones, notificaciones, etc.)
  - Elimina perfiles (`perfil_bienestar_usuario`, `perfil_academico_usuario`)
  - Elimina `usuario_carreras`, `asignaturas_usuario_semestre`
  - Elimina `admin_auditoria` donde el usuario fue target
  - Elimina de `public.usuarios`
  - Elimina de `auth.users`
- **Seguridad:** `SECURITY DEFINER`, verifica `rol = 'admin'`, no puede auto-eliminarse.

#### 3.2 AdminRepository — `deleteUser()` y consulta ampliada

| Método | Descripción | Estado |
|--------|-------------|--------|
| `deleteUser(usuarioId)` | Invoca RPC `delete_user(p_usuario_id)` | ✅ |
| `obtenerDetalleUsuario(usuarioId)` | Ampliado con LEFT JOIN a `perfil_bienestar_usuario`, `perfil_academico_usuario` y subconsultas COUNT para sesiones, rutinas, retos, insignias | ✅ |

#### 3.3 AdminProvider — `eliminarUsuario()` y mutaciones de configuración

| Mutación | Descripción | Estado |
|----------|-------------|--------|
| `eliminarUsuario(usuarioId, ref)` | Invoca `deleteUser()`, registra en `admin_auditoria`, invalida listado | ✅ |
| `editarNombreUsuario(usuarioId, nombre, ref)` | UPDATE `usuarios.nombre_completo`, registra en auditoría | ✅ |
| `editarEmailUsuario(usuarioId, email, ref)` | UPDATE `usuarios.email`, registra en auditoría | ✅ |

#### 3.4 Presentation — Widgets mejorados

| Archivo | Cambio | Estado |
|---------|--------|--------|
| `admin_panel_screen.dart` | Añadido botón "Eliminar" en PopupMenuButton, filtros por rol, ordenamiento por fecha/nivel/XP | ✅ |
| `admin_usuario_detalle.dart` | Nueva sección "Configuración" con edición de nombre/email, reset XP, cambiar nivel, botón eliminar. Sección "Actividad reciente" con conteos reales de retos/rutinas/insignias | ✅ |
| `admin_kpi_dashboard.dart` | Añadido `LineChart` de `fl_chart` mostrando tendencia de registros diarios 30 días bajo el grid de KPIs | ✅ |
| `admin_wipe_dialog.dart` | Añadido `errorBuilder` en `Image.network` | ✅ |

#### 3.5 Fix de imágenes

- `errorBuilder` añadido a todos los `Image.network` en `AdminPanelScreen` y `AdminUsuarioDetalle` para manejar avatares con URL inválida mostrando fallback con inicial del nombre.

#### 3.6 Verificación Fase 3

```bash
flutter analyze                    # 0 issues, 0 warnings
flutter test                        # Todos los tests pasando
supabase db push                    # Migración 0010 desplegada
```

---

### Post-implementación

- [ ] Actualizar `AGENTS.md`: migraciones 11→12 (con `0009` real), módulo `admin/` con sub-componentes reales
- [ ] Actualizar `docs/14-changelog.md`: añadir PRs/commits reales en entrada `[6.7.0]`
- [ ] Actualizar `docs/18-implementacion-admin.md`: marcar fases como `[x]` con fechas reales
- [ ] `dart format .` en `app/`
- [ ] `flutter test --coverage`
- [ ] Commit siguiendo convención: `feat: [Admin] Panel de administración v2 — Fase X completada`

---

## 3. Referencia Rápida de Archivos

### Archivos creados en Fase 1 MVP (14 nuevos + 5 modificados)

| Fase | Archivo | Tipo | Estado |
|------|---------|------|--------|
| 1 | `supabase/migrations/20260616000009_admin_panel_v2.sql` | Migración BD | ✅ |
| 1 | `app/lib/features/admin/domain/admin_kpi_dto.dart` | DTO | ✅ |
| 1 | `app/lib/features/admin/domain/admin_auditoria_dto.dart` | DTO | ✅ |
| 1 | `app/lib/features/admin/domain/admin_contenido_dto.dart` | DTO | ✅ |
| 1 | `app/lib/features/admin/infrastructure/admin_metricas_repository.dart` | Repository | ✅ |
| 1 | `app/lib/features/admin/infrastructure/admin_auditoria_repository.dart` | Repository | ✅ |
| 1 | `app/lib/features/admin/application/admin_metricas_provider.dart` | Provider | ✅ |
| 1 | `app/lib/features/admin/application/admin_auditoria_provider.dart` | Provider | ✅ |
| 1 | `app/lib/features/admin/presentation/admin_hub_screen.dart` | Widget (Hub) | ✅ |
| 1 | `app/lib/features/admin/presentation/widgets/admin_kpi_dashboard.dart` | Widget | ✅ |
| 1 | `app/lib/features/admin/presentation/widgets/admin_kpi_card.dart` | Widget | ✅ |
| 1 | `app/lib/features/admin/presentation/widgets/admin_log_entry.dart` | Widget | ✅ |
| 1 | `app/lib/features/admin/presentation/widgets/admin_auditoria_list.dart` | Widget | ✅ |
| 1 | `app/lib/features/admin/presentation/widgets/admin_paginacion_bar.dart` | Widget | ✅ |

### Archivos modificados en Fase 1 MVP (5 existentes)

| Fase | Archivo | Tipo de cambio |
|------|---------|----------------|
| 1 | `app/lib/features/admin/presentation/admin_panel_screen.dart` | Refactor: pestaña "Usuarios" dentro de `AdminHubScreen`, búsqueda y acciones |
| 1 | `app/lib/features/admin/presentation/admin_usuario_detalle.dart` | Enriquecido: 3 sub-pestañas (Perfil/Estadísticas/Timeline) |
| 1 | `app/lib/features/admin/presentation/widgets/admin_wipe_dialog.dart` | Refactor: registro en `admin_auditoria` |
| 1 | `app/lib/features/admin/application/admin_provider.dart` | Extendido: `registrarAuditoria()` integrado |
| 1 | `app/lib/core/routing/app_router.dart` | Ruta `/admin` → `AdminHubScreen` |

### Archivos implementados en Fase 2 (15 nuevos + 2 modificados)

| Fase | Archivo | Tipo |
|------|---------|------|
| 2 | `app/lib/features/admin/domain/admin_ejercicio_dto.dart` | DTO — `AdminEjercicio` |
| 2 | `app/lib/features/admin/domain/admin_usuario_estadisticas_dto.dart` | DTO — `AdminUsuarioEstadisticas` + `AdminDataPoint` |
| 2 | `app/lib/features/admin/domain/admin_timeline_dto.dart` | DTO — `AdminTimelineEntry` + enum `TimelineTipoAdmin` |
| 2 | `app/lib/features/admin/infrastructure/admin_contenido_repository.dart` | Repository — `listarContenidoReportado()`, `aprobarContenido()`, `eliminarContenido()` |
| 2 | `app/lib/features/admin/infrastructure/admin_ejercicio_repository.dart` | Repository — `listarEjercicios()`, `toggleActivo()` |
| 2 | `app/lib/features/admin/infrastructure/admin_usuario_stats_repository.dart` | Repository — `obtenerRpeSemanal()`, `obtenerVolumenSemanal()`, `obtenerTimeline()` |
| 2 | `app/lib/features/admin/application/admin_contenido_provider.dart` | Provider — moderación + mutaciones |
| 2 | `app/lib/features/admin/application/admin_ejercicio_provider.dart` | Provider — catálogo + toggle |
| 2 | `app/lib/features/admin/application/admin_usuario_stats_provider.dart` | Provider — gráficos + timeline |
| 2 | `app/lib/features/admin/presentation/widgets/admin_contenido_card.dart` | Widget — Card con botones aprobar/eliminar |
| 2 | `app/lib/features/admin/presentation/widgets/admin_contenido_list.dart` | Widget — Lista paginada de contenido reportado |
| 2 | `app/lib/features/admin/presentation/widgets/admin_ejercicio_card.dart` | Widget — Card con Switch activo/inactivo |
| 2 | `app/lib/features/admin/presentation/widgets/admin_ejercicio_list.dart` | Widget — Lista paginada de ejercicios con búsqueda |
| 2 | `app/lib/features/admin/presentation/widgets/admin_graficos_usuario.dart` | Widget — Gráficos fl_chart (LineChart RPE + BarChart volumen) |
| 2 | `app/lib/features/admin/presentation/widgets/admin_timeline_usuario.dart` | Widget — Timeline vertical de actividad |

### Archivos modificados en Fase 2 (2 existentes)

| Fase | Archivo | Tipo de cambio |
|------|---------|----------------|
| 2 | `app/lib/features/admin/presentation/admin_usuario_detalle.dart` | Placeholders reemplazados por `AdminGraficosUsuario` y `AdminTimelineUsuario` reales |
| 2 | `app/lib/features/admin/presentation/admin_hub_screen.dart` | `TabController(length: 3)` → `TabController(length: 5)`; añadidos tabs Contenido y Ejercicios |

---

## 4. Checklist de Verificación por Fase

### Fase 0 ✅ COMPLETADO — 15/06/2026

- [x] `flutter analyze` → 0 issues, 0 warnings
- [x] Avatar fallback funciona con `url_avatar` null
- [x] `esAdminProvider` devuelve `true` para usuarios con rol `admin`
- [x] `AdminWipeDialog` no crashea si `admin_auditoria` no existe

### Fase 1 ✅ COMPLETADO — 15/06/2026

- [x] Migración `0009` creada y desplegada (`supabase db push`)
- [x] `v_admin_metricas` devuelve KPIs sin errores
- [x] `AdminHubScreen` renderiza TabBar con 3 tabs (KPIs, Usuarios, Auditoría)
- [x] Tab "KPIs": grid 2×3 visible con datos reales
- [x] Tab "Usuarios": búsqueda funcional, acciones admin (reset XP, set nivel, wipe)
- [x] Tab "Auditoría": registros de auditoría visibles con paginación
- [x] Tabs "Contenido" y "Ejercicios": implementados en Fase 2 ✅
- [x] `flutter analyze` → 0 issues, 0 warnings

### Fase 2 ✅ COMPLETADO — 15/06/2026

- [x] Tab "Contenido": publicaciones/comentarios reportados visibles, ocultar/restaurar funcional
- [x] Tab "Ejercicios": toggle `activo`/`inactivo` con confirmación
- [x] `admin_auditoria` registra acciones de moderación y ejercicios
- [x] `AdminUsuarioDetalle`: 3 sub-pestañas funcionales (Perfil / Estadísticas / Timeline)
- [x] Gráficos `fl_chart` renderizan sin errores (LineChart RPE, BarChart volumen)
- [x] Timeline muestra actividad real del usuario
- [x] `flutter analyze` → 0 issues, 0 warnings
- [x] `flutter test` → todos pasando

### Fase 3 ✅ COMPLETADO — 15/06/2026

- [x] Migración `0010` creada con RPC `delete_user(p_usuario_id)` (28+ tablas + auth.users)
- [x] Botón "Eliminar usuario" funcional en lista y detalle
- [x] `AdminUsuarioDetalle` con sección de configuración (editar nombre/email, reset XP, cambiar nivel)
- [x] `AdminKpiDashboard` con gráfico de tendencia 30 días (fl_chart LineChart)
- [x] Filtros por email/nombre/rol y ordenamiento por fecha/nivel/XP en `AdminPanelScreen`
- [x] `errorBuilder` en todos los `Image.network` del panel admin
- [x] `flutter analyze` → 0 issues, 0 warnings
- [x] `flutter test` → todos pasando

### Post-implementación ✅ COMPLETADO — 15/06/2026

- [x] `AGENTS.md` actualizado: 26 migraciones (incluyendo 0010-0025), módulo admin con delete_user, configuración, gráfico KPIs
- [x] `docs/14-changelog.md`: entrada `[6.8.0]` añadida con Fase 3 completa
- [x] `docs/18-implementacion-admin.md`: Fases 0-3 marcadas como `[x]` con fechas reales
- [x] `docs/04-data-model.md` → v5.5: RPC `delete_user` documentada con SQL, comparativa wipe vs delete
- [x] `docs/06-frontend.md`: §20 actualizado con delete user, gráfico tendencia, filtros, configuración
- [x] `docs/07-backend.md`: migración 0010 añadida al historial
- [x] `docs/00-plan-maestro.md` → v1.6: módulos F-I añadidos (Delete User, Gráfico KPIs, Filtros, Configuración)
- [x] `dart format .` ejecutado
- [x] `flutter analyze` → 0 issues, 0 warnings

---

## 5. Notas Técnicas

### Dependencias existentes (no requieren nuevas)

- `fl_chart: ^0.70.0` — ya está en `pubspec.yaml` (usado por analítica)
- `supabase_flutter` — SDK principal para queries
- `flutter_riverpod` — state management
- `go_router` — navegación

### Convenciones

- **Idioma:** Código en inglés, comentarios DartDoc en español
- **Capas:** domain/ → infrastructure/ → application/ → presentation/
- **Providers:** Riverpod `FutureProvider.family` para queries parametrizados, `StateNotifierProvider` para mutaciones
- **DTOs:** Clases inmutables con `fromMap(Map<String, dynamic>)` factory
- **Repositorios:** Clases con métodos async que llaman a `Supabase.instance.client`

### RLS y Seguridad

- Todas las queries admin usan `es_admin()` para bypassear RLS
- La migración 0006 (`admin_rol.sql`) ya implementa `es_admin()` y políticas base
- La migración 0009 añade políticas específicas para tablas de moderación y ejercicios
- `admin_auditoria` es append-only (solo INSERT + SELECT, no UPDATE ni DELETE)

---

**Fin del documento de implementación.**
