# 01 - Introducción

**Proyecto:** SynaptixFit — Aplicación Integral de Bienestar para Estudiantes Universitarios  
**Versión del documento:** 1.2  
**Fecha:** 10-05-2026  
**Estado:** ✅ LISTO PARA DESARROLLO

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
- **Como contribución académica:** el proyecto demuestra la viabilidad de integrar tecnologías modernas —Flutter multiplataforma, Supabase como backend gestionado, Cloudflare R2 para multimedia, y Realtime para sincronización en vivo— en una arquitectura que puede servir como referencia para futuros desarrollos en el ámbito edTech.

### 1.6 Funcionalidades principales

El MVP de SynaptixFit integra las siguientes funcionalidades, organizadas en cinco módulos:

1. **Planificación académica:** gestión de asignaturas con horarios semanales, detección automática de conflictos entre bloques de estudio y sesiones de entrenamiento, y perfil académico personalizado con seguimiento de carga semanal y nivel de estrés.
2. **Bienestar y entrenamiento:** catálogo de ejercicios con terminología anatómica profesional (más de 1.300 ejercicios con GIFs animados), constructor de rutinas personalizadas con selección de series, repeticiones y descansos, y registro de sesiones completadas con cálculo de calorías y XP.
3. **Retos gamificados:** creación de retos simples (meta única) y complejos (con hitos ponderados), sistema de progreso con barras visuales y cálculo automático de avance, y recompensas mediante experiencia (XP), niveles y rachas.
4. **Red social de logros:** muro de actividad donde los estudiantes comparten sus sesiones completadas y retos finalizados, sistema de me gusta y comentarios, y control de visibilidad por recurso (público, solo amigos, privado).
5. **Notificaciones adaptativas:** centro de avisos categorizados por prioridad (crítica, recomendada, informativa), alertas de conflicto horario y fatiga, y preferencias de entrega configurables por franja horaria y límite diario.

### 1.7 Observaciones y alcance

El alcance definitivo del proyecto podrá ajustarse durante el desarrollo en coordinación con el tutor académico, manteniendo como prioridad la correcta aplicación de una metodología de desarrollo software y la validación de un núcleo funcional estable. Las funcionalidades avanzadas (integración con IA para recomendaciones personalizadas, notificaciones push nativas y sincronización offline completa) se consideran líneas de trabajo futuro.

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
| Persistencia local | Hive / Sembast (offline-first) |

### Backend
| Componente | Tecnología |
|------------|-----------|
| Base de datos | Supabase (PostgreSQL) |
| Autenticación | Supabase Auth (email/password + JWT) |
| Tiempo real | Supabase Realtime (WebSocket) |
| Edge Functions | Supabase Functions (Deno) |
| Almacenamiento multimedia | Cloudflare R2 (CORS + URLs firmadas) |

### Servicios Externos
| Componente | Tecnología |
|------------|-----------|
| Catálogo de ejercicios | ExerciseDB (AscendAPI) via Kaggle (ingesta batch a Supabase) |
| IA (Fase 2) | Supabase Vector (OpenAI embeddings) |
| Push (Fase 2) | Firebase Cloud Messaging |

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
  - 🏠 Inicio (Dashboard)
  - 📚 Académico
  - 🎯 Retos
  - 👥 Social
  - 👤 Perfil
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

Este proyecto sigue el estándar modular de 14 puntos:

| # | Archivo | Descripción |
|---|---------|------------|
| 01 | `01-introduction.md` | Este documento. Contexto, objetivos, stack, glosario. |
| 02 | [02-requirements.md](02-requirements.md) | Requisitos funcionales y no funcionales (SRS v2.5). |
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
| 14 | [14-changelog.md](14-changelog.md) | Historial de versiones y cambios. |

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

**Documento compilado:** 19-04-2026  
**Versión:** 1.0  
**Clasificación:** PÚBLICO — Equipo jloen
