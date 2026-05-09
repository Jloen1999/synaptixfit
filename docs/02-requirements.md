# 02 - Requisitos del Producto (SRS)

Version: 2.9
Estado: IN_PROGRESS (Módulo académico completado — Hitos 1-8 implementados)
Fecha: 09-05-2026
Referencia cruzada: docs/03-architecture-rfc.md

## 1. Resumen Ejecutivo
SynaptixFit es una aplicacion movil/web para estudiantes que integra organizacion academica, gamificacion de retos y bienestar fisico en una sola experiencia. El objetivo es reducir la fragmentacion entre apps de estudio, habitos y comunidad, aumentando la constancia semanal del usuario.

Este documento define una especificacion de requisitos de estilo profesional (SRS), cubriendo alcance, requisitos funcionales y no funcionales, casos de uso, flujos alternativos, flujos de excepcion, reglas de negocio y criterios de aceptacion.

## 2. Objetivos del Producto

### 2.1 Objetivo general
Proveer un MVP multiplataforma que permita planificar estudio, registrar progreso personal y reforzar adherencia mediante dinamicas de gamificacion y comunidad.

### 2.2 Objetivos especificos
1. Unificar en una sola app planificacion academica y bienestar fisico.
2. Incrementar la constancia semanal del usuario con recordatorios y seguimiento visible.
3. Incorporar control granular de privacidad por contenido.
4. Sentar una base tecnica escalable para fases posteriores.

### 2.3 Metricas de exito (KPIs)
1. Activacion: porcentaje de usuarios que crean su primer plan en menos de 24 horas.
2. Retencion semanal: porcentaje de usuarios activos al dia 7.
3. Adherencia: porcentaje de usuarios que completan al menos 1 reto y 1 rutina por semana.
4. Interaccion social: promedio de likes por publicacion de logro.

## 3. Alcance

### 3.1 Alcance MVP (Fase 1)
1. Registro/login y perfil de usuario.
2. Modulo academico base:
   - Gestion de asignaturas.
   - Planes de estudio en calendario semanal.
   - Vinculacion de bloques y apuntes con asignaturas.
   - Registro de evaluaciones (examenes, practicas, entregas).
   - Registro de calificaciones por evaluacion.
   - CRUD de apuntes en texto enriquecido.
   - Visibilidad por recurso (publico, privado, solo_amigos).
3. Modulo de retos base:
   - Crear y completar retos simples.
   - Clonar retos publicos al propio perfil.
4. Modulo bienestar base:
   - Crear y completar rutinas.
5. Comunidad basica:
   - Feed de logros.
   - Likes.
6. Notificaciones basicas de recordatorio.

### 3.2 Alcance Fase 2 (no bloqueante MVP)
1. Retos complejos con hitos encadenados.
2. Comentarios y moderacion en feed.
3. Insignias y rachas avanzadas.
4. Recomendaciones inteligentes de equilibrio estudio/actividad.
5. Integraciones externas avanzadas (calendarios y wearables).

### 3.3 Fuera de alcance MVP
1. Chat en tiempo real entre usuarios.
2. Marketplace de plantillas.
3. Recomendador IA avanzado completo.
4. Integracion completa con relojes inteligentes.

## 4. Stakeholders y Perfil de Usuario

### 4.1 Stakeholders
1. Estudiante usuario final.
2. Tutor academico (supervision del TFG).
3. Equipo de desarrollo (frontend/backend).
4. Evaluadores del TFG.

### 4.2 Publico objetivo
1. Primario: estudiantes universitarios (18-30 anos).
2. Secundario: bachillerato y opositores.
3. Perfil comun: alta carga academica y necesidad de rutina semanal.

## 5. Fuentes y Hallazgos de Investigacion
Fecha de investigacion: 16-04-2026.

### 5.1 Competencia
1. StudySmarter: foco academico integral.
2. Habitica: gamificacion y social fuerte.
3. Duolingo: buenas practicas de retencion por progreso corto.

### 5.2 Brecha detectada
1. Apps academicas con poca conexion a bienestar fisico.
2. Apps de habitos poco orientadas al contexto academico.
3. Oportunidad en un producto vertical con permisos sociales granulares.

### 5.3 Viabilidad tecnica
1. Flutter permite base unica Android/iOS/Web.
2. Supabase cubre auth, Postgres, realtime y RLS.
3. Push multiplataforma viable con proveedor dedicado.

### 5.4 Necesidades generales del estudiante (evidencia aplicada)
1. Salud mental y presion academica:
   - Referencia: WHO (mental health of adolescents) reporta que 1 de cada 7 adolescentes presenta un trastorno mental y que depresion/ansiedad impactan asistencia y desempeno academico.
   - Implicacion de producto: incluir mecanismos de carga sostenible, recordatorios no intrusivos y opciones de pausa/reprogramacion.
2. Bienestar fisico y sedentarismo:
   - Referencia: WHO (physical activity) destaca alta inactividad global y beneficio directo de actividad fisica sobre bienestar mental y cognitivo.
   - Implicacion de producto: integrar rutinas realistas, metas semanales graduales y seguimiento de adherencia.
3. Necesidad de entornos seguros y de apoyo:
   - Referencia: CDC YRBS 2023 destaca impacto de factores sociales y del entorno escolar en salud mental.
   - Implicacion de producto: fortalecer privacidad, control de visibilidad y dinamicas sociales positivas.
4. Necesidad de constancia y estructura:
   - Referencia: analisis de competencia (StudySmarter, Habitica, Duolingo) y literatura de adherencia digital.
   - Implicacion de producto: ciclos cortos de progreso, feedback frecuente, retos escalables y visualizacion de avance.

### 5.5 Fuentes consultadas en esta iteracion
1. WHO - Physical activity fact sheet.
2. WHO - Mental health of adolescents fact sheet.
3. WHO - Depressive disorder (depression) fact sheet.
4. CDC - 2023 Youth Risk Behavior Survey Results (YRBS).
5. Freeletics - enfoque de coach adaptable, seleccion de dias/tiempo y ajuste dinamico del plan.
6. Hevy - enfoque de seguimiento de sesiones, progreso, historial y adherencia.
7. wger - API/dataset open source para ejercicios (evaluado y descartado temporalmente por incidencias operativas y calidad multimedia).
8. Workout.cool - base open source moderna para catalogo de ejercicios y rutinas.
9. ExerciseDB (AscendAPI en Kaggle), API Ninjas y YMove - evaluadas como referencia de mercado para limites, multimedia y viabilidad de MVP.

