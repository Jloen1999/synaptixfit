# Datos demo de SynaptixFit

> **Qué es:** un seed reproducible que crea seis cuentas demo con cinco semanas de historia realista (estudio, entrenamiento, retos, insignias, red social) para probar todas las funciones y grabar el vídeo del TFG.
> **Dónde:** `tools/demo/`. Todo se crea por la **API pública**, así corren las reglas y eventos reales del backend (XP, insignias, retos, estado cognitivo, ACWR, avisos, publicaciones automáticas).

## Cuentas demo

Todas usan el dominio reservado `@demo.synaptixfit.test` y **la misma contraseña**, guardada solo en `%USERPROFILE%\.config\synaptixfit\demo.env` (`DEMO_PASSWORD=…`). Nunca se escribe en el repositorio ni en los logs.

| Cuenta | Persona | Qué muestra | Qué probar con ella |
|---|---|---|---|
| `lucia.fernandez@demo.synaptixfit.test` | Biotecnología (UEx, catálogo), 2.º. Gimnasio 4 días (torso-pierna) | Racha de 36 días, nivel 14, 11 insignias (incl. «Imparable» y «Coleccionista»), ACWR **óptimo** (~1,07), 2 retos completados, planes de estudio de 6 semanas, apuntes largos de Bioquímica, resumen IA | Inicio completo, Progreso (racha, insignias, analítica), Planificador con clases/estudio/gimnasio y un solape, reto de Histología con hito ligado a un bloque |
| `pablo.ruiz@demo.synaptixfit.test` | Ing. Informática (UEx, catálogo), 2.º. Running + calistenia | **Modo exámenes**, parciales esta semana, carga cognitiva **crítica** (~98 %), ACWR **sobreentrenamiento** (~2,1), check-in de hoy con fatiga alta, avisos de fatiga, una entrega vencida sin hacer, repasos SM-2 atrasados | Regulación cruzada (banner «Carga física elevada», estudio limitado a 45 min), recomendaciones de entrenamiento, avisos `FATIGUE_ALERT`, reto «San Silvestre» (19/24 sesiones) |
| `marta.gomez@demo.synaptixfit.test` | Derecho (Granada, texto libre), 4.º. Principiante en fuerza | Mucho repaso SM-2 (materiales «Dominado»), flashcards (generadas con IA), 2 bancos de preguntas manuales y 4 tests hechos, insignia «Planificador Maestro», solicitud de amistad pendiente de Andrés | Repaso pendiente («La letra de cambio») y material nuevo sin evaluar, flashcards y tests (Académico → material → Practicar), aceptar/rechazar la solicitud, apuntes compartidos |
| `andres.molina@demo.synaptixfit.test` | CAFyD (Granada, texto libre), 3.º. Fuerza 6 días | Rutina **generada con IA**, 28 sesiones, semana de descarga → ACWR **bajo** (~0,4, desentrenamiento relativo), reto de 24 sesiones completado, historial de peso, una insignia oculta | Analítica de volumen y RPE, historial de sesiones, comunidad de rutinas (rutina pública para clonar), insignias ocultas |
| `sara.lopez@demo.synaptixfit.test` | Doble Grado ADE + Informática (UEx, catálogo), 2.º. Full body 3 días | Muy social: 7 publicaciones, «Alma social» y «Popular», muchos me gusta y comentarios; ACWR en **riesgo** (~1,37) | Muro social (publicar, comentar, me gusta), notificaciones sociales; **hacer un entrenamiento completa su reto (17/18) en directo** |
| `admin@demo.synaptixfit.test` | Administración | Rol `admin` (asignado por SQL, como indica `docs/04-guides/onboarding.md`) | Panel de administración: KPIs y tendencia, usuarios (filtrar `demo`), contenido, ejercicios, auditoría (incluye una exportación RGPD de Lucía) |

Lucía, Pablo, Sara y Marta son amigos entre sí; Andrés es amigo de Sara, Lucía y Pablo y tiene pendiente la solicitud a Marta. Los cinco perfiles completan el onboarding (bienestar + académico + asignaturas). Al final, Marta queda con enfoque **solo estudios** y Andrés con **solo deporte** (ADR 0014): ven solo su ámbito; Lucía, Pablo y Sara usan la app completa.

## Requisitos

