# Modelo de datos

> **Qué es:** quién es dueño de cada tabla y qué cambió respecto al esquema heredado de Supabase.
> **Fuente de verdad del esquema:** `backend/src/main/resources/db/migration/postgresql/` (Flyway; una carpeta por motor, `DB_VENDOR`).
> **Regla:** la base de datos solo guarda datos; ninguna regla de negocio vive en vistas, columnas generadas, triggers ni consultas (ADR 0012, `docs/06-ops/database_portability.md`).

## Propiedad de las tablas

Cada tabla tiene **un único módulo propietario**: solo él la mapea como entidad JPA y la modifica. Otro módulo que necesite leerla lo hace con `JdbcClient` en su adaptador de persistencia; si necesita provocar un cambio, publica un evento de dominio (`events.md`).

| Módulo | Tablas |
|---|---|
| Núcleo (auth, cuenta, XP) | `usuarios`, `refresh_tokens`, `restablecimientos_contrasena`, `configuracion_global` (lectura) |
| Perfil y catálogo | `perfil_bienestar_usuario`, `perfil_academico_usuario`, `historial_peso`, `historial_objetivos`, `usuario_carreras`, `universidades`, `centros`, `carreras`, `asignaturas_catalogo`, `bibliografia_asignatura`, `profesores_asignatura`, `criterios_evaluacion`, `prerrequisitos_asignatura` |
| Entrenamiento | `ejercicios`, `ejercicio_nombres`, `vocabulario_nombres`, `ejercicio_equipamiento`, `ejercicio_musculo_objetivo`, `ejercicio_musculo_secundario`, `ejercicio_parte_cuerpo`, `equipamientos`, `musculos`, `partes_cuerpo`, `rutinas`, `semanas_rutina`, `dias_rutina`, `seleccion_de_ejercicios`, `sesiones_registradas`, `series_sesion`, `plan_entrenamiento_semanal`, `estado_diario_usuario`, `recomendaciones_pendientes` |
| Académico | `asignaturas`, `asignaturas_usuario_semestre`, `apuntes`, `archivos_asignatura`, `documentos_ia`, `importaciones_plan_docente`, `materiales_estudio`, `registros_repaso_srs`, `bancos_preguntas`, `preguntas`, `intentos_pregunta`, `test_sessions` |
| Planificador | `horarios_academicos`, `planes_estudio`, `entregas_examenes`, `carga_academica_semanal`, `sesiones_focus`, `suscripciones_calendario` |
| Gamificación | `retos`, `hitos_de_reto`, `progreso_de_reto`, `insignias`, `usuario_insignias` |
| Social | `actividades_sociales`, `interacciones_sociales`, `comentarios_feed`, `amistades`, `notificaciones`, `preferencias_notificacion` |
| Indicadores (neurofisiología y analítica) | `estado_cognitivo_usuario`, `estado_regulacion_cruzada`, `registros_carga_fisica` |
| Administración | `admin_auditoria`, `configuracion_global` (escritura) |

**Excepción justificada:** el borrado y la anonimización RGPD (`UserDataErasureJdbcAdapter`, módulo de administración) borra en tablas de todos los módulos dentro de una única transacción, porque el derecho de supresión es transversal y debe ser atómico. Un módulo que añada una tabla con `usuario_id` sin `ON DELETE CASCADE` debe incluirla en ese adaptador y en la exportación (`UserDataExportJdbcAdapter`).

## Cambios respecto al esquema heredado

Las 62 migraciones de Supabase se consolidaron en `V1__baseline_schema.sql`. `V2__seed_catalog.sql` carga el catálogo (universidades, plan de estudios, 909 ejercicios con su MET, insignias). `V850` amplía el catálogo de ejercicios a unos 5.400.