### 5.6 Decision arquitectonica para catalogo de ejercicios (MVP)
1. Decision adoptada: el dataset de ejercicios (metadatos) debe residir en Supabase (base propia), no depender en tiempo real de una API externa para pantallas core.
2. Justificacion tecnica resumida:
   - Integridad relacional: permite vincular usuarios, rutinas y ejercicios con consultas SQL consistentes.
   - Rendimiento y resiliencia: menor latencia y mejor soporte offline con cache local en Flutter.
   - Control de producto: facilita curacion, traduccion al espanol, correccion de multimedia y versionado.
   - Coste y continuidad: evita bloqueos por limites de uso o cambios comerciales de terceros.
   - Operacion de archivos: los recursos multimedia (gif/mp4/jpg) se sirven desde bucket R2 de Cloudflare para aislar almacenamiento de objetos.
3. Comparativa ejecutiva de alternativas:

| Alternativa | Ventaja principal | Riesgo principal |
| --- | --- | --- |
| API externa en tiempo real desde Flutter | Datos potencialmente actualizados al instante | Dependencia externa, limites de uso, mayor latencia y acoplamiento en cliente |
| Dataset propio en Supabase | Integridad relacional, control total y mejor rendimiento | Requiere carga inicial y proceso de mantenimiento de datos |

4. Estado actual de proveedor fuente para seeding:
   - Proveedor adoptado: ExerciseDB (AscendAPI), distribuido via Kaggle.
   - Repositorio `exercisedb-api` en GitHub se considera soporte documental/legal (README + LICENSE), no fuente primaria de datos pesados.
   - Paquete de datos adoptado: `exercisedb/fitness-exercises-dataset` en Kaggle.
   - Causas de adopcion: estructura relacional util (`exercises.json`, `muscles.json`, `equipments.json`, `bodyParts.json`) y disponibilidad de multimedia optimizada (`gifs_180x180`).

### 5.7 Estrategia de seeding (adopcion industrial)
1. Extraer dataset fuente mediante script puntual (JSON/CSV) desde proveedor seleccionado.
   - Fuente aprobada para MVP: descarga desde Kaggle del dataset oficial de ExerciseDB (AscendAPI).
2. Normalizar estructura a modelo interno (ejercicio, grupo muscular, equipamiento, idioma, fuente).
   - Flujo vigente de idioma: traduccion a espanol previa a la importacion de metadatos.
   - Scripts operativos usados en esta iteracion:
     - `exercisedb/traducir_ejercicios.py` para `exercises.json`.
     - `exercisedb/traducir.py` para `muscles.json`, `equipments.json` y `bodyParts.json` (cambiando `ARCHIVO_ENTRADA`/`ARCHIVO_SALIDA` por corrida).
3. Importar metadatos a tabla `ejercicios` en Supabase con fuente, licencia y version.
4. Cargar archivos multimedia al bucket R2 y guardar en Supabase solo referencia (url/clave) y metadatos tecnicos.
5. Ejecutar refresco batch controlado (manual o programado), evitando dependencia runtime en el cliente.
6. Mantener trazabilidad de versiones del dataset para auditoria academica y tecnica.

## 6. Requisitos Funcionales

### 6.1 Convenciones
1. Prioridad: MUST (MVP), SHOULD (alto valor), COULD (fase posterior).
2. Todos los requisitos deben tener criterio de aceptacion verificable.

### 6.2 Autenticacion y perfil
1. RF-AUTH-01 (MUST): El sistema debe permitir registro con email y proveedores sociales.
   - Criterio: el usuario puede crear cuenta y autenticarse.
2. RF-AUTH-02 (MUST): El usuario debe editar su perfil basico (nombre, carrera, meta_semanal).
   - Criterio: los cambios persisten tras cerrar y reabrir sesion.
3. RF-AUTH-03 (SHOULD): El usuario debe gestionar amistades (solicitar, aceptar, eliminar).
   - Criterio: el estado de amistad cambia correctamente y afecta visibilidad.
4. RF-AUTH-04 (SHOULD): El usuario debe poder completar su perfil extendido (biografia corta, avatar y objetivos personales).
   - Criterio: la biografia se guarda con limite de longitud y puede editarse en cualquier momento.
5. RF-AUTH-05 (SHOULD): El usuario debe definir la visibilidad de su perfil (publico, solo_amigos o privado).
   - Criterio: la informacion del perfil se muestra segun su configuracion de privacidad.

### 6.3 Modulo academico
1. RF-ACA-01 (MUST): Crear, editar y eliminar planes de estudio semanales.
2. RF-ACA-02 (MUST): Crear, editar y eliminar bloques de estudio con asignatura, horario y prioridad.
3. RF-ACA-03 (MUST): CRUD de apuntes con texto enriquecido.
4. RF-ACA-04 (MUST): Definir visibilidad de plan y apunte (publico, privado, solo_amigos).
5. RF-ACA-05 (MUST): Aplicar control de acceso segun visibilidad y amistad.
6. RF-ACA-06 (MUST): Crear, editar y archivar asignaturas (nombre, codigo opcional, docente opcional).
   - Criterio: el usuario puede mantener su listado de asignaturas activo por periodo.
7. RF-ACA-07 (MUST): Vincular bloques de estudio y apuntes a una asignatura concreta.
   - Criterio: todo bloque debe quedar asociado a una asignatura existente.
8. RF-ACA-08 (SHOULD): Registrar evaluaciones por asignatura (tipo, fecha, peso institucional opcional, nota objetivo).
   - Criterio: el usuario puede visualizar evaluaciones en calendario y por asignatura.
9. RF-ACA-09 (SHOULD): Registrar calificaciones reales por evaluacion.
   - Criterio: el sistema guarda historico y fecha de registro de cada calificacion.
10. RF-ACA-10 (SHOULD): Calcular progreso academico por asignatura usando evaluaciones y calificaciones disponibles.
   - Criterio: mostrar estado por asignatura (al dia, en riesgo, pendiente de nota).
11. RF-ACA-11 (SHOULD): Permitir notas rapidas vinculadas o no a asignatura para capturas inmediatas.
   - Criterio: las notas rapidas pueden convertirse a apunte formal sin perder contenido.

### 6.4 Modulo de retos
1. RF-RET-01 (MUST): Crear retos simples con meta y fecha limite.
2. RF-RET-02 (MUST): Registrar progreso y completar retos.
3. RF-RET-03 (MUST): Ver retos publicos de otros usuarios.
4. RF-RET-04 (MUST): Clonar reto publico al propio perfil.
5. RF-RET-05 (SHOULD): Crear retos complejos con hitos secuenciales o paralelos.
   - Criterio: el usuario define al menos 2 hitos, dependencias y fechas objetivo.