- Python 3.10+ (solo librería estándar).
- `DEMO_PASSWORD` en el entorno, o el fichero `%USERPROFILE%\.config\synaptixfit\demo.env` (el script lo lee si falta la variable).
- Para el histórico, acceso a la base de datos: el contenedor local `synaptixfit-db-1` o `ssh infra-ovh` (OpenSSH de Windows con la clave del propietario; las credenciales de la BD se leen **en el servidor**, de `/root/synaptixfit/db-app.env`).

## Ejecutar

Siempre desde la raíz del repositorio. Con `bash` usa `PYTHONIOENCODING=utf-8` si la consola no muestra bien los acentos.

**Local** (backend en `http://localhost:8080` y `docker compose up -d db`):

```powershell
python tools/demo/seed_demo.py --db local
```

**Producción:**

```powershell
python tools/demo/seed_demo.py --base-url https://synaptixfit.jloenit.dev --db prod
```

Opciones útiles:

| Opción | Para qué |
|---|---|
| `--only lucia` (repetible, también con el email) | Crear solo esa persona; sus amistades con las que ya existan se rehacen |
| `--reset` | Borrar y volver a crear las personas que ya existan (sin él, se saltan: el seed es idempotente) |
| `--no-ai` / `--ai-budget N` | La IA cuesta dinero: por defecto como mucho **3 llamadas** (rutina de Andrés, flashcards de Marta, resumen de Lucía). Si la IA falla, se usa la rutina manual |
| `--no-history` | Sin acceso a la BD: todo queda con fecha de hoy (sin rachas ni gráficas de semanas) |

Tarda unos 2 minutos en local y unos 5 en producción (≈ 2.800 llamadas a través de Cloudflare y 38 ejecuciones de SQL por ssh). **No lo lances cerca de medianoche (hora de Madrid):** si el día cambia a mitad, el script se detiene; vuelve a ejecutarlo con `--reset`. Al final imprime un resumen por persona y guarda un registro en `tools/demo/runs/` (ignorado por git).

## Borrar (purga)

Cada cuenta se borra con el endpoint RGPD (`DELETE /api/v1/me` con contraseña y confirmación), que elimina sus filas de todos los módulos. Si la cuenta admin demo fuera el último administrador, primero se le quita el rol con `set_role.sql`.

```powershell
python tools/demo/purge_demo.py --db local
python tools/demo/purge_demo.py --base-url https://synaptixfit.jloenit.dev --db prod --yes
```

Para empezar de cero: purga y vuelve a sembrar (o `seed_demo.py --reset`). Cada baja deja su traza anónima en la auditoría del panel de administración.

## Cómo se construye el histórico

La API fecha casi todo con «ahora» y no deja crear bloques en el pasado, así que el seed **simula los días uno a uno**:

1. **Alta (hace 38 días):** registro, perfiles, asignaturas del catálogo, rutina, entregas y retos con fechas reales.
2. **Calendario:** cada bloque histórico (clases, estudio, gimnasio) se crea 12 semanas después de su fecha y `move_blocks.sql` lo devuelve a ella (semanas enteras: no cambia el día de la semana). Se hace antes de completarlos, para que la carga semanal y la cognitiva caigan en la semana correcta.
3. **Un día por ronda (hace 35 días → ayer):** check-in, repasos SM-2, tests, bloques completados, Pomodoros, sesión de entrenamiento con series y RPE, entregas, hitos, publicaciones, me gusta y comentarios. Todo por la API, con la hora real. Después, `shift_history.sql`:
   - lleva lo creado en la ronda (marca de tiempo ≥ inicio de la ronda) a la fecha simulada, a las 19:00;
   - «enrolla» la actividad que alimenta la racha y el ACWR (sesiones, sus series y carga física, check-ins y Pomodoros): retrocede un día cada ronda, así en cada ronda el backend ve los días anteriores justo antes de hoy y concede las insignias de racha o detecta el sobreentrenamiento el día que toca.
4. **Hoy:** bloques de hoy y de las dos próximas semanas (más los de examen), las acciones de hoy y los retos activos con hitos ligados a bloques futuros.
5. **Recalcular con el backend** (no por SQL): sincronizar la carga académica de cada semana, leer regulación cruzada, racha y estado cognitivo, evaluar insignias. Después, preferencias de avisos reales, avisos antiguos leídos e insignias marcadas como vistas.
6. **Admin:** rol por SQL (`set_role.sql`) y unas lecturas del panel.

