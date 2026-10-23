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
- **Recordatorios locales del móvil:** `RemindersHost` (montado en `AchievementsHost`) llama a `SyncRemindersUseCase` al entrar en el armazón, con cada cambio de planificador/estudio/entrenamiento/preferencias/enfoque y al activar el interruptor «Recordatorios · En este móvil» (ajustes de notificaciones); al cerrar sesión los borra. Qué se programa lo decide el servidor (`GET /notifications/reminder-plan`); el cliente solo pone textos e ids (`ReminderComposer`) y programa con `ReminderSchedulerRepositoryContract`. No repliques preferencias, silencio ni límite en el cliente. En web no hace nada. Ver ADR 0013.
- **Reglas de XP y retos las decide el servidor:** el Pomodoro avisa según `xpStatus` y los retos usan `tracksTrainingSessions`; no repliques umbrales ni condiciones en el cliente.
- **Navegar a otra pestaña** con `context.go`; a pantallas completas con `context.push`. No uses `go` hacia una ruta de pantalla completa: destruye las pestañas.

## Puntos de extensión por módulo

Para que cada módulo crezca sin tocar ficheros compartidos, cada uno tiene su propio archivo en:

| Qué | Dónde |
|---|---|
| Registro de data sources y repositorios | `lib/data/di/<modulo>_data_di.dart` |
| Registro de casos de uso | `lib/domain/di/<modulo>_domain_di.dart` |
| Registro de blocs | `lib/presentation/di/<modulo>_presentation_di.dart` |
| Rutas | `lib/presentation/screens/<modulo>/<modulo>_routes.dart` |
| Textos | `lib/presentation/l10n/parts/app_es_<modulo>.arb` |
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
9. `parts/app_es_<modulo>.arb` → textos, y `<modulo>_error_messages.dart` para los `code` de error nuevos.
10. Regenerar código y traducciones.

## Comandos

- Generar: `dart run build_runner build --delete-conflicting-outputs`, `dart run tool/merge_arb.dart && flutter gen-l10n`, `dart run tool/generate_tokens.dart` (si cambian los tokens).
- Verificar: `flutter analyze` y `flutter test`.
- Ejecutar: `flutter run -d chrome --web-port 5173 --dart-define-from-file=config/dev.json` (plantilla en `config/dev.example.json`; en el emulador Android, `API_BASE_URL=http://10.0.2.2:8080`).

## Comentarios

- `///` de una o dos líneas en cada clase pública: qué papel cumple y con qué se relaciona (p. ej. «Implementa [RoutineRepositoryContract] con [RoutineRemoteDataSource]»).
- Explica el porqué de las reglas no obvias; nada de comentarios evidentes ni código comentado.

## No hacer

- No editar `*.g.dart`, `*.freezed.dart`, `l10n/gen_l10n/`, `l10n/app_es.arb` ni `theme/tokens.g.dart`.
- No llamar a servicios externos (DeepSeek, R2, Supabase) desde el cliente: todo pasa por el backend.
- No crear carpetas fuera de la estructura del perfil sin preguntar.