6. RF-RET-06 (SHOULD): Calcular automaticamente la importancia de cada hito en funcion de su orden.
   - Criterio: el usuario solo define el orden y el sistema recalcula el avance global al reordenar hitos.
7. RF-RET-07 (SHOULD): Permitir pausar, reprogramar o cancelar retos complejos sin perder historial.
   - Criterio: toda transicion de estado queda registrada con fecha y actor.
8. RF-RET-08 (SHOULD): Validar dependencias entre hitos para evitar cierres inconsistentes.
   - Criterio: no puede cerrarse un hito bloqueado por otro no completado.
9. RF-RET-09 (COULD): Recomendar ajuste de dificultad segun cumplimiento historico del usuario.

#### 6.4.1 Mini norma de calculo (retos complejos)
1. El usuario no introduce pesos manuales.
2. El usuario solo crea y ordena hitos.
3. El sistema asigna automaticamente la importancia de cada hito segun su posicion en el orden actual.
4. Cuando el usuario reordena hitos, el sistema recalcula automaticamente el avance global del reto.
5. El avance global siempre se muestra en porcentaje de 0 a 100.
6. Si dos hitos estan al mismo nivel de prioridad, se usa el orden visual actual como desempate.
7. Toda recalculacion debe quedar registrada en historial tecnico para auditoria.

### 6.5 Modulo bienestar
1. RF-BIE-01 (MUST): Registrar perfil fisico inicial del estudiante (peso, altura y nivel de condicion actual).
   - Criterio: el sistema valida rangos permitidos y permite actualizacion periodica.
2. RF-BIE-02 (MUST): Registrar contexto de entrenamiento (dias disponibles por semana, tiempo por sesion, equipamiento disponible y objetivo principal).
   - Criterio: la recomendacion semanal usa estos datos como entrada obligatoria.
3. RF-BIE-03 (MUST): Crear y guardar rutinas por objetivo (fuerza, resistencia, movilidad, mixto).
   - Criterio: cada rutina incluye duracion estimada y nivel de exigencia.
4. RF-BIE-04 (SHOULD): Recomendar numero de sesiones semanales de entrenamiento de forma automatica.
   - Criterio: la recomendacion se adapta al perfil, disponibilidad y adherencia reciente.
5. RF-BIE-05 (SHOULD): Recomendar duracion e intensidad de sesion por semana.
   - Criterio: el sistema evita aumentos bruscos entre semanas consecutivas.
6. RF-BIE-06 (MUST): Registrar sesion completada con duracion real y esfuerzo percibido.
   - Criterio: cada sesion guarda fecha, rutina, duracion y nivel de esfuerzo reportado.
7. RF-BIE-07 (SHOULD): Recalcular el plan semanal cuando se detecte baja adherencia o fatiga alta.
   - Criterio: el sistema propone ajuste de carga y frecuencia para la semana siguiente.
8. RF-BIE-08 (SHOULD): Incluir recomendaciones de calentamiento y vuelta a la calma en cada sesion.
   - Criterio: el usuario visualiza ambas partes antes de iniciar la sesion.
9. RF-BIE-09 (SHOULD): Permitir alternativas de ejercicios segun equipamiento disponible o entrenamiento en casa.
   - Criterio: la rutina mantiene el objetivo aunque cambie el ejercicio.
10. RF-BIE-10 (MUST): Mostrar tablero semanal de bienestar con sesiones planificadas vs completadas.
   - Criterio: el usuario ve cumplimiento, tendencia y proxima accion sugerida.
11. RF-BIE-11 (MUST): Permitir buscar, filtrar y seleccionar ejercicios del catalogo para construir o editar rutinas.
   - Criterio: el usuario puede filtrar por objetivo, grupo muscular, equipamiento y nivel.
12. RF-BIE-12 (MUST): Mostrar ficha de ejercicio con instrucciones y recurso multimedia alojado en Cloudflare R2.
   - Criterio: la app muestra previsualizacion tecnica del ejercicio y alternativa textual si el recurso multimedia falla.

#### 6.5.1 Mini norma de recomendacion semanal (bienestar)
1. El usuario no calcula manualmente la carga semanal.
2. El sistema propone sesiones por semana en base a perfil fisico, objetivo y disponibilidad.
3. La progresion semanal no debe aumentar la carga total de forma abrupta.
4. Si la adherencia baja de un umbral definido o se reporta fatiga alta, el sistema reduce temporalmente la exigencia.
5. Debe reservarse al menos un dia de descanso en la planificacion semanal.
6. Todas las recalibraciones del plan quedan registradas para trazabilidad.
7. Las recomendaciones son orientativas y no sustituyen evaluacion profesional de salud.

### 6.6 Comunidad
1. RF-SOC-01 (MUST): Generar publicaciones de logro (reto o rutina completada).
2. RF-SOC-02 (MUST): Mostrar feed segun reglas de visibilidad.
3. RF-SOC-03 (MUST): Permitir like a publicaciones visibles.
4. RF-SOC-04 (COULD): Comentarios y notificaciones sociales.

### 6.7 Notificaciones
1. RF-NOT-01 (MUST): Recordatorios de bloques de estudio.
2. RF-NOT-02 (MUST): Recordatorios de retos y rutinas.
3. RF-NOT-03 (MUST): Activar/desactivar categorias de notificaciones.
4. RF-NOT-04 (SHOULD): Configurar ventanas horarias de silencio y frecuencia maxima de avisos.
   - Criterio: el usuario define franja sin notificaciones y limite diario.
5. RF-NOT-05 (SHOULD): Priorizar notificaciones por urgencia (vencimientos proximos, baja adherencia).
   - Criterio: el sistema ordena envios evitando saturacion.

### 6.8 Analitica y autorregulacion academica
1. RF-ANA-01 (SHOULD): Mostrar tablero semanal de cumplimiento (estudio, retos, rutinas).
2. RF-ANA-02 (SHOULD): Detectar sobrecarga semanal por exceso de bloques o metas irreales.
3. RF-ANA-03 (SHOULD): Sugerir microajustes de plan (redistribuir bloques, dividir metas grandes).
4. RF-ANA-04 (COULD): Exportar resumen semanal en formato compartible.