El SQL **solo cambia fechas** de filas de usuarios `@demo.synaptixfit.test` de la ejecución (ninguna regla de negocio). Excepción documentada: la clave de los avisos de fatiga lleva el día (`fatigue:<motivo>:<día>`) y se cambia al día simulado para que no se dedupliquen entre rondas. No se tocan las fechas que elige el usuario (fechas límite, inicio y fin de retos, horario de los bloques, semanas de los planes) ni los tokens.

| Fichero | Qué hace |
|---|---|
| `seed_demo.py` | Orquesta todo |
| `personas.py` | Datos de las personas: perfiles, asignaturas, apuntes con contenido real, rutinas, plazos, retos, publicaciones y hábitos diarios (deterministas) |
| `demo_lib.py` | Cliente de la API (con `User-Agent` propio: Cloudflare bloquea el de Python, error 1010), contraseña, zona horaria y ejecución de SQL local o por ssh |
| `shift_history.sql`, `move_blocks.sql`, `set_role.sql` | SQL de fechas y de rol (variables con `\set`; los ejecuta el seed) |
| `purge_demo.py` | Borrado RGPD de las cuentas demo |

## Comportamientos que conviene conocer

- **Catálogo:** solo hay 7 universidades. Lucía, Pablo y Sara usan grados y asignaturas del catálogo (UEx); Derecho y CAFyD no existen, así que Marta y Andrés tienen el grado en texto libre y asignaturas manuales (Lucía tiene además una manual).
- **Avisos de sobreentrenamiento en la semana 2:** el ACWR necesita 4 semanas de historia; con una sola semana de base, la segunda semana de entrenamiento sale alta y el backend avisa. Es el comportamiento real con usuarios nuevos.
- **Hoy depende de la hora del seed:** los bloques de hoy anteriores a la hora de ejecución quedan completados y los posteriores, pendientes; si se siembra por la mañana, «Tu día» tendrá menos actividad.
- **Sin archivos:** no se suben PDFs a R2 (guías docentes, archivos de asignatura). Se pueden probar en directo.
- Con el paso de los días los datos «envejecen» (la racha se pierde si nadie entra). Para el vídeo, siembra el mismo día o el anterior.

## Guion de pruebas

- [ ] **Inicio (Lucía):** saludo con racha 36 y nivel 14, «Tu equilibrio» (carga cognitiva, atención, energía, ACWR óptimo), «Tu día», bloques de hoy, retos activos, aviso de entregas próximas.
- [ ] **Regulación cruzada (Pablo):** banner «Carga física elevada», ACWR ~2,1 en «Sobrecarga», carga cognitiva crítica, estudio recomendado de 45 min; Rutinas → check-in con fatiga 84/100 y sugerencias de ajuste.
- [ ] **Planificador (Lucía o Pablo):** semana actual con clases fijas, estudio, gimnasio, repasos SM-2 y examen; semanas anteriores con bloques completados; solape detectado; «Guardar plan».
- [ ] **Entregas y exámenes (Pablo):** práctica 2 en 2 días, parcial en 3, entrega de subnetting vencida.
- [ ] **Académico (Marta):** asignaturas, apuntes (`Control de constitucionalidad`), repaso pendiente con vista previa SM-2, flashcards y test de práctica; apuntes compartidos de amigos.
- [ ] **IA:** resumen de «Glucólisis y su regulación» (Lucía), flashcards (Marta), rutina de Andrés (generada con IA).
- [ ] **Rutinas (Andrés):** rutina de 6 días, historial de sesiones con series y RPE, comunidad (rutinas públicas de Lucía, Sara y Andrés para clonar).
- [ ] **Retos:** completados (Lucía, Andrés), activos con hitos ligados a entregas/bloques (Pablo, Marta, Sara), de fitness por sesiones; comunidad de retos.
- [ ] **En directo con Sara:** completar un entrenamiento → reto «Tres entrenos por semana» 18/18, publicación automática e insignia «Primer reto».
- [ ] **Progreso:** racha y hitos, insignias (Andrés tiene una oculta), analítica semanal (sesiones, minutos, RPE, volumen), carga física de 28 días, historial de peso (Andrés).
- [ ] **Social (Sara):** muro con publicaciones manuales y automáticas, me gusta, comentarios, amigos y solicitudes (Marta).
- [ ] **Notificaciones:** sociales (Sara), fatiga (Pablo), hitos (Lucía); preferencias por persona (Pablo en modo exámenes).
- [ ] **Admin:** KPIs, tendencia, usuarios (buscar «demo»), detalle de un usuario, auditoría, ejercicios, bloqueo de plataforma (no activarlo en producción durante la grabación).
