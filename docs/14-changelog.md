# 14 - Historial de Cambios (Changelog)

**Proyecto:** SynaptixFit  
**Formato:** [Versionado Semántico](https://semver.org/lang/es/)

---

## [2.5.28] — 03-05-2026

### Realtime activado en catálogo de ejercicios
- Se habilitó Supabase Realtime en las 8 tablas del catálogo de ejercicios: `ejercicios`, `partes_cuerpo`, `musculos`, `equipamientos`, `ejercicio_musculo_objetivo`, `ejercicio_musculo_secundario`, `ejercicio_parte_cuerpo` y `ejercicio_equipamiento`.
- Se actualizó [app/lib/features/bienestar/application/ejercicios_provider.dart](app/lib/features/bienestar/application/ejercicios_provider.dart) para usar `.stream()` y reflejar cambios en vivo en la UI.
- Migración: [supabase/migrations/20260501_0008_enable_realtime_ejercicios.sql](supabase/migrations/20260501_0008_enable_realtime_ejercicios.sql).

---

## [2.5.27] — 22-04-2026

### Catálogo de ejercicios poblado con terminología anatómica profesional
- Se ejecutó `supabase/seed_ejercicios.py` con los JSON traducidos al español (`synaptix_bodyParts_es.json`, `synaptix_muscles_es.json`, `synaptix_equipments_es.json`, `synaptix_exercises_es.json`).
- Los nombres de músculos, partes del cuerpo y equipamientos usan terminología anatómica profesional (ej. "Pectoral mayor" en lugar de "pecho", "Deltoides anterior" en lugar de "hombros").
- Los GIFs se referencian desde Cloudflare R2 en resolución 360x360.

---

## [2.5.26] — 22-04-2026

### Modelo normalizado de ejercicios (ExerciseDB v2)
- Se reemplazó la tabla plana `ejercicios` (con columnas `grupo_muscular TEXT`, `equipamiento TEXT` y ENUMs fijos) por un modelo 3NF completo:
	- 3 tablas de catálogo: `partes_cuerpo`, `musculos`, `equipamientos`.
	- 4 tablas de relación N:M: `ejercicio_musculo_objetivo`, `ejercicio_musculo_secundario`, `ejercicio_parte_cuerpo`, `ejercicio_equipamiento`.
	- Vista denormalizada `v_ejercicios_completos` para consultas rápidas desde el frontend.
- Campo `exercise_db_id TEXT UNIQUE` reemplaza al obsoleto `id_wger INT`.
- Campo `url_gif TEXT` unifica `url_video` y `url_imagen`.
- Campo `instrucciones TEXT[]` reemplaza `instrucciones TEXT`.
- Se eliminaron `descripcion_respaldo`, `url_video`, `url_imagen`, `id_wger`.
- Se actualizó `EjercicioDb` en [app/lib/shared/models/db_models.dart](app/lib/shared/models/db_models.dart) con propiedades derivadas (`musculoPrincipal`, `equipamientoPrincipal`, `parteCuerpoPrincipal`).
- Se añadieron modelos de catálogo en [app/lib/shared/models/catalogo_models.dart](app/lib/shared/models/catalogo_models.dart) (`ParteCuerpoDb`, `MusculoDb`, `EquipamientoDb`, `CatalogosEjercicios`).
- Migración: [supabase/migrations/20260422_0006_ejercicios_v2_normalizado.sql](supabase/migrations/20260422_0006_ejercicios_v2_normalizado.sql).

### Actualización de UI de ejercicios
- `ExploradorEjerciciosScreen` ahora filtra por catálogos N:M (parte del cuerpo, músculo, equipamiento) usando las tablas de relación.
- `DetalleEjercicioScreen` muestra chips de metadatos anatómicos (músculos objetivo, músculos secundarios, partes del cuerpo, equipamientos) y renderiza el GIF animado desde `url_gif`.
- `ExerciseCard` muestra `musculoPrincipal` y `equipamientoPrincipal` desde las propiedades derivadas del modelo.
- Se actualizó `EjerciciosRepository` para consultar `v_ejercicios_completos` y las tablas de catálogo y relación N:M.

---

## [2.5.25] — 26-04-2026

### Inicio orientado a creación
- La barra superior de inicio ahora muestra el logo en el lado izquierdo y elimina el título textual de la app.
- El botón flotante de añadir se transformó en un menú de creación con accesos directos a:
	- Nueva rutina
	- Reto simple
	- Reto complejo
	- Plan de estudio semanal
- Se mantuvo la lógica alineada con las rutas y flujos de creación ya disponibles en la aplicación.

---

## [2.5.24] — 25-04-2026

### Seguridad de repositorio
- Se agregó [.gitignore](.gitignore) en la raíz del workspace para evitar publicar archivos sensibles en GitHub.
- Se excluyeron archivos de entorno (`.env`), secretos OAuth de Google (`client_secret_*.json`, `google-services.json`, `GoogleService-Info.plist`), certificados/llaves privadas y secretos locales de Cloudflare (`.dev.vars`, `.secrets*`).

---

## [2.5.23] — 25-04-2026

### Retroceso unificado
- El botón físico de volver atrás del dispositivo ahora comparte la misma lógica de navegación que el botón de retroceso de la interfaz en las pantallas con `FeatureScaffold`.
- Se centralizó la navegación de retorno en un helper común para mantener consistencia entre la barra superior y el sistema.

---

## [2.5.22] — 25-04-2026

### Acceso inteligente y cierre de sesión
- La pantalla de presentación y la pantalla de acceso ahora detectan una sesión activa y redirigen automáticamente a onboarding o dashboard según corresponda.
- Se conectó el botón de cerrar sesión en el perfil para ejecutar el `logout` real y volver a la pantalla de acceso.
- El controlador de autenticación ahora limpia su estado local al cerrar sesión para evitar estados obsoletos en navegación posterior.

---

## [2.5.21] — 25-04-2026

### Retorno consistente en pantallas secundarias
- Se añadió un destino de retorno explícito en el scaffold compartido para pantallas que se abren con rutas directas sin historial de navegación.
- Se habilitó botón de volver atrás en:
	- [app/lib/features/bienestar/presentation/explorador_ejercicios_screen.dart](app/lib/features/bienestar/presentation/explorador_ejercicios_screen.dart)
	- [app/lib/features/bienestar/presentation/detalle_ejercicio_screen.dart](app/lib/features/bienestar/presentation/detalle_ejercicio_screen.dart)
	- [app/lib/features/bienestar/presentation/sesion_completada_screen.dart](app/lib/features/bienestar/presentation/sesion_completada_screen.dart)
	- [app/lib/features/bienestar/presentation/constructor_rutina_screen.dart](app/lib/features/bienestar/presentation/constructor_rutina_screen.dart)
	- [app/lib/features/retos/presentation/detalle_reto_screen.dart](app/lib/features/retos/presentation/detalle_reto_screen.dart)
	- [app/lib/features/retos/presentation/crear_reto_simple_screen.dart](app/lib/features/retos/presentation/crear_reto_simple_screen.dart)
	- [app/lib/features/retos/presentation/crear_reto_complejo_screen.dart](app/lib/features/retos/presentation/crear_reto_complejo_screen.dart)
	- [app/lib/features/academico/presentation/plan_semanal_screen.dart](app/lib/features/academico/presentation/plan_semanal_screen.dart)
	- [app/lib/features/notificaciones/presentation/notificaciones_screen.dart](app/lib/features/notificaciones/presentation/notificaciones_screen.dart)
- Se reforzó el `FeatureScaffold` y el `SynaptixFitAppBar` para soportar retornos explícitos cuando el `context.canPop()` no está disponible.

---

## [2.5.20] — 25-04-2026

### R2 público alineado
- Se actualizó la URL pública de Cloudflare R2 a `https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev` en [app/.env](app/.env), y se alineó el valor por defecto del seed de ejercicios en [supabase/seed_ejercicios.py](supabase/seed_ejercicios.py).
- Se documentó la misma URL pública en [docs/08-installation.md](docs/08-installation.md) para mantener consistencia entre entorno local, scripts y documentación.

---

## [2.5.19] — 25-04-2026

### Barra inferior centrada con avatar y dashboard sin título genérico
- Se movió la pestaña de perfil al centro de la navegación inferior y ahora muestra el avatar del usuario cuando existe `url_avatar`, con fallback a la inicial del nombre en [app/lib/shared/widgets/bottom_nav_bar.dart](app/lib/shared/widgets/bottom_nav_bar.dart).
- Se reordenó el shell de rutas para mantener la navegación coherente con la nueva posición central del perfil en [app/lib/core/routing/shell_route.dart](app/lib/core/routing/shell_route.dart).
- Se reemplazó el título `Dashboard` por `SynaptixFit` en [app/lib/features/dashboard/presentation/dashboard_screen.dart](app/lib/features/dashboard/presentation/dashboard_screen.dart).

### Seed demo enriquecido en Supabase
- Se añadió [supabase/seed_demo_data.py](supabase/seed_demo_data.py) para poblar usuarios, perfil de bienestar, asignaturas, horarios, sesiones, retos, hitos, actividades sociales, interacciones y notificaciones con datos de demo reales.
- Se reforzó el guardado de avatar en [app/lib/features/auth/infrastructure/bienestar_repository.dart](app/lib/features/auth/infrastructure/bienestar_repository.dart) para aceptar `avatar_url` o `picture` desde metadata.

---

## [2.5.18] — 25-04-2026

### Fix crítico en Dashboard y módulos relacionados (Supabase)
- Se corrigieron referencias erróneas a la tabla `sesion_registrada` en:
	- [app/lib/features/dashboard/application/dashboard_provider.dart](app/lib/features/dashboard/application/dashboard_provider.dart)
	- [app/lib/features/academico/presentation/plan_semanal_screen.dart](app/lib/features/academico/presentation/plan_semanal_screen.dart)
	- [app/lib/features/bienestar/presentation/sesion_completada_screen.dart](app/lib/features/bienestar/presentation/sesion_completada_screen.dart)
	- [app/lib/features/perfil/presentation/perfil_screen.dart](app/lib/features/perfil/presentation/perfil_screen.dart)
- Se alineó el consumo de hitos de retos con el esquema real, cambiando `hitos_reto` por `hitos_de_reto` en [app/lib/features/retos/application/retos_provider.dart](app/lib/features/retos/application/retos_provider.dart).

### Implementación funcional de creación de retos
- Se reemplazó la creación mock de reto simple por flujo real con:
	- Validación de formulario.
	- Selección de tipo, visibilidad y fechas.
	- Persistencia en Supabase (`retos` + hito inicial en `hitos_de_reto`).
	- Redirección automática al detalle del reto creado.
	- Archivo: [app/lib/features/retos/presentation/crear_reto_simple_screen.dart](app/lib/features/retos/presentation/crear_reto_simple_screen.dart).
- Se reemplazó la creación mock de reto complejo por flujo real con:
	- Gestión dinámica de hitos (crear/eliminar).
	- Validación de pesos (suma exacta 100%).
	- Persistencia en Supabase (`retos` + inserción por lote en `hitos_de_reto`).
	- Redirección automática al detalle del reto creado.
	- Archivo: [app/lib/features/retos/presentation/crear_reto_complejo_screen.dart](app/lib/features/retos/presentation/crear_reto_complejo_screen.dart).

---

## [2.5.17] — 21-04-2026

### Salidas esperadas de traducir.py y evidencias de ejecucion
- Se actualizo [docs/08-installation.md](docs/08-installation.md) para especificar `ARCHIVO_SALIDA` esperado al ejecutar `traducir.py` con `muscles.json`, `equipments.json` y `bodyParts.json`.
- Se actualizaron [docs/08-installation.md](docs/08-installation.md) y [docs/13-maintenance.md](docs/13-maintenance.md) incorporando capturas de ejecucion:
	- `traducir_ejercicios.png`
	- `traducir_musculos.png`
	- `traducir_equipamientos.png`
	- `traducir_partesCuerpo.png`

---

## [2.5.16] — 21-04-2026

### Pipeline de traduccion ExerciseDB documentado
- Se actualizo [docs/02-requirements.md](docs/02-requirements.md) para reflejar la traduccion al espanol como parte vigente del seeding del dataset.
- Se actualizo [docs/03-architecture.md](docs/03-architecture.md) incorporando la fase de traduccion en el pipeline Kaggle -> Supabase + R2.
- Se actualizo [docs/08-installation.md](docs/08-installation.md) con el procedimiento real ejecutado usando [exercisedb/traducir_ejercicios.py](exercisedb/traducir_ejercicios.py) y [exercisedb/traducir.py](exercisedb/traducir.py).
- Se actualizo [docs/13-maintenance.md](docs/13-maintenance.md) con trazabilidad operacional de traduccion para `exercises.json`, `muscles.json`, `equipments.json` y `bodyParts.json`.

---

## [2.5.15] — 21-04-2026

### Adopcion definitiva de ExerciseDB (AscendAPI) via Kaggle
- Se actualizo [docs/01-introduction.md](docs/01-introduction.md) para reflejar ExerciseDB como fuente aprobada del catalogo de ejercicios.
- Se actualizo [docs/02-requirements.md](docs/02-requirements.md) con la decision final de proveedor y la ruta oficial de obtencion del dataset en Kaggle.
- Se actualizo [docs/03-architecture.md](docs/03-architecture.md) para pasar de estado de evaluacion a pipeline activo ExerciseDB -> Supabase + R2.
- Se actualizaron [docs/04-data-model.md](docs/04-data-model.md), [docs/07-backend.md](docs/07-backend.md), [docs/08-installation.md](docs/08-installation.md) y [docs/09-testing.md](docs/09-testing.md) para alinear funciones, variables y criterios con ExerciseDB.
- Se reescribio [docs/13-maintenance.md](docs/13-maintenance.md) incorporando evidencia visual en `app/assets/images/documentacion/exercisesdb/` sobre GitHub shell, descarga Kaggle y estructura del dataset.

---

## [2.5.14] — 21-04-2026

### Decision tecnica documentada: proveedor de ejercicios en evaluacion
- Se actualizo [docs/01-introduction.md](docs/01-introduction.md) para reflejar que el catalogo de ejercicios usa infraestructura propia (Supabase + R2) con proveedor externo pendiente de aprobacion.
- Se actualizo [docs/02-requirements.md](docs/02-requirements.md) con el descarte temporal de wger (Docker y API REST) y la condicion de ExerciseDB como candidato de evaluacion futura.
- Se actualizo [docs/03-architecture.md](docs/03-architecture.md) para eliminar la suposicion de wger como fuente adoptada y dejar el pipeline de ingesta en estado suspendido hasta nueva decision.
- Se actualizaron [docs/04-data-model.md](docs/04-data-model.md), [docs/06-frontend.md](docs/06-frontend.md), [docs/07-backend.md](docs/07-backend.md), [docs/08-installation.md](docs/08-installation.md) y [docs/09-testing.md](docs/09-testing.md) para desacoplar referencias de operacion activa en wger.
- Se reescribio [docs/13-maintenance.md](docs/13-maintenance.md) con evidencia visual del intento Docker/REST en la carpeta `app/assets/images/documentacion/wger/` y criterios formales para aprobar el siguiente proveedor.

---

## [2.5.13] — 21-04-2026

### Capa académica extendida para personalización
- Se actualizó [docs/04-data-model.md](docs/04-data-model.md) con:
	- Extensión de `asignaturas` (`dificultad_percibida`, `creditos`, `prioridad`, `proxima_evaluacion`).
	- Nueva tabla `perfil_academico_usuario` para contexto académico base.
	- Nueva tabla `carga_academica_semanal` para señales semanales de carga y estrés.
- Se actualizó [docs/11-security.md](docs/11-security.md) incorporando las nuevas tablas en la matriz RLS y la clasificación de sensibilidad para datos académicos.
- Se preparó la implementación SQL con RLS y permisos desde el inicio para prevenir errores de acceso en PostgREST.

---

## [2.5.12] — 21-04-2026

### Fix de permisos Supabase tras reset de esquema
- Se corrigió el error `PostgrestException 42501 (permission denied)` al guardar el perfil de bienestar.
- Se agregó la migración [supabase/migrations/20260421_0003_restore_table_grants_after_schema_reset.sql](supabase/migrations/20260421_0003_restore_table_grants_after_schema_reset.sql) para restaurar permisos de tablas y secuencias para roles `anon`, `authenticated` y `service_role`.
- Se reforzó [supabase/sql/schema.sql](supabase/sql/schema.sql) con `GRANT` y `ALTER DEFAULT PRIVILEGES` para evitar que el problema reaparezca después de `DROP SCHEMA public CASCADE`.
- Se añadió [supabase/migrations/20260421_0004_backfill_usuarios_and_restore_auth_trigger.sql](supabase/migrations/20260421_0004_backfill_usuarios_and_restore_auth_trigger.sql) para reponer el trigger `auth.users -> public.usuarios` y backfillear usuarios faltantes, corrigiendo el error `23503` de FK en `perfil_bienestar_usuario`.
- Se blindó [app/lib/features/auth/infrastructure/bienestar_repository.dart](app/lib/features/auth/infrastructure/bienestar_repository.dart) para asegurar automáticamente la fila en `public.usuarios` antes de guardar o actualizar datos de bienestar.

---

## [2.5.11] — 19-04-2026

### Perfil físico (IA y UX de campos)
- Se cambió `Nivel de actividad` a desplegable en [app/lib/features/auth/presentation/perfil_fisico_screen.dart](app/lib/features/auth/presentation/perfil_fisico_screen.dart).
- Se integraron sugerencias de IA para `Objetivo principal` usando Gemini en:
	- [app/lib/features/auth/infrastructure/objetivo_ia_service.dart](app/lib/features/auth/infrastructure/objetivo_ia_service.dart)
	- [app/lib/features/auth/presentation/perfil_fisico_screen.dart](app/lib/features/auth/presentation/perfil_fisico_screen.dart)
- Se añadió soporte de variable de entorno `GEMINI_API_KEY` en [app/lib/core/config/env_config.dart](app/lib/core/config/env_config.dart).
- Se mejoró la visualización de labels flotantes y bordes de campos para evitar pérdida de legibilidad al enfocar inputs en [app/lib/features/auth/presentation/perfil_fisico_screen.dart](app/lib/features/auth/presentation/perfil_fisico_screen.dart).
- Se corrigió overflow horizontal del bloque de sugerencias/acciones en pantallas estrechas con layout adaptable.
- Se añadió opción `Ocultar sugerencias` / `Mostrar sugerencias` para permitir edición manual del objetivo principal tras generar recomendaciones.
- Se implementó cálculo dinámico de IMC al introducir `Peso` y `Altura` con actualización en tiempo real.
- Se ajustó el layout general para evitar cortes de scroll en la etapa de sugerencias (contenedor expandible + Stepper con scroll interno).
- Se reforzó la apariencia de botones accionables en sugerencias IA con estilos `FilledButton` y `OutlinedButton`.

---

## [2.5.10] — 19-04-2026

### Perfil físico y progreso de pasos
- Se transformo el campo `Sexo` en un desplegable en [app/lib/features/auth/presentation/perfil_fisico_screen.dart](app/lib/features/auth/presentation/perfil_fisico_screen.dart) para evitar entradas ambiguas.
- Se modernizo el flujo del Stepper con un indicador superior de progreso, estados completado/activo y transiciones visuales suaves.
- Se habilito la navegacion real hacia atras tocando un paso anterior en el Stepper, sin boton adicional.
- Se preservan los campos al regresar a pasos previos mediante controladores dedicados.

---

## [2.5.9] — 19-04-2026

### Autenticacion Google nativa en mobile
- Se reemplazo el flujo OAuth por navegador en mobile por Google Sign-In nativo en [app/lib/features/auth/infrastructure/auth_repository.dart](app/lib/features/auth/infrastructure/auth_repository.dart), evitando redireccion a localhost.
- Se integra `google_sign_in` + `signInWithIdToken` de Supabase para Android/iOS.
- Se agregaron variables de entorno para configuracion de cliente Google en [app/lib/core/config/env_config.dart](app/lib/core/config/env_config.dart):
	- `GOOGLE_WEB_CLIENT_ID` (requerido para mobile)
	- `GOOGLE_IOS_CLIENT_ID` (opcional para iOS)
- Se mejoro el manejo de errores de Google Sign-In en [app/lib/features/auth/infrastructure/auth_repository.dart](app/lib/features/auth/infrastructure/auth_repository.dart) para mostrar diagnosticos accionables (DEVELOPER_ERROR/SHA-1, cliente OAuth, red, cancelacion).
- Se añadio el scope `openid` al flujo de Google Sign-In para que coincida con los permisos del consentimiento OAuth.
- Se fuerza el reinicio de la sesion local de Google Sign-In antes de mostrar el selector de cuenta, para evitar reutilizar el correo anterior.
- La pantalla de acceso deja de autoredirigir por una sesion previa en Supabase para que el formulario siga visible al entrar a la app.

---

## [2.5.8] — 19-04-2026

### Autenticacion y pantalla de acceso
- Se agrego el logo oficial de la app en [app/lib/features/auth/presentation/acceso_screen.dart](app/lib/features/auth/presentation/acceso_screen.dart) con `Hero` y fallback visual.
- Se implemento boton profesional **Continuar con Google** en [app/lib/features/auth/presentation/acceso_screen.dart](app/lib/features/auth/presentation/acceso_screen.dart).
- Se conecto la autenticacion real con Supabase en [app/lib/features/auth/infrastructure/auth_repository.dart](app/lib/features/auth/infrastructure/auth_repository.dart):
	- Login con email y contrasena (`signInWithPassword`).
	- Registro con email y contrasena (`signUp`).
	- Inicio con Google OAuth (`signInWithOAuth`).
	- Cierre de sesion real (`signOut`).
- Se amplio el estado de autenticacion en [app/lib/features/auth/presentation/auth_controller.dart](app/lib/features/auth/presentation/auth_controller.dart) para manejar `autenticado`, `loginConGoogle` y `sincronizarSesionActiva`.
- La pantalla de acceso ahora escucha cambios de sesion OAuth y sincroniza correctamente la navegacion post-login.

---

## [2.5.7] — 19-04-2026

### Convencion de nombres de pantallas
- Se ajusto la convención de nombres para vistas Flutter al formato `*_screen.dart`.
- Se renombraron los archivos:
	- `pantalla_presentacion.dart` -> [app/lib/features/splash/presentation/presentacion_screen.dart](app/lib/features/splash/presentation/presentacion_screen.dart)
	- `pantalla_acceso.dart` -> [app/lib/features/auth/presentation/acceso_screen.dart](app/lib/features/auth/presentation/acceso_screen.dart)
- Se actualizaron las clases a sufijo `Screen`:
	- `PantallaPresentacion` -> `PresentacionScreen`
	- `PantallaAcceso` -> `AccesoScreen`
- Se actualizaron imports y referencias en [app/lib/core/routing/app_router.dart](app/lib/core/routing/app_router.dart).

---

## [2.5.6] — 19-04-2026

### UI/UX Flutter (presentacion y acceso)
- Se renombro la pantalla de autenticacion a [app/lib/features/auth/presentation/pantalla_acceso.dart](app/lib/features/auth/presentation/pantalla_acceso.dart) con clase `PantallaAcceso` para mantener nomenclatura clara en espanol.
- Se renombro la pantalla de onboarding a [app/lib/features/splash/presentation/pantalla_presentacion.dart](app/lib/features/splash/presentation/pantalla_presentacion.dart) con clase `PantallaPresentacion`.
- Se modernizo la interfaz de acceso con composicion visual premium (gradientes, glass-card, microanimaciones y grafico generado por codigo).
- Se mejoro la presentacion inicial con estilo visual mas inmersivo y arte generativo nativo en Flutter (sin imagenes estaticas externas).
- Se actualizaron rutas en [app/lib/core/routing/app_router.dart](app/lib/core/routing/app_router.dart) y [app/lib/features/splash/presentation/splash_screen.dart](app/lib/features/splash/presentation/splash_screen.dart): `/` ahora abre la presentacion y la navegacion de entrada usa `/acceso`.
- Se eliminaron los archivos obsoletos `bienvenida_screen.dart` y `presentacion_screen.dart`.

---

## [2.5.5] — 19-04-2026

### Base de datos Supabase (SQL inicial)
- Se creo la carpeta [supabase/](supabase/) para centralizar scripts SQL y migraciones.
- Se agrego la migracion inicial [supabase/migrations/20260419_0001_init_schema.sql](supabase/migrations/20260419_0001_init_schema.sql) con tablas, indices, funciones y politicas RLS.
- Se agrego [supabase/sql/schema.sql](supabase/sql/schema.sql) listo para copiar y pegar en Supabase SQL Editor.
- Se agrego [supabase/README.md](supabase/README.md) con estructura y uso rapido.

---

## [2.5.4] — 19-04-2026

### Documentación SHA-1 Android (validada)
- Se añadió en [docs/08-installation.md](08-installation.md) el procedimiento verificado para obtener SHA-1 en Windows con `gradlew signingReport`.
- Se agregaron comandos alternativos con `keytool` para casos donde Gradle falle.
- Se incluyeron referencias de capturas pendientes para documentar visualmente: ejecución de comando, salida SHA1 y formulario OAuth Android.

---

## [2.5.3] — 19-04-2026

### Documentación de autenticación Android
- Se añadió en [docs/08-installation.md](08-installation.md) la aclaración de cuándo es obligatorio o recomendable crear un OAuth Client de tipo Android.
- Se documentó un paso a paso completo para crear el cliente Android (tipo de aplicación, package name y huella SHA-1) y registrarlo en Supabase junto al cliente web.
- Se mejoró el formato de la sección de configuración de Google Provider en Supabase para mayor legibilidad.

---

## [2.5.2] — 19-04-2026

### Documentación de autenticación (Google + Supabase)
- Se añadió una guía visual profesional en [docs/08-installation.md](08-installation.md) con capturas reales del flujo completo de Google Auth Platform y Supabase.
- Se actualizaron los pasos para reflejar la interfaz en español de Google Cloud: **Descripción general**, **Público**, **Acceso a los datos** y **Clientes**.
- Se incorporaron opciones avanzadas no documentadas previamente en Supabase Provider de Google: **Skip nonce checks** y **Allow users without an email**.
- Se corrigió y normalizó la estructura Markdown de [docs/08-installation.md](08-installation.md) para evitar bloques mal cerrados.

---

## [2.5.1] — 19-04-2026

### Implementación Flutter (MVP inicial)
- Se inicializó el bootstrap real de la app con `Riverpod` + `GoRouter` en [app/lib/main.dart](app/lib/main.dart).
- Se añadió configuración base de entorno/Supabase en [app/lib/core/config/env_config.dart](app/lib/core/config/env_config.dart) y [app/lib/core/config/supabase_config.dart](app/lib/core/config/supabase_config.dart).
- Se implementó routing completo (incluyendo `ShellRoute` con navegación inferior) en [app/lib/core/routing/app_router.dart](app/lib/core/routing/app_router.dart) y [app/lib/core/routing/shell_route.dart](app/lib/core/routing/shell_route.dart).
- Se añadieron widgets compartidos del MVP en [app/lib/shared/widgets](app/lib/shared/widgets).
- Se crearon pantallas base (mock) para las 15 vistas del MVP en `features/auth`, `features/dashboard`, `features/bienestar`, `features/retos`, `features/academico`, `features/notificaciones`, `features/social` y `features/perfil`.
- Se añadieron providers iniciales de estado en `features/auth`, `features/dashboard`, `features/bienestar` y `features/retos`.

### Calidad y verificación
- Se corrigieron errores de compilación y lints deprecados detectados por `flutter analyze`.
- Se actualizó el test base en [app/test/widget_test.dart](app/test/widget_test.dart).
- Estado final de validación: `flutter analyze` sin issues y `flutter test` con pruebas en verde.

---

## [2.5.0] — 19-04-2026

### Documentación
- **Reestructuración completa:** Migración de 6 archivos con nombres arbitrarios al estándar de 14 puntos del equipo jloen.
- Se crearon los archivos faltantes: `01-introduction.md`, `05-api.md`, `06-frontend.md`, `07-backend.md`, `08-installation.md`, `09-testing.md`, `10-deployment.md`, `11-security.md`, `12-user-guide.md`, `13-maintenance.md`, `14-changelog.md`.
- Se renombraron: `03-architecture-rfc.md` → `03-architecture.md`, `06-database-schema.md` → `04-data-model.md`.
- Se eliminaron archivos obsoletos: `01-project-documentation-index.md`, `04-design-phase.md`, `05-screen-specifications.md`.

### Requisitos (SRS v2.5)
- 19 casos de uso completos (CU-01 a CU-19) con flujos principales, alternativos y de excepción.
- Módulo académico expandido: asignaturas, evaluaciones, calificaciones, notas rápidas.
- Módulo de bienestar expandido: perfil físico, recomendación semanal de entrenamiento, catálogo de ejercicios.
- 20 reglas de negocio formalizadas.
- Matriz de trazabilidad requisitos → diseño → código.

### Arquitectura (RFC v2.5)
- Stack definido: Flutter + Supabase + Cloudflare R2.
- Estructura de carpetas Clean Architecture por features.
- 9 repositorios de dominio con contratos completos.
- 6 canales Realtime definidos.
- Pipeline de ingesta wger documentado paso a paso.

### Diseño (v2.0)
- 15 pantallas funcionales generadas en Stitch (todas en español es-ES).
- Design System Synapse Velocity aplicado con tokens de color, tipografía y espaciado.
- Flujos UX detallados con diagramas Mermaid.
- Cobertura 100% de los 14 casos de uso MVP.

### Modelo de Datos (v1.0)
- 13 tablas principales con constraints y validaciones SQL.
- Políticas RLS completas por tabla.
- 3 stored procedures: detección de conflictos, cálculo de progreso, sistema XP.
- Índices de performance para queries críticos.

---

## [1.0.0] — 16-04-2026

### Inicio del proyecto
- Definición inicial de la idea: app de bienestar para estudiantes.
- Investigación de competencia (StudySmarter, Habitica, Duolingo).
- Análisis de viabilidad técnica (Flutter, Supabase, wger).
- Primera versión del SRS con requisitos base.

---

**Mantenido por:** Equipo jloen  
**Convención de commit:** `feat:`, `fix:`, `docs:`, `refactor:`