### 6.9 Seguridad de bienestar y uso responsable
1. RF-SAF-01 (MUST): Incluir mensajes de uso responsable indicando que la app no sustituye atencion profesional.
2. RF-SAF-02 (SHOULD): Mostrar recursos de ayuda cuando el usuario reporte alto nivel de estres o bloqueo sostenido.
3. RF-SAF-03 (MUST): Permitir desactivar publicaciones automaticas de logros para reducir presion social.

## 7. Casos de Uso Detallados (con flujo alternativo y excepcion)

### 7.1 CU-01 Registro e inicio de sesion
1. Actor principal: Estudiante.
2. Precondiciones: la app esta instalada o accesible por web.
3. Disparador: el usuario selecciona registrarse o iniciar sesion.
4. Flujo principal:
   1. El usuario ingresa credenciales o selecciona login social.
   2. El sistema valida datos.
   3. El sistema autentica usuario.
   4. El sistema redirige a Home.
5. Flujo alternativo:
   1. A1 - Recuperacion de contrasena: el usuario solicita recuperacion y recibe enlace o codigo.
   2. A2 - Login social con cuenta existente: el sistema vincula identidad y continua.
6. Flujo de excepcion:
   1. E1 - Credenciales invalidas: mostrar error y permitir reintento.
   2. E2 - Proveedor social no disponible: ofrecer login por email.
7. Postcondiciones: sesion activa y token valido.
8. Requisitos relacionados: RF-AUTH-01.

### 7.2 CU-02 Gestionar plan de estudio y bloques
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado.
3. Flujo principal:
   1. El usuario crea un plan semanal.
   2. El usuario selecciona o crea asignaturas del periodo.
   3. Agrega bloques con asignatura, horario y prioridad.
   4. Guarda cambios.
   5. El sistema persiste y muestra plan actualizado.
4. Flujo alternativo:
   1. A1 - Edicion parcial: el usuario edita solo un bloque.
   2. A2 - Cambio de visibilidad: el usuario cambia plan a solo_amigos o privado.
   3. A3 - Reordenar bloques: el usuario cambia el orden recomendado del dia.
5. Flujo de excepcion:
   1. E1 - Solapamiento horario: el sistema avisa conflicto y sugiere ajuste.
   2. E2 - Error de conexion: guardar en cola local y reintentar sincronizacion.
   3. E3 - Asignatura inexistente: bloquear guardado del bloque y pedir seleccion valida.
6. Postcondiciones: plan consistente y visible segun permisos.
7. Requisitos relacionados: RF-ACA-01, RF-ACA-02, RF-ACA-04, RF-ACA-05, RF-ACA-06, RF-ACA-07.

### 7.3 CU-03 Crear y administrar apuntes
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado.
3. Flujo principal:
   1. El usuario crea un apunte.
   2. Edita contenido en texto enriquecido.
   3. Define visibilidad.
   4. Guarda apunte.
4. Flujo alternativo:
   1. A1 - Guardado automatico: el sistema guarda borrador periodico.
   2. A2 - Duplicar apunte propio para reutilizar estructura.
   3. A3 - Convertir nota rapida en apunte formal con un solo paso.
5. Flujo de excepcion:
   1. E1 - Contenido invalido (tamano maximo excedido): avisar y bloquear guardado.
   2. E2 - Permiso insuficiente en edicion: denegar accion.
6. Postcondiciones: apunte persistido y controlado por visibilidad.
7. Requisitos relacionados: RF-ACA-03, RF-ACA-04, RF-ACA-05, RF-ACA-11.

### 7.4 CU-04 Crear, progresar y completar reto simple
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado.
3. Flujo principal:
   1. El usuario crea reto con meta y fecha limite.
   2. Registra progreso periodicamente.
   3. Al alcanzar meta, marca completado.
   4. El sistema registra logro y publica actividad.
4. Flujo alternativo:
   1. A1 - Cierre manual antes de meta: permitir cerrar como cancelado.
   2. A2 - Ajuste de meta dentro de limites configurados.
5. Flujo de excepcion:
   1. E1 - Fecha limite vencida: pasar a estado vencido.
   2. E2 - Progreso invalido (negativo o superior al maximo): rechazar operacion.
6. Postcondiciones: estado del reto consistente (activo, completado o vencido).
7. Requisitos relacionados: RF-RET-01, RF-RET-02, RF-SOC-01.

### 7.5 CU-05 Clonar reto publico
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado y reto origen visible/publico.
3. Flujo principal:
   1. El usuario abre un reto publico.
   2. Selecciona clonar.
   3. El sistema crea nuevo reto asociado al usuario.
   4. El sistema confirma clonacion.
4. Flujo alternativo:
   1. A1 - Clonar y personalizar fecha/meta en el mismo flujo.
5. Flujo de excepcion:
   1. E1 - Reto no visible por permisos: denegar acceso.
   2. E2 - Reto eliminado durante la clonacion: informar y refrescar listado.
6. Postcondiciones: nuevo reto disponible en perfil del usuario.
7. Requisitos relacionados: RF-RET-03, RF-RET-04.

### 7.6 CU-06 Gestionar rutina y sesion completada
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado.
3. Flujo principal:
   1. El usuario selecciona rutina sugerida o propia.
   2. Revisa y ajusta la seleccion de ejercicios de la sesion.
   3. Inicia sesion con calentamiento recomendado.
   4. Registra sesion como completada con duracion real y esfuerzo percibido.
   5. El sistema actualiza historial, adherencia y publica logro (si esta habilitado).
4. Flujo alternativo:
   1. A1 - Marcar sesion con duracion custom.
   2. A2 - Sustituir ejercicios por alternativas sin equipamiento.
   3. A3 - Pausar rutina y reactivarla posteriormente.
5. Flujo de excepcion:
   1. E1 - Sesion duplicada en mismo intervalo: solicitar confirmacion.
   2. E2 - Fatiga alta reportada: sugerir sesion de menor intensidad.
   3. E3 - Recurso multimedia no disponible: mostrar instrucciones textuales y continuar.
   4. E4 - Error de persistencia: reintento con control idempotente.
6. Postcondiciones: sesion registrada de forma trazable.
7. Requisitos relacionados: RF-BIE-03, RF-BIE-06, RF-BIE-07, RF-BIE-08, RF-BIE-09, RF-BIE-11, RF-BIE-12, RF-SOC-01.

### 7.7 CU-07 Visualizar feed e interactuar con like
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado.
3. Flujo principal:
   1. El sistema carga feed paginado.
   2. El usuario visualiza publicaciones permitidas.
   3. El usuario agrega o quita like.
