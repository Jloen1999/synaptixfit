# 01 - Introducción

**Proyecto:** SynaptixFit — Aplicación Integral de Bienestar para Estudiantes Universitarios  
**Versión del documento:** 1.5  
**Fecha:** 09-06-2026  
**Estado:** ✅ EN DESARROLLO ACTIVO

---

## 1. Anteproyecto del Trabajo de Fin de Grado

### 1.1 Título provisional

**Diseño y desarrollo de una aplicación multiplataforma de apoyo al estudiante para la organización académica y la promoción de hábitos saludables.**

### 1.2 Temática del trabajo

El presente trabajo se enmarca en el ámbito de la Ingeniería del Software aplicada al entorno educativo. En particular, se abordan aspectos relacionados con el análisis de requisitos, el diseño de la arquitectura software, el desarrollo de aplicaciones multiplataforma y la validación funcional de una solución digital centrada en el usuario.

### 1.3 Resumen

El objetivo de este Trabajo de Fin de Grado es el planteamiento, diseño e implementación de un prototipo funcional —Producto Mínimo Viable (MVP)— de una aplicación multiplataforma orientada a ayudar al estudiante universitario en la gestión de su planificación académica y en la adopción de hábitos saludables.

El proyecto aborda las distintas fases del ciclo de vida del software: desde el análisis de necesidades del usuario y la especificación de requisitos funcionales y no funcionales, hasta el diseño técnico de la solución y el desarrollo de las funcionalidades principales del sistema. El proceso sigue un enfoque incremental, priorizando un alcance realista y viable dentro de las limitaciones temporales propias de un TFG.

Asimismo, se llevará a cabo una evaluación del prototipo mediante pruebas funcionales y de usabilidad, con el fin de verificar el correcto comportamiento del sistema y su adecuación a los objetivos planteados. Las funcionalidades adicionales o de carácter avanzado se considerarán como posibles líneas de trabajo futuro.

### 1.4 Problema que se pretende resolver

Los estudiantes universitarios se enfrentan a diario a una doble exigencia: mantener un rendimiento académico constante mientras cuidan de su bienestar físico y mental. Sin embargo, las herramientas disponibles actualmente —aplicaciones de calendario académico, apps de seguimiento deportivo, gestores de hábitos y plataformas de comunidad— operan de forma aislada, obligando al estudiante a fragmentar su rutina entre múltiples aplicaciones que no se comunican entre sí. Esta dispersión genera fricción, reduce la constancia y dificulta la creación de una rutina semanal equilibrada.

SynaptixFit nace para resolver esta fragmentación, ofreciendo un ecosistema unificado donde el estudiante puede planificar sus horarios académicos, organizar sus sesiones de entrenamiento, establecer retos personales gamificados y compartir sus logros con compañeros, todo desde una única aplicación y con un control granular de su privacidad.

### 1.5 Impacto potencial del sistema

La unificación de los ámbitos académico y de bienestar en una sola plataforma tiene el potencial de generar un impacto significativo en varios niveles:

- **Para el estudiante:** reducción de la carga cognitiva asociada a la gestión de múltiples herramientas, aumento de la constancia semanal gracias a la gamificación no punitiva, y mejora del equilibrio entre estudio, actividad física y descanso.
- **Para la comunidad universitaria:** fomento de una red de apoyo entre pares donde los logros académicos y deportivos se comparten y celebran, contribuyendo a un entorno más saludable y motivador.
- **Como contribución académica:** el proyecto demuestra la viabilidad de integrar tecnologías modernas —Flutter multiplataforma, Supabase como backend gestionado, Cloudflare R2 para multimedia, Google Gemini Flash (JSON mode) para refinamiento IA, un motor de reglas determinista para generación de rutinas, métricas académicas y energéticas con providers React, y Realtime para sincronización en vivo— en una arquitectura que puede servir como referencia para futuros desarrollos en el ámbito edTech.

### 1.6 Funcionalidades principales

El MVP de SynaptixFit integra las siguientes funcionalidades, organizadas en cinco módulos:

1. **Planificación académica:** gestión de asignaturas con horarios semanales, detección automática de conflictos entre bloques de estudio y sesiones de entrenamiento, y perfil académico personalizado con seguimiento de carga semanal y nivel de estrés. Incluye **métricas académicas** (adherencia académica 0-100 basada en disciplina pura) y **sincronización automática** de carga desde horarios y entregas.
2. **Bienestar y entrenamiento:** catálogo de ejercicios con terminología anatómica profesional (más de 1.300 ejercicios con GIFs animados), constructor de rutinas personalizadas con selección de series, repeticiones y descansos, **motor de recomendaciones híbrido (reglas deterministas + refinamiento IA con Gemini JSON mode)** que genera rutinas completas con paralelización de providers, catálogo inteligente top 60 y parámetros personalizados por modalidad (fuerza, aeróbico, isométrico). Incluye feedback post-entrenamiento con degradación dinámica de carga y **métricas de estado energético** (0-100 con gates no lineales).
3. **Retos gamificados:** creación de retos simples (meta única) y complejos (con hitos ponderados), sistema de progreso con barras visuales y cálculo automático de avance, y recompensas mediante experiencia (XP), niveles y rachas.
4. **Red social de logros:** muro de actividad donde los estudiantes comparten sus sesiones completadas y retos finalizados, sistema de me gusta y comentarios, y control de visibilidad por recurso (público, solo amigos, privado).
5. **Notificaciones adaptativas:** centro de avisos categorizados por prioridad (crítica, recomendada, informativa), alertas de conflicto horario y fatiga, y preferencias de entrega configurables por franja horaria y límite diario.

### 1.7 Observaciones y alcance

El alcance definitivo del proyecto podrá ajustarse durante el desarrollo en coordinación con el tutor académico, manteniendo como prioridad la correcta aplicación de una metodología de desarrollo software y la validación de un núcleo funcional estable. Las funcionalidades avanzadas (notificaciones push nativas e integración con calendarios externos) se consideran líneas de trabajo futuro. La integración con IA generativa (Gemini Flash), el sistema de periodización, el check-in diario de fatiga, y la sincronización offline (cola Hive + connectivity_plus) están implementados y funcionales.

**Sistema de gamificación (100% implementado):** La función PostgreSQL `otorgar_xp()` se llama desde 3 ubicaciones del cliente Flutter: `finalizarSesion()` en `rutina_provider.dart:792` (fórmula `50 + min(duraciónMin, 90) + rpe × 5`), `syncCargaAcademicaSemanal()` en `rutina_provider.dart:1380` (bonificación de 150 XP al sincronizar carga), y `completarReto()` en `retos_provider.dart:181` (XP por completar hitos). El sistema incluye level-up automático (umbral = 1000 × nivel), XP sobrante acumulado, y DTO `XpResultado` para feedback de subida de nivel. El campo `racha_actual` se actualiza vía triggers en BD (`trg_actualizar_racha`).

---

## 2. Objetivos del Producto

| # | Objetivo | KPI asociado |
|---|----------|-------------|
| O1 | Unificar planificación académica y bienestar físico | Activación: % de usuarios que crean su primer plan en <24h |
| O2 | Incrementar constancia semanal del usuario | Retención: % de usuarios activos al día 7 |
| O3 | Incorporar control granular de privacidad | Adopción: % de usuarios que configuran visibilidad |
| O4 | Sentar base técnica escalable | Cobertura de tests ≥ 70% en lógica crítica |

---

## 3. Stack Tecnológico

### Frontend
| Componente | Tecnología |
|------------|-----------|
| Framework | Flutter (Dart) |
| Estado | Riverpod (Funcional) |
| Routing | Go Router |
| UI | Widgets personalizados + tokens Synapse Velocity |
| Persistencia local | Hive (caché offline, cola de sincronización) |

### Backend
| Componente | Tecnología |
|------------|-----------|
| Base de datos | Supabase (PostgreSQL) |
| Autenticación | Supabase Auth (email/password + JWT) |
| Tiempo real | Supabase Realtime (WebSocket) |
| Almacenamiento multimedia | Cloudflare R2 (CORS + Worker proxy) |
| Edge Functions | Supabase Functions (Deno) — **no implementadas en MVP** |

### Servicios Externos
| Componente | Tecnología |
|------------|-----------|
| Catálogo de ejercicios | Dataset final (~909 ejercicios con video/imagen, ingesta batch desde JSON unificado) |
| IA generativa | Gemini Flash API (Google) — refinamiento de rutinas con **JSON mode forzado** (`response_mime_type: application/json`), vía Dio (cliente Flutter). Catálogo inteligente top 60 (~15KB). |
| Motor de reglas | Dart (cliente) — pipeline determinista con **parámetros personalizados por modalidad** (fuerza, aeróbico, isométrico), sin dependencia de IA |
| Métricas | Dart (cliente) — `adherenciaAcademicaProvider` (0-100 disciplina pura), `estadoEnergeticoProvider` (0-100 con 3 gates no lineales) |

