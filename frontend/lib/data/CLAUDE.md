# Capa data (Flutter)

Rol: adaptadores de salida + traducción de errores técnicos.

- Puede importar `domain/`. Prohibido importar `presentation/`.
- Los repositorios implementan los `*RepositoryContract` de `domain/` y envuelven cada llamada en `RepositoryErrorHandler.guard()` (o `guardStream()`). **Nunca** `try/catch` manual.
- Los modelos técnicos (JSON, documentos de Firebase) se mapean a modelos de dominio antes de salir de esta capa.
- Errores: excepción técnica → `toGenericError()` → `ErrorMapper.mapToError()` → `AppError`.
  - Firebase → `errors/firebase_errors/`.
  - API HTTP con RFC 9457 → `errors/http_errors/`, traduciendo **por `code`**, no por estado HTTP.
- Todo `code` nuevo debe existir en `docs/03-api/errors.md`.
- Registro en `di/data_di.dart`, siempre contra el contrato.