4. Flujo alternativo:
   1. A1 - Filtro por tipo de logro.
   2. A2 - Refresco en tiempo real.
5. Flujo de excepcion:
   1. E1 - Publicacion no visible por cambio de permisos: ocultar item y actualizar feed.
   2. E2 - Error temporal de red: mantener accion en cola para reintento.
6. Postcondiciones: estado de interaccion consistente.
7. Requisitos relacionados: RF-SOC-02, RF-SOC-03.

### 7.8 CU-08 Crear y gestionar reto complejo por hitos
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado.
3. Disparador: el usuario selecciona "nuevo reto complejo".
4. Flujo principal:
   1. El usuario define objetivo general, fecha limite y tipo de medida.
   2. El usuario agrega hitos con orden, fechas y dependencias.
   3. El sistema valida consistencia de dependencias y cronograma.
   4. El usuario guarda el reto.
   5. El sistema inicia estado activo y calcula progreso global.
5. Flujo alternativo:
   1. A1 - Plantilla: el usuario crea reto desde plantilla publica.
   2. A2 - Reprogramacion: el usuario mueve fechas manteniendo dependencias.
   3. A3 - Pausa temporal: el usuario pausa reto por carga academica.
6. Flujo de excepcion:
   1. E1 - Dependencia ciclica: bloquear guardado y mostrar conflicto.
   2. E2 - Hito con fecha fuera de rango: solicitar correccion.
   3. E3 - Intento de completar hito bloqueado: denegar y mostrar requisito pendiente.
7. Postcondiciones: reto complejo persistido con estado y trazabilidad.
8. Requisitos relacionados: RF-RET-05, RF-RET-06, RF-RET-07, RF-RET-08.

### 7.9 CU-09 Gestionar amistades y permisos de privacidad
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado.
3. Flujo principal:
   1. El usuario envia solicitud de amistad.
   2. El receptor acepta o rechaza.
   3. El sistema actualiza estado de relacion.
   4. El sistema recalcula visibilidad para recursos solo_amigos.
4. Flujo alternativo:
   1. A1 - Bloquear usuario: se revoca visibilidad y futuras solicitudes.
   2. A2 - Eliminar amistad: recursos solo_amigos dejan de ser visibles.
5. Flujo de excepcion:
   1. E1 - Solicitud duplicada: informar estado existente.
   2. E2 - Usuario no encontrado o inactivo: cancelar operacion.
6. Postcondiciones: permisos actualizados en tiempo casi real.
7. Requisitos relacionados: RF-AUTH-03, RF-ACA-05, RF-SOC-02.

### 7.10 CU-10 Configurar notificaciones adaptativas
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado con permisos de notificacion otorgados.
3. Flujo principal:
   1. El usuario define categorias de aviso activas.
   2. Define franja de silencio y limite diario.
   3. El sistema prioriza avisos segun urgencia y preferencias.
4. Flujo alternativo:
   1. A1 - Modo examenes: aumentar frecuencia temporalmente.
   2. A2 - Modo descanso: reducir avisos a minimos esenciales.
5. Flujo de excepcion:
   1. E1 - Permiso de sistema denegado: mostrar guia para activacion manual.
   2. E2 - Proveedor push no disponible: almacenar cola y reenviar.
6. Postcondiciones: politicas de notificacion personalizadas y auditables.
7. Requisitos relacionados: RF-NOT-01, RF-NOT-02, RF-NOT-03, RF-NOT-04, RF-NOT-05.

### 7.11 CU-11 Gestionar carga semanal y prevenir sobrecarga
1. Actor principal: Estudiante.
2. Precondiciones: usuario con al menos 1 semana de datos.
3. Flujo principal:
   1. El sistema calcula horas de estudio, retos activos y rutinas planificadas.
   2. Detecta patrones de sobrecarga (picos de tareas y baja finalizacion).
   3. Sugiere ajustes (dividir bloques, mover hitos, reducir frecuencia).
   4. El usuario acepta o descarta sugerencias.
4. Flujo alternativo:
   1. A1 - Aplicacion automatica de ajustes sugeridos.
   2. A2 - Guardar escenario alternativo sin reemplazar el plan vigente.
5. Flujo de excepcion:
   1. E1 - Datos insuficientes: mostrar recomendaciones basicas no personalizadas.
   2. E2 - Conflicto con eventos fijos: marcar sugerencia como no aplicable.
6. Postcondiciones: plan semanal optimizado o confirmacion de plan original.
7. Requisitos relacionados: RF-ANA-01, RF-ANA-02, RF-ANA-03.

### 7.12 CU-12 Sincronizacion offline y resolucion de conflictos
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado y cambios locales pendientes.
3. Flujo principal:
   1. El usuario realiza cambios sin conectividad.
   2. El sistema guarda operaciones en cola local.
   3. Al recuperar red, el sistema sincroniza en orden.
   4. Si hay conflicto, muestra comparacion y opciones de resolucion.
4. Flujo alternativo:
   1. A1 - Resolucion automatica por ultima escritura para campos no criticos.
   2. A2 - Resolucion manual para datos sensibles (visibilidad, fecha limite).
5. Flujo de excepcion:
   1. E1 - Version remota eliminada: permitir recrear como nuevo recurso.
   2. E2 - Reintentos excedidos: marcar operacion fallida y notificar.
6. Postcondiciones: estado local y remoto consistentes.
7. Requisitos relacionados: RNF-CON-02, RF-ACA-01, RF-RET-07.

### 7.13 CU-13 Gestionar asignaturas y evaluaciones
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado.
3. Flujo principal:
   1. El usuario crea asignaturas del periodo academico.
   2. El usuario registra evaluaciones para cada asignatura.
   3. El sistema vincula evaluaciones al calendario.
   4. El usuario consulta vista por asignatura y vista semanal.
4. Flujo alternativo:
   1. A1 - Archivar asignatura finalizada sin eliminar historial.
   2. A2 - Reprogramar fecha de evaluacion por cambio docente.
5. Flujo de excepcion:
   1. E1 - Fecha de evaluacion invalida: solicitar correccion.
   2. E2 - Nombre duplicado en el mismo periodo: sugerir fusion o renombrado.
6. Postcondiciones: asignaturas y evaluaciones persistidas con trazabilidad.
7. Requisitos relacionados: RF-ACA-06, RF-ACA-07, RF-ACA-08.