### Formatos Multimedia
| Tipo | Formato | Límite |
|------|---------|--------|
| Video | H.264 MP4 | < 10 MB |
| Imagen | WebP | < 2 MB |
| Miniatura | JPG optimizado | < 200 KB |

---

## 4. Design System: Synapse Velocity

### 4.1 Paleta de colores

| Rol | Color | Uso |
|-----|-------|-----|
| **Primario (Académico)** | `#0D3B66` (Azul profundo) | App bars, headlines, fondos profundos |
| **Secundario (Deportivo)** | `#006e2d` / `#1DB954` (Verde energético) | CTAs de fitness, indicadores de progreso |
| **Terciario (Flujo)** | `#00A896` (Teal) | Métricas de bienestar, acentos sutiles |
| **Neutro** | `#F4F7F9` | Fondos de superficie |
| **Error** | `#ba1a1a` | Estados de error, validaciones |

### 4.2 Tipografía

| Rol | Fuente | Peso |
|-----|--------|------|
| Display y Headlines | Manrope | Bold (600-700) |
| Body y Labels | Inter | Regular (400) / Medium (500) |

### 4.3 Forma y elevación

| Propiedad | Valor |
|-----------|-------|
| Border radius estándar | 8px (`ROUND_EIGHT`) |
| Botones primarios (pill) | `1.5rem` / `9999px` |
| Navegación | Glassmorphism (80% opacidad + 20px backdrop blur) |
| Sombras | Difusas, teñidas con color de superficie (nunca negro puro) |

### 4.4 Reglas de diseño

1. **Regla "Sin Línea":** No usar bordes de 1px para separar secciones. Usar cambios de fondo (`surface-container-low` sobre `surface`).
2. **Jerarquía tonal:** Apilar capas de superficie como hojas de papel (lowest → low → container → high).
3. **Métricas como titulares:** Los números principales deben ser significativamente más grandes que sus etiquetas.

### 4.5 Navegación

- **Bottom Navigation:** 5 tabs con glassmorphism.
  - Inicio (Dashboard)
  - Académico
  - Rutinas (Bienestar)
  - Retos
  - Social

Perfil NO es un tab. Es una ruta separada `/perfil`, accesible desde el avatar.
- **Tab activo:** Color secundario (verde) con punto indicador de 4px.

### 4.6 Proyecto Stitch

| Propiedad | Valor |
|-----------|-------|
| ID del proyecto | `projects/16069267803479671083` |
| ID del Design System | `assets/9627a6f296664034a31c0659fd56d8b5` |
| Pantallas generadas | 15 (todas en español es-ES) |

---

## 5. Público Objetivo

| Segmento | Descripción |
|----------|------------|
| **Primario** | Estudiantes universitarios (18-30 años) |
| **Secundario** | Bachillerato y opositores |
| **Perfil común** | Alta carga académica + necesidad de rutina semanal |

---

## 6. Glosario de Términos

| Término | Definición |
|---------|-----------|
| **Reto simple** | Objetivo con meta medible y fecha límite, sin subdivisiones. |
| **Reto complejo** | Objetivo dividido en hitos secuenciales con pesos porcentuales. |
| **Hito** | Subdivisión de un reto complejo con su propio progreso y fecha objetivo. |
| **RPE** | Rate of Perceived Exertion. Escala 1-10 de esfuerzo percibido. |
| **Racha** | Días consecutivos completando al menos una acción (estudio, rutina o reto). |
| **XP** | Puntos de experiencia obtenidos al completar acciones. |
| **RLS** | Row-Level Security. Políticas de acceso a nivel de fila en PostgreSQL. |
| **Seeding** | Proceso de carga inicial de datos desde una fuente externa hacia Supabase. |
| **Edge Function** | Función serverless ejecutada en Supabase para lógica de negocio sensible. |
| **Fallback** | Contenido alternativo cuando el recurso principal no está disponible. |
| **Visibilidad** | Nivel de acceso de un recurso: `publico`, `solo_amigos` o `privado`. |

---

## 7. Convenciones y Estándares

### 7.1 Nomenclatura

| Contexto | Convención | Ejemplo |
|----------|-----------|---------|
| Tablas SQL | snake_case en español | `usuarios`, `sesiones_rutina` |
| Columnas SQL | snake_case en español | `creado_en`, `usuario_id` |
| Variables Dart | camelCase | `currentStreak`, `routineId` |
| Funciones Dart | camelCase | `calculateProgress()` |
| Archivos Dart | snake_case | `routine_builder_screen.dart` |
| Rutas API | kebab-case en español | `/plan-semanal/integrado` |

### 7.2 Idioma

