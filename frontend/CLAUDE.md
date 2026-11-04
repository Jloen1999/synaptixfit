# Frontend (Flutter + BLoC)

Perfil completo: `../docs/01-architecture/profiles/frontend-flutter-bloc.md`. Léelo antes de crear carpetas nuevas.
Cada capa de `lib/` tiene su propio `CLAUDE.md`.

## Mapa rápido

- `lib/domain/` → modelos (`@freezed`), `AppError`, `Result`, contratos de repositorio y casos de uso.
- `lib/data/` → data sources remotas (`remote_data_source/<modulo>/`, DTOs en `dto/`) y locales (`local_data_source/`), repositorios (con `guard()`) y traducción de errores.
- `lib/presentation/` → pantallas (`screens/<zona>/<pantalla>/{bloc,page}/`), widgets, tema y textos.
- `lib/app/di/app_di.dart` → raíz de composición: `data` → `domain` → `presentation`.
- `lib/routes.dart` → go_router con 5 pestañas (`StatefulShellRoute`): barra inferior en móvil y riel lateral en pantallas anchas.

## Acciones correlacionadas (no son funciones aisladas)

- **Datos al día entre pantallas:** `DataChangeInterceptor` (Dio) emite qué `DataTopic` toca cada escritura correcta; el bloc de cada pestaña inyecta `WatchDataChangesUseCaseContract`, se suscribe en `started` con `DataChangeRefreshMixin` (temas que muestra → su evento `refreshed`) y se refresca solo; la suscripción se cancela al cerrarse el bloc. Si añades un prefijo de API nuevo, añádelo al mapa del interceptor (y a su test).
- **Logros:** nivel e insignias se celebran solo en `AchievementsHost` (armazón de pestañas). No muestres diálogos de insignias en pantallas sueltas. Las insignias las otorga el servidor: el cliente solo lee las no celebradas y las marca como vistas (`GetUnnotifiedBadgesUseCase`, `MarkBadgesNotifiedUseCase`); nunca llama a `/badges/evaluate`.
- **Recordatorios locales del móvil:** `RemindersHost` (montado en `AchievementsHost`) llama a `SyncRemindersUseCase` al entrar en el armazón, con cada cambio de planificador/estudio/entrenamiento/preferencias/enfoque y al activar el interruptor «Recordatorios · En este móvil» (ajustes de notificaciones); al cerrar sesión los borra. Qué se programa lo decide el servidor (`GET /notifications/reminder-plan`); el cliente solo pone textos e ids (`ReminderComposer`) y programa con `ReminderSchedulerRepositoryContract`. No repliques preferencias, silencio ni límite en el cliente. En web no hace nada. Ver ADR 0013. Cada aviso lleva `payload` «tipo|referencia» (`Reminder.payload`, `OpenedReminder.fromPayload`): al tocarlo, `RemindersHost` abre lo concreto (el bloque en el calendario, la sesión abierta, el reto); los avisos de versiones anteriores (solo el tipo) abren su pantalla.
- **Pomodoro de toda la app:** `PomodoroBloc` es una sola instancia (`registerLazySingleton`); la pantalla lo usa con `BlocProvider.value` y salir no lo para. `FocusTimerHost` (en `AchievementsHost`) recupera la fase guardada en el teléfono al entrar (la cuenta sale de la sesión, sin red: si no se sabe de quién es, se conserva) (si terminó con la app cerrada, la registra) y la olvida al cerrar sesión; `FocusTimerBar` la muestra sobre la navegación, y en Android hay una notificación fija con la cuenta atrás.
- **Sesión de entreno: pausas y cronómetro por serie (ADR 0030):** el tiempo real es el **activo** (`TrainingSession.activeSecondsAt`: inicio → ahora − pausas), igual que lo acota el servidor al terminar. Pausar la serie pausa la sesión (`POST /training/sessions/{id}/pause` y `/resume`, idempotentes; sin conexión la pausa vale igual en el cliente). El cronómetro de la serie es opcional: «Marcar» siempre está a mano y la serie se guarda con `activeSeconds` solo si se usó. `OpenSessionBar` (sobre la navegación, como el Pomodoro) muestra la sesión abierta no abandonada y vuelve a ella; salir de la sesión a mitad pregunta «Pausar y salir / Terminar ahora / Seguir».
- **Calentamiento, «Usar hoy» y guía del ejercicio (ADR 0031):** las series de calentamiento van en `TrainingSession.warmupSets` (numeración propia, `SetRecord.warmup`); `sets` son solo las de trabajo. «Cambiar solo hoy» (`LiveSessionEvent.exerciseSwapped`) cambia el ejercicio del hueco en la sesión y las series se mandan con `exerciseId`; la rutina no cambia. El cronómetro de la serie y esos cambios se guardan en el teléfono (`LiveSessionDraft`) y sobreviven a cerrar la app. «Las claves», «Errores comunes» y «Tu nota» los pinta `ExerciseGuideSection` (ficha y «Cómo se hace»); sin consejos no se enseña la sección.
- **Plan por fases, plantillas y evolución (ADR 0032):** la semana actual, el avance y el siguiente paso de una rutina los da el servidor (`Routine.currentWeek`, `progressPercent`, `nextStep`) y la hoja «Tu plan, semana a semana» solo los pinta. Las plantillas (`RoutineTemplatesPage`, `/training/templates`) se filtran en el cliente, pero se crean con `POST /training/templates/{id}/use`. «Tu evolución» (`ExerciseProgressSection`) pinta los puntos de `GET /training/exercises/{id}/progress`. Una tarea de reto puede vincularse a un día de la rutina en curso (`ChallengeLinkType.routineDay`); se completa sola al entrenarlo.
- **Botones en los avisos:** los bloques llevan «Empezar» (abre la app; en estudio, el Pomodoro del bloque) y «Posponer 10 min», que se resuelve sin abrir la app (`reminderBackgroundTap`, necesita el `ActionBroadcastReceiver` del manifiesto). Solo en Android. Los avisos de entrega abren esa entrega (`PlannerPaths.deadline`).
- **Reglas de XP y retos las decide el servidor:** el Pomodoro avisa según `xpStatus` y los retos usan `tracksTrainingSessions`; no repliques umbrales ni condiciones en el cliente.
- **Navegar a otra pestaña** con `context.go`; a pantallas completas con `context.push`. No uses `go` hacia una ruta de pantalla completa: destruye las pestañas. Tampoco apiles con `push`, desde una pantalla completa (sesión en vivo, planificador, muro…), una ruta que vive **dentro** de una pestaña (`/training/routines/:id`, `/training/exercises/:id`…): go_router duplica el armazón y queda una pantalla en negro. Usa `go` (cambia de pestaña) o una hoja (`showExerciseHowToSheet`).