### 7.14 CU-14 Registrar calificaciones y seguimiento academico
1. Actor principal: Estudiante.
2. Precondiciones: existe al menos una evaluacion registrada.
3. Flujo principal:
   1. El usuario registra la calificacion obtenida en una evaluacion.
   2. El sistema actualiza el progreso de la asignatura.
   3. El sistema muestra estado academico y recomendaciones basicas.
4. Flujo alternativo:
   1. A1 - Correccion de calificacion por error de carga.
   2. A2 - Registro parcial de nota cuando solo hay parte de evaluaciones publicadas.
5. Flujo de excepcion:
   1. E1 - Valor fuera de rango permitido: rechazar y mostrar rango valido.
   2. E2 - Evaluacion no encontrada o archivada: denegar registro.
6. Postcondiciones: historico de calificaciones actualizado.
7. Requisitos relacionados: RF-ACA-09, RF-ACA-10.

### 7.15 CU-15 Editar perfil extendido del estudiante
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado.
3. Flujo principal:
   1. El usuario abre su perfil.
   2. Actualiza biografia, avatar y objetivos personales.
   3. Configura visibilidad del perfil.
   4. El sistema guarda cambios y aplica privacidad.
4. Flujo alternativo:
   1. A1 - Restablecer avatar y biografia a estado vacio.
   2. A2 - Cambiar solo visibilidad sin editar contenido.
5. Flujo de excepcion:
   1. E1 - Biografia supera limite maximo: truncar o solicitar reduccion.
   2. E2 - Formato de imagen invalido: rechazar y mostrar formatos permitidos.
6. Postcondiciones: perfil actualizado segun configuracion elegida.
7. Requisitos relacionados: RF-AUTH-04, RF-AUTH-05.

### 7.16 CU-16 Configurar perfil fisico y objetivo de entrenamiento
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado.
3. Flujo principal:
   1. El usuario registra peso, altura y nivel de condicion fisica.
   2. Define objetivo principal (salud general, fuerza, resistencia, movilidad).
   3. Define dias disponibles y tiempo por sesion.
   4. El sistema valida datos y guarda perfil de bienestar.
4. Flujo alternativo:
   1. A1 - Actualizacion mensual de datos fisicos.
   2. A2 - Cambio de objetivo por periodo academico.
5. Flujo de excepcion:
   1. E1 - Datos fuera de rango permitido: solicitar correccion.
   2. E2 - Faltan datos obligatorios para recomendar plan: bloquear recomendacion automatica.
6. Postcondiciones: perfil de bienestar listo para recomendaciones.
7. Requisitos relacionados: RF-BIE-01, RF-BIE-02.

### 7.17 CU-17 Generar plan semanal de entrenamiento recomendado
1. Actor principal: Estudiante.
2. Precondiciones: perfil de bienestar configurado.
3. Flujo principal:
   1. El sistema calcula sesiones recomendadas para la semana.
   2. Propone duracion, intensidad y seleccion base de ejercicios por sesion.
   3. El usuario confirma o ajusta la seleccion de ejercicios dentro de limites.
   4. El sistema guarda plan semanal y programa recordatorios.
4. Flujo alternativo:
   1. A1 - Cambiar dias de entrenamiento por carga academica puntual.
   2. A2 - Seleccionar modalidad casa/gimnasio segun equipamiento.
5. Flujo de excepcion:
   1. E1 - Disponibilidad insuficiente: proponer plan minimo viable.
   2. E2 - Conflicto con calendario academico: sugerir redistribucion.
   3. E3 - No hay ejercicios compatibles con filtros aplicados: proponer seleccion minima por defecto.
6. Postcondiciones: plan semanal de entrenamiento activo.
7. Requisitos relacionados: RF-BIE-04, RF-BIE-05, RF-BIE-10, RF-BIE-11.

### 7.18 CU-18 Recalcular plan por adherencia y fatiga
1. Actor principal: Sistema (con aprobacion del estudiante).
2. Precondiciones: existe historial minimo de sesiones recientes.
3. Flujo principal:
   1. El sistema evalua adherencia y esfuerzo percibido.
   2. Detecta sobrecarga o infraestimulo.
   3. Propone ajuste de frecuencia, intensidad o duracion.
   4. El usuario acepta o rechaza cambios.
4. Flujo alternativo:
   1. A1 - Ajuste automatico suave si el usuario lo habilito previamente.
5. Flujo de excepcion:
   1. E1 - Datos insuficientes: mantener plan y solicitar mas registros.
   2. E2 - Ajuste excede limites de seguridad: aplicar configuracion conservadora.
6. Postcondiciones: plan actualizado o mantenido con decision registrada.
7. Requisitos relacionados: RF-BIE-06, RF-BIE-07, RF-BIE-10.

### 7.19 CU-19 Buscar y seleccionar ejercicios para una rutina
1. Actor principal: Estudiante.
2. Precondiciones: usuario autenticado y catalogo de ejercicios disponible.
3. Flujo principal:
   1. El usuario abre el explorador de ejercicios.
   2. Aplica filtros (objetivo, grupo muscular, equipamiento, nivel).
   3. El sistema muestra resultados con nombre, instrucciones y vista previa multimedia.
   4. El usuario selecciona uno o varios ejercicios y los agrega a la rutina.
   5. El sistema guarda la composicion de rutina y su orden.
4. Flujo alternativo:
   1. A1 - Reemplazar ejercicio manteniendo objetivo de la sesion.
   2. A2 - Duplicar seleccion de ejercicios desde una rutina previa.
5. Flujo de excepcion:
   1. E1 - Sin resultados para los filtros: sugerir ajuste de filtros o seleccion base.
   2. E2 - Archivo multimedia no disponible: mantener ejercicio con ficha textual.
6. Postcondiciones: rutina persistida con ejercicios seleccionados.
7. Requisitos relacionados: RF-BIE-11, RF-BIE-12, RI-05, RI-09.

## 8. Requisitos No Funcionales
### 8.1 Plataforma y arquitectura
1. RNF-PLA-01: Ejecutar en Android, iOS y Web con una base Flutter.
2. RNF-PLA-02: UI responsive/adaptive para movil y escritorio.
3. RNF-PLA-03: Navegacion coherente con rutas y deep links.

### 8.2 Seguridad y privacidad
1. RNF-SEG-01: Control de acceso backend por autenticacion y visibilidad.
2. RNF-SEG-02: RLS para evitar exposicion de contenido privado.
3. RNF-SEG-03: Claves privilegiadas nunca expuestas en cliente.
4. RNF-SEG-04: Auditoria basica para cambios sensibles.