| Cambio | Motivo |
|---|---|
| `usuarios` deja de referenciar `auth.users`; añade `password_hash` y `google_sub` (+ CHECK de que exista alguna credencial) | Autenticación propia |
| Nueva tabla `refresh_tokens` (solo hash SHA-256) | Sesiones con token de refresco rotatorio |
| `usuarios.xp_total` → `xp_nivel_actual` | Guardaba la experiencia dentro del nivel, no el total |
| `usuarios.nivel_privacidad` y `apuntes.visibilidad` usan `private`/`friends`/`public` | Había tres vocabularios distintos (`privado`, `solo_amigos`…) |
| `entregas_examenes`: eliminado el CHECK duplicado `ck_entregas_tipo` | Dos CHECK contradictorios; valores válidos: `examen`, `entrega`, `presentacion`, `otro` |
| `ejercicios.dificultad` por defecto `intermedio` | El valor por defecto `medio` violaba su propio CHECK |
| `comentarios_feed.creado_en_idx` eliminado | Columna sin uso |
| `interacciones_sociales` solo guarda likes | Los comentarios viven en `comentarios_feed` |
| `admin_auditoria.admin_id` admite NULL con `ON DELETE SET NULL` | El registro de auditoría no debe desaparecer al borrar al admin |
| FKs añadidas: `retos.asignatura_id`, `hitos_de_reto.asignatura_id`, `documentos_ia.asignatura_id`, `archivos_asignatura.usuario_id`; `registros_carga_fisica.sesion_id` con `ON DELETE CASCADE` | Integridad referencial que faltaba |
| Índices duplicados eliminados | Coste de escritura sin beneficio |
| `V940`: los avisos automáticos enviados antes de `V900` reciben su `codigo_mensaje` y `parametros_mensaje`, deducidos de `clave_referencia` o de su texto fijo; los escritos a mano por la administración no cambian | Que los avisos antiguos también se lean en el idioma de la app |
| `V930`: tablas `ejercicio_nombres` (`ejercicio_id`, `idioma`, `nombre`; 16.335 filas) y `vocabulario_nombres` (`termino` en español, `idioma`, `nombre`; músculos, material y partes del cuerpo). Idiomas `en`, `fr` y `pt` (portugués de Portugal) | Nombres técnicos de gimnasio en el idioma de la app (ADR 0017). El español de `ejercicios.nombre` sigue siendo el canónico: `RoutineRuleEngine` y `ExerciseEligibility` buscan palabras en él. Generado con `tools/exercises/build_names_migration.py`. Los ejercicios creados o renombrados desde el panel guardan aquí sus nombres revisados (propuestos por IA) |
| `V920`: los avisos de insignia ya enviados enlazan a `/progress/badges` en vez de al perfil | Tocar el aviso lleva a las insignias |
| `V910`: la descripción de la insignia de constancia deja de decir «check-in» («Cuenta cómo estás 7 días seguidos») | Lenguaje sencillo |
| `V900`: `notificaciones.codigo_mensaje` y `notificaciones.parametros_mensaje` (`jsonb`), opcionales | Los avisos automáticos se muestran en el idioma de quien los lee (ADR 0017); título y descripción quedan en español como respaldo |
| `V850`: catálogo de ejercicios ampliado a unos 5.400 (openGym, ADR 0016). Columnas nuevas `ejercicios.categoria` (12 valores de `ExerciseCategory` en minúsculas: `strength`, `stretching`, `mobility`…; índice `idx_ejercicios_categoria`) y `ejercicios.codigo_externo` (código de la fuente, para no duplicar al regenerar); 11 equipamientos nuevos; descripción e instrucciones nuevas en los 909 originales | Buscar por tipo de ejercicio, elegir calentamiento y vuelta a la calma y ofrecer alternativas. Una categoría desconocida o nula se deduce de la modalidad |
| `V800`: catálogo académico de España (96 universidades del RUCT con tipo y comunidad, 3.486 grados y 4.829 asignaturas) | Elegir universidad, grado y asignaturas al registrarse sin escribirlos a mano |
| `V700`: nombres de 689 ejercicios corregidos al español (traducciones erróneas, inglés y erratas del catálogo Lyfta); cada `UPDATE` solo cambia la fila si el nombre sigue siendo el original | Calidad del catálogo. Ojo: `RoutineRuleEngine` y `ExerciseEligibility` buscan palabras en el nombre, así que algunos ejercicios con salto («Saltos de tijera», «Sentadilla con salto») pasan a considerarse de alto impacto, que es lo correcto |
| `V650`: `usuarios.enfoque` (`academico`, `deporte`, `ambos`; NULL = sin elegir) y `usuarios.onboarding_completado`; las cuentas existentes quedan en `ambos` y heredan el cierre del onboarding de `perfil_bienestar_usuario` | Enfoque de uso (ADR 0014); con solo estudios no existe el perfil físico donde se guardaba el cierre |
| `V600`: `notificaciones.clave_referencia` (opcional, con índice `(usuario_id, clave_referencia)`); se rellena para los avisos ya enviados de retos completados y subidas de nivel | Los avisos automáticos se deduplicaban por tipo + título + descripción y un segundo reto con el mismo título no avisaba nunca. Ahora `AutomaticNotificationService` usa una clave estable (`challenge:<id>`, `badge:<id>`, `level:<n>`, `fatigue:<motivo>:<día>`) |
| `V550`: se eliminan las vistas `v_admin_metricas`, `v_analitica_semanal` y `v_ejercicios_completos` | Calculaban valores de negocio en SQL propio de PostgreSQL; ahora lo hacen `AdminActivityAggregation` y `WeeklyTrainingMetric.byWeek` (ADR 0012) |
| `V500`: `sesiones_focus.bloque_id`, `sesiones_focus.asignatura_id` (opcionales, `ON DELETE SET NULL`) y `sesiones_focus.xp_otorgado`; `retos.sesiones_objetivo` (1-365, opcional) y `retos.sesiones_completadas` | Pomodoro vinculado a un bloque y una asignatura, con XP de tope diario calculado sumando lo ya concedido; retos de fitness que avanzan con las sesiones de entrenamiento recontadas desde cero (ADR 0009) |
| `V450`: `ck_usuarios_credencial` admite cuentas anonimizadas (`eliminado_en IS NOT NULL`); `v_admin_metricas` con «hoy» en UTC y sin contar cuentas eliminadas | La anonimización RGPD dejaba la fila sin credenciales |
| `V960`: `suscripciones_calendario` (una por usuario, solo la huella SHA-256 del token; ADR 0020) | Ver el planificador en Google, Apple u Outlook con un enlace privado que se actualiza solo |
| `V980`: `suscripciones_resumen_semanal` (una por usuario; doble confirmación, solo la huella del token de confirmación; ADR 0022) | Resumen semanal por correo |
| `V970`: `restablecimientos_contrasena` (solo la huella SHA-256, caduca a los 30 min, un uso; ADR 0021) | Recuperar la contraseña por correo |
| `V950`: `registros_carga_fisica.bloque_id` (FK a `horarios_academicos`, `ON DELETE CASCADE`). Cada registro viene de una sesión (`sesion_id`) o de un bloque de deporte sin rutina (`bloque_id`) | Los bloques de deporte daban XP pero no contaban para el ACWR ni la fatiga |
| `V400`: `carga_aguda_7d` y `carga_cronica_28d` son medias diarias (ACWR coherente); índice único de `registros_carga_fisica.sesion_id`. Regla del dominio (`CrossRegulationState`): sin carga anterior a los últimos 7 días no hay línea base, `carga_cronica_28d` se guarda a 0 y `acwr_actual` queda NULL (zona `NO_DATA`); endurecida en el ADR 0019: hace falta carga en 2 de las 3 semanas anteriores | El ACWR heredado salía ~7 veces mayor y podía duplicar la carga de una sesión; sin línea base, la primera semana de un usuario nuevo daba ACWR 4 y avisaba de sobreentrenamiento |
| `V350`: `comentarios_feed.reportado_por` e índices de moderación, notificaciones y amistades | Saber quién reportó un comentario; consultas del muro y notificaciones eficientes |
| `V100`: `dias_disponibles` NOT NULL y coherente con `dias_disponibles_semana`; objetivo por defecto válido; CHECK de fechas de clase; un único periodo de objetivo abierto | Datos de perfil contradictorios y valores por defecto que violaban sus CHECK |
| `V300`: insignia «Planificador Maestro» | Su criterio existía en el motor pero faltaba en el catálogo |
| `V250`: `horarios_academicos.material_estudio_id` y `planes_estudio.xp_planificacion_puntos` | Repasos SM-2 idempotentes en el calendario; restar exactamente la XP del plan al borrarlo |
| `V150`: `sesiones_registradas.completada_en` admite NULL (sesión en curso) y añade `xp_otorgado` | El inicio de sesión insertaba datos falsos que contaban como completados; restar exactamente la XP al desmarcar. **Contrato:** una sesión cuenta como realizada solo si `completada_en IS NOT NULL` |
| Sin RLS, políticas, `GRANT`, publicación realtime ni funciones/triggers | La autorización y las reglas de negocio viven en el backend |

