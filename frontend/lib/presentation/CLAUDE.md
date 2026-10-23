# Capa presentation (Flutter)

Rol: adaptadores de entrada (pages) + coordinador de estado (blocs).

- Puede importar `domain/`. Prohibido importar `data/`.
- Cada pantalla: `screens/<zona>/<pantalla>/{bloc,page}/`.
- Bloc en tres archivos: `*_bloc.dart` (con `part`), `*_event.dart`, `*_state.dart` (`@freezed`).
- La página solo envía eventos (`context.read<Bloc>().add(...)`) y pinta estados. Sin lógica de negocio.
- Textos siempre en `l10n/app_es.arb`, con `context.localizations`. Nada de strings en el código.
- Errores al usuario: `ErrorsMessageMixin` convierte `AppError` en texto del `.arb`. Nunca mostrar el `detail` del servidor.
- Antes de crear un widget, busca en `widgets/` (y su barrel `widgets.dart`) si ya existe. Solo se parametriza lo que varía.
- Colores y tipografía desde `theme/`, nunca valores sueltos.
- Blocs registrados en `di/presentation_di.dart` como factory.