### 8.3 Rendimiento
1. RNF-REN-01: Carga inicial <= 3 s en movil gama media con red estable.
2. RNF-REN-02: Interacciones locales frecuentes <= 300 ms.
3. RNF-REN-03: Feed paginado para controlar memoria y latencia.

### 8.4 Confiabilidad
1. RNF-CON-01: Disponibilidad backend mensual objetivo >= 99.5% en MVP.
2. RNF-CON-02: Reintentos e idempotencia para escrituras criticas.

### 8.5 Accesibilidad y UX
1. RNF-UX-01: Texto escalable, contraste suficiente y labels en elementos clave.
2. RNF-UX-02: Gamificacion motivadora sin dinamicas punitivas excesivas.

### 8.6 Mantenibilidad y calidad
1. RNF-CAL-01: Arquitectura modular por features.
2. RNF-CAL-02: Cobertura de pruebas minima objetivo para logica critica >= 70%.
3. RNF-CAL-03: Lint y formateo obligatorio en pipeline de calidad.

### 8.7 Observabilidad y operacion
1. RNF-OBS-01: Registrar metricas de negocio (adherencia, abandono, reprogramaciones).
2. RNF-OBS-02: Trazar transiciones de estado en retos y sincronizacion offline.
3. RNF-OBS-03: Alertar fallos repetidos de push o errores de permisos.

### 8.8 Salvaguardas de bienestar
1. RNF-SAF-01: Evitar lenguaje punitivo en mensajes de incumplimiento.
2. RNF-SAF-02: Incluir mecanismos para reducir presion social (ocultar rachas, desactivar autopost).
3. RNF-SAF-03: Mantener separacion explicita entre recomendaciones de bienestar y consejo clinico.

## 9. Reglas de Negocio
1. RB-01: El propietario siempre puede leer y editar sus recursos.
2. RB-02: Recurso publico puede ser leido por usuarios autenticados.
3. RB-03: Recurso solo_amigos requiere amistad aceptada.
4. RB-04: Un like por usuario y publicacion.
5. RB-05: Un reto vencido no puede marcarse completado sin reapertura valida.
6. RB-06: Cambios de visibilidad deben aplicarse de forma inmediata en feed.
7. RB-07: Estados de reto permitidos: borrador -> activo -> pausado -> completado | vencido | cancelado.
8. RB-08: En retos complejos, un hito dependiente solo puede completarse si su prerequisito esta completado.
9. RB-09: El progreso global de un reto complejo se calcula automaticamente segun el orden actual de hitos.
10. RB-10: Las recomendaciones de carga no deben superar limites definidos por el usuario (horas maximas semanales).
11. RB-11: Las publicaciones automaticas de logros deben respetar preferencia de privacidad activa.
12. RB-12: Todo bloque de estudio debe estar vinculado a una asignatura existente y activa.
13. RB-13: Una evaluacion pertenece a una unica asignatura y no puede quedar huerfana.
14. RB-14: La calificacion debe respetar el rango configurado (por defecto 0 a 10).
15. RB-15: Archivar una asignatura no elimina su historial academico.
16. RB-16: La biografia de perfil tiene limite maximo configurable para evitar sobrecarga visual.
17. RB-17: El plan de entrenamiento semanal debe considerar dias disponibles y reservar al menos un dia de descanso.
18. RB-18: El ajuste de carga semanal debe ser progresivo y conservador para evitar sobrecarga.
19. RB-19: Si se detecta baja adherencia sostenida o fatiga alta, el sistema prioriza reduccion temporal de intensidad.
20. RB-20: Los datos fisicos del estudiante se consideran sensibles y su visibilidad por defecto es privada.

## 10. Requisitos de Datos y Trazabilidad

### 10.1 Entidades minimas
1. usuarios
2. amistades
3. perfil_bienestar_usuario
4. plan_entrenamiento_semanal
5. ejercicios
6. asignaturas
7. evaluaciones_asignatura
8. calificaciones_evaluacion
9. planes_estudio
10. bloques_estudio
11. apuntes
12. notas_rapidas
13. retos
14. rutinas
15. sesiones_rutina
16. publicaciones_muro
17. me_gusta_publicacion
18. preferencias_notificacion

### 10.2 Trazabilidad de eventos clave
1. Cambio de visibilidad.
2. Eliminacion de contenido.
3. Completar reto o rutina.
4. Error de acceso por permisos.
5. Alta o archivo de asignatura.
6. Registro o correccion de calificacion.
7. Actualizacion de perfil fisico.
8. Recalculo de plan de entrenamiento semanal.
9. Seleccion o reemplazo de ejercicios en una rutina.

## 11. Requisitos de Integracion
1. RI-01: Integracion con Supabase Auth para autenticacion.
2. RI-02: Integracion con Postgres + RLS para control de datos.
3. RI-03: Integracion con proveedor push (FCM/APNs/Web Push).
4. RI-04: Integracion con almacenamiento de archivos (Cloudflare R2).
5. RI-05: El catalogo de ejercicios (metadatos) debe residir en Supabase en una tabla interna `ejercicios`.
6. RI-06: La carga inicial del catalogo debe realizarse mediante proceso de seeding desde fuente externa validada.
7. RI-07: El flujo principal de consulta de ejercicios no debe depender de llamadas runtime a APIs externas.
8. RI-08: Las actualizaciones del catalogo deben ejecutarse en lotes controlados con registro de fuente, fecha y version.
9. RI-09: Los archivos multimedia de ejercicios deben almacenarse en bucket R2 de Cloudflare; en Supabase solo se guardan referencias y metadatos.
10. RI-10: El acceso a multimedia en R2 debe usar URL firmada o mecanismo equivalente de acceso controlado.