## Lógica que salió de la base de datos

| Antes (función o trigger SQL) | Ahora |
|---|---|
| `otorgar_xp`, `restar_xp` | `User.gainExperience` / `loseExperience` + `AwardExperienceUseCase` / `RevokeExperienceUseCase` |
| `handle_new_auth_user`, `trg_inicializar_estado_cognitivo` | Registro en `AuthService` + evento `UserRegistered` |
| `shadowban_nuevo_si_lockdown` | `AuthService` consulta `PlatformSettingsPort` al registrar |
| `invalidar_contenido_al_privatizar` | Evento `UserPrivacyChanged` |
| `sync_entrega_a_reto`, `sync_reto_a_entrega`, `sync_hito_a_entrega` | Eventos `DeadlineCompletionChanged` y `ChallengeLinkCompletionChanged` |
| `fn_actualizar_progreso_hito` | Evento `StudyBlockCompletionChanged` |
| `trg_insertar_carga_fisica`, `recalcular_regulacion_cruzada` | Evento `TrainingSessionCompletionChanged` |
| `marcar_semana_completada`, `actualizar_estado_semana` (contradictorios entre sí) | Regla única en el dominio de entrenamiento |
| `es_admin`, políticas RLS | Rol en el JWT + comprobación de propiedad en los casos de uso |
| `anonymize_user`, `exportar_datos_usuario`, `delete_user`, `wipe_user_data` | Casos de uso de administración (RGPD) |
| Vistas `v_admin_metricas`, `v_analitica_semanal` | `AdminActivityAggregation`, `WeeklyTrainingMetric.byWeek` (aplicadas en los casos de uso; los puertos solo devuelven filas) |
| Columnas generadas `carga_diaria` y `acwr_actual` (se conservan como copia, la app no las lee) | `PhysicalLoadRecord.load` + `PhysicalLoadHistory`; `CrossRegulationState` |
| Progreso de retos con `CASE` en el SQL del inicio | `Challenge.progress()` vía `ListMyChallengesUseCase` |