- **Código:** Variables y funciones en inglés o español según el equipo lo decida. Consistencia interna obligatoria.
- **Comentarios:** Siempre en español.
- **SQL:** Triggers, funciones y políticas en español.
- **Documentación:** Siempre en español.

### 7.3 Testing

| Tipo | Cobertura mínima | Alcance |
|------|-----------------|---------|
| Unit tests | ≥ 70% | Lógica de dominio crítica |
| Integration tests | Flujos principales | Login, crear rutina, registrar sesión |
| Golden tests | Pantallas clave | Dashboard, Explorador, Constructor |

---

## 8. Estructura de Documentación

Este proyecto sigue el estándar modular de documentación del equipo jloen:

| # | Archivo | Descripción |
|---|---------|------------|
| 00 | [00-plan-maestro.md](00-plan-maestro.md) | Plan maestro: hoja de ruta, fases 0-4, Sprints 7-9, Time-Blocking, panel admin. |
| 01 | `01-introduction.md` | Este documento. Contexto, objetivos, stack, glosario. |
| 02 | [02-requirements.md](02-requirements.md) | Requisitos funcionales y no funcionales (SRS v5.1). |
| 03 | [03-architecture.md](03-architecture.md) | Arquitectura del sistema, modelo 4+1, diagramas. |
| 04 | [04-data-model.md](04-data-model.md) | Modelos ER, esquemas de BD, relaciones, RLS. |
| 05 | [05-api.md](05-api.md) | Endpoints REST, requests/responses, auth, errores. |
| 06 | [06-frontend.md](06-frontend.md) | Estructura UI, componentes, estado, pantallas. |
| 07 | [07-backend.md](07-backend.md) | Edge Functions, Realtime, middlewares, lógica servidor. |
| 08 | [08-installation.md](08-installation.md) | Setup local, variables de entorno, dependencias. |
| 09 | [09-testing.md](09-testing.md) | Estrategia de testing, cobertura, test cases. |
| 10 | [10-deployment.md](10-deployment.md) | CI/CD, hosting, infraestructura. |
| 11 | [11-security.md](11-security.md) | Auth, RLS, encriptación, datos sensibles. |
| 12 | [12-user-guide.md](12-user-guide.md) | Manual de uso, roles, flujos principales. |
| 13 | [13-maintenance.md](13-maintenance.md) | Gobierno del catálogo de ejercicios, backups, actualización de dependencias. |
| 14 | [14-changelog.md](14-changelog.md) | Historial de versiones y cambios (~2162 líneas). |
| 15 | [15-ia-recomendacion-sistema.md](15-ia-recomendacion-sistema.md) | Sistema de recomendación híbrido (motor de reglas + IA Gemini con JSON mode): pipeline completo, catálogo inteligente top 60, contexto académico unificado, parámetros por modalidad, validación extendida, fallback. |
| 16 | [16-guia-autenticacion-google.md](16-guia-autenticacion-google.md) | Guía técnica de implementación de autenticación nativa con Google (Flutter + Supabase). |
| 17 | [17-dataset-lyfta.md](17-dataset-lyfta.md) | Dataset Lyfta: pipeline de scraping, limpieza y generación de 682 ejercicios con video. |
| 18 | [18-implementacion-admin.md](18-implementacion-admin.md) | Panel de administración Fase 3: arquitectura, implementación, DTOs, repositorios, widgets. |
| 19 | [19-plan-coherencia-gamificacion.md](19-plan-coherencia-gamificacion.md) | Plan de coherencia de gamificación: 9 fases, XP unificado, SyncHub, insignias. |
| 20 | [20-plan-verificacion-qa.md](20-plan-verificacion-qa.md) | Plan de verificación QA: checklist, pruebas, métricas de calidad. |
| 21 | [21-plan-definitivo.md](21-plan-definitivo.md) | Plan definitivo: arquitectura final, roadmap completado, estado del proyecto. |

---

## 9. Contacto y Roles

| Rol | Responsabilidad | Documento de referencia |
|-----|----------------|------------------------|
| Product Manager | Requisitos, priorización, roadmap | `02-requirements.md` |
| Arquitecto de Software | Decisiones arquitectónicas, contratos API | `03-architecture.md` |
| Arquitecto de Datos | Esquemas, RLS, stored procedures | `04-data-model.md` |
| Diseñador UX/UI | Design System, flujos, pantallas | `06-frontend.md` |
| QA | Criterios de aceptación, test cases | `09-testing.md` |

---

**Documento compilado:** 09-06-2026  
**Versión:** 1.5  
**Clasificación:** PÚBLICO — Equipo jloen