## 12. Historias de Usuario (resumen operativo)
1. HU-01: Como estudiante quiero crear bloques en calendario para organizar mi semana.
2. HU-02: Como estudiante quiero gestionar apuntes con formato para estudiar mejor.
3. HU-03: Como estudiante quiero controlar visibilidad de mi contenido.
4. HU-04: Como estudiante quiero crear y ordenar mis asignaturas para estructurar el semestre.
5. HU-05: Como estudiante quiero registrar evaluaciones para no perder fechas importantes.
6. HU-06: Como estudiante quiero registrar notas de examenes para ver mi progreso real.
7. HU-07: Como estudiante quiero tener una biografia y objetivos en mi perfil para personalizar mi experiencia.
8. HU-10: Como estudiante quiero crear retos para mantener constancia.
9. HU-11: Como estudiante quiero clonar retos publicos para ahorrar tiempo.
10. HU-12: Como estudiante quiero dividir un objetivo grande en hitos para evitar abandono.
11. HU-20: Como estudiante quiero registrar rutinas para sostener habitos.
12. HU-21: Como estudiante quiero compartir logros para sentir acompanamiento.
13. HU-22: Como estudiante quiero registrar peso, altura y disponibilidad para recibir recomendaciones realistas.
14. HU-23: Como estudiante quiero que la app me recomiende cuantas sesiones hacer por semana segun mi carga academica.
15. HU-24: Como estudiante quiero que el plan se ajuste cuando no puedo cumplir o reporto fatiga.
16. HU-25: Como estudiante quiero buscar y seleccionar ejercicios para personalizar mis rutinas.
17. HU-30: Como usuario quiero recordatorios para no olvidar objetivos.
18. HU-31: Como usuario quiero configurar franjas de silencio para no sentir saturacion.
19. HU-32: Como usuario quiero recibir sugerencias de ajuste cuando mi carga semanal sea excesiva.

## 13. Criterios de Aceptacion Global del MVP
1. El usuario puede completar un flujo extremo a extremo: registro -> crear plan -> completar reto/rutina -> visualizar logro.
2. La visibilidad de recursos se respeta en lectura y escritura.
3. El feed muestra solo contenido autorizado.
4. Las notificaciones configuradas se pueden activar/desactivar correctamente.
5. El sistema mantiene rendimiento objetivo en escenarios base de uso.
6. El sistema permite gestionar y resolver conflictos de sincronizacion sin perdida de datos criticos.
7. El usuario puede pausar/reprogramar objetivos cuando detecta sobrecarga.
8. El usuario puede gestionar asignaturas, evaluaciones y calificaciones sin inconsistencias de datos.
9. El usuario puede editar su biografia y visibilidad de perfil de forma segura.
10. El usuario recibe recomendacion semanal de entrenamiento basada en su perfil fisico y disponibilidad.
11. El sistema ajusta la propuesta de entrenamiento cuando detecta baja adherencia o fatiga.
12. El catalogo de ejercicios puede consultarse en la app sin fallo aunque un proveedor externo este temporalmente caido.
13. El usuario puede buscar y seleccionar ejercicios con filtros y visualizar recursos multimedia desde R2.

## 14. Matriz de Trazabilidad (extracto)
1. Objetivo O1 (organizacion academica) -> RF-ACA-01/02/03/06/07/08/09/10/11 -> CU-02/CU-03/CU-13/CU-14.
2. Objetivo O2 (constancia por gamificacion) -> RF-RET-01/02/04 -> CU-04/CU-05.
3. Objetivo O3 (bienestar) -> RF-BIE-01/02/03/04/05/06/07/08/09/10/11/12 + RF-SAF-01/02/03 -> CU-06/CU-16/CU-17/CU-18/CU-19.
4. Objetivo O4 (comunidad y retencion) -> RF-SOC-01/02/03 -> CU-07/CU-09.
5. Objetivo O5 (privacidad) -> RF-ACA-04/05 + RF-AUTH-05 + RB-01/02/03 -> CU-02/CU-03/CU-09/CU-15.
6. Objetivo O6 (retos avanzados) -> RF-RET-05/06/07/08 -> CU-08.
7. Objetivo O7 (autorregulacion) -> RF-ANA-01/02/03 + RF-NOT-04/05 + RF-BIE-07 -> CU-10/CU-11/CU-18.
8. Objetivo O8 (personalizacion de perfil) -> RF-AUTH-04/05 + RF-BIE-01/02 -> CU-15/CU-16.

## 15. Riesgos y Mitigaciones
1. Riesgo: alcance excesivo para primera entrega.
   - Mitigacion: priorizacion MUST/SHOULD/COULD y congelar backlog MVP.
2. Riesgo: complejidad de permisos y privacidad.
   - Mitigacion: matriz de acceso formal, pruebas de autorizacion y RLS.
3. Riesgo: retencion inicial baja.
   - Mitigacion: onboarding corto, plantillas base y recordatorios configurables.
4. Riesgo: inconsistencia UX movil/web.
   - Mitigacion: guia de componentes compartidos y pruebas cross-platform.
5. Riesgo: desactualizacion del catalogo de ejercicios al usar base propia.
   - Mitigacion: seeding inicial + refresco batch periodico con trazabilidad de version.
6. Riesgo: incumplimiento de licencias del dataset externo.
   - Mitigacion: registrar fuente/licencia por importacion y documentar atribucion requerida.

## 16. Plan por Fases
1. Fase 1 (MVP, 3-5 meses): auth y perfil extendido, asignaturas, planes, bloques, apuntes/notas rapidas, evaluaciones y calificaciones base, perfil fisico de bienestar, recomendacion semanal basica de entrenos, seeding de catalogo `ejercicios` en Supabase, carga de multimedia de ejercicios en bucket R2, rutinas y registro de sesiones, retos simples, feed y likes, notificaciones basicas.
2. Fase 2 (crecimiento): retos complejos, comentarios, insignias avanzadas, integraciones ampliadas.

## 17. Restricciones, Supuestos y Dependencias

### 17.1 Restricciones
1. Tiempo de implementacion acotado por calendario academico del TFG.
2. Recursos de infraestructura limitados a configuracion MVP.

### 17.2 Supuestos
1. El usuario dispone de conectividad periodica para sincronizar.
2. El proveedor backend gestionado mantiene SLA esperado.

### 17.3 Dependencias
1. Disponibilidad de servicios de autenticacion y notificaciones.
2. Definicion estable del modelo de datos en RFC de arquitectura.

## 18. Recomendacion de Stack
1. Frontend: Flutter (Android, iOS, Web).
2. Estado: Riverpod.
3. Backend MVP: Supabase (Auth + Postgres + RLS + Realtime + Edge Functions).
4. Archivos: Cloudflare R2 con acceso firmado.
5. Push: proveedor dedicado invocado desde backend.

Decision sugerida para MVP: Supabase + Realtime + Cloudflare R2 por equilibrio entre velocidad de entrega, seguridad y escalabilidad gradual.

## 19. Handoff al Arquitecto
Con este SRS aprobado, el siguiente paso es producir:
1. Esquema fisico SQL final (tablas, indices y politicas RLS).
2. Contratos de servicios (repositorios, RPC y Edge Functions).
3. Mapa de pantallas y navegacion.
4. Backlog tecnico priorizado por sprint con criterios de prueba.