## Puntos de extensión por módulo

Para que cada módulo crezca sin tocar ficheros compartidos, cada uno tiene su propio archivo en:

| Qué | Dónde |
|---|---|
| Registro de data sources y repositorios | `lib/data/di/<modulo>_data_di.dart` |
| Registro de casos de uso | `lib/domain/di/<modulo>_domain_di.dart` |
| Registro de blocs | `lib/presentation/di/<modulo>_presentation_di.dart` |
| Rutas | `lib/presentation/screens/<modulo>/<modulo>_routes.dart` |
| Textos | `lib/presentation/l10n/parts/app_es_<modulo>.arb` (plantilla) y su traducción en `app_en_`, `app_fr_` y `app_pt_<modulo>.arb` (ADR 0017) |
| Texto de los `code` de error de negocio | `lib/presentation/l10n/error_messages/<modulo>_error_messages.dart` |

Módulos: `home`, `academic`, `training`, `challenges`, `progress` (pestañas) y `profile`, `planner`, `social`, `admin`, `reminders` (avisos locales, sin rutas).

## Pasos para un caso de uso nuevo

1. `domain/use_cases/<modulo>/` → caso de uso + su `Contract` (devuelve `AppResult<T>`).
2. `domain/repositories/` → método en el contrato.
3. `data/remote_data_source/<modulo>/` → la llamada real con `ApiClient` (Dio) y su DTO.
4. `data/repository/` → implementación con `RepositoryErrorHandler.guard()`.
5. `*_di.dart` del módulo → registrar cada pieza contra su contrato.
6. `presentation/screens/<zona>/<pantalla>/bloc/` → eventos, estado y bloc (`@freezed`).
7. `presentation/screens/<zona>/<pantalla>/page/` → la pantalla.
8. `<modulo>_routes.dart` → navegación.
9. `parts/app_es_<modulo>.arb` → textos (y los mismos en `app_en_`, `app_fr_` y `app_pt_<modulo>.arb`; `translations_test.dart` lo comprueba), y `<modulo>_error_messages.dart` para los `code` de error nuevos. Fechas y números con `DateFormat`/`NumberFormat` sin idioma fijo: siguen el de la app.
10. Regenerar código y traducciones.

## Comandos

- Generar: `dart run build_runner build --delete-conflicting-outputs`, `dart run tool/merge_arb.dart && flutter gen-l10n`, `dart run tool/generate_tokens.dart` (si cambian los tokens).
- Verificar: `flutter analyze` y `flutter test`.
- Ejecutar: `flutter run -d chrome --web-port 5173 --dart-define-from-file=config/dev.json` (plantilla en `config/dev.example.json`; en el emulador Android, `API_BASE_URL=http://10.0.2.2:8080`).

## Comentarios

- `///` de una o dos líneas en cada clase pública: qué papel cumple y con qué se relaciona (p. ej. «Implementa [RoutineRepositoryContract] con [RoutineRemoteDataSource]»).
- Explica el porqué de las reglas no obvias; nada de comentarios evidentes ni código comentado.

## No hacer

- No editar `*.g.dart`, `*.freezed.dart`, `l10n/gen_l10n/`, `l10n/app_<idioma>.arb` ni `theme/tokens.g.dart`.
- No llamar a servicios externos (DeepSeek, R2, Supabase) desde el cliente: todo pasa por el backend.
- No crear carpetas fuera de la estructura del perfil sin preguntar.
