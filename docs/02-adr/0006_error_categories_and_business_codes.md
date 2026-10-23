# 0006. Derivar el estado HTTP de categorías de error y traducir los códigos de negocio por `code`

* **Estado:** Aprobado
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
El perfil backend propone un mapa `code → estado HTTP` en el `GlobalExceptionHandler`, y el catálogo de errores una variante de `AppError` por `code`. Con ocho módulos y decenas de códigos, ambos ficheros serían puntos de conflicto constantes y su mantenimiento manual, propenso a errores.

## Decisión
- **Backend:** cada excepción de dominio extiende una categoría semántica (`NotFoundException`, `ConflictException`, `BusinessRuleException`, `InvalidInputException`, `ForbiddenOperationException`, `AuthenticationException`, `ExternalServiceException`). El handler deriva el estado de la categoría; `STATUS_BY_CODE` queda para excepciones justificadas. El dominio sigue sin conocer HTTP.
- **Cliente:** `AppError` tiene variantes para los `code` transversales y `AppError.business(code)` para los de negocio. `ErrorsMessageMixin` traduce `business` delegando en un resolutor por módulo (`presentation/l10n/error_messages/<modulo>_error_messages.dart`). La traducción sigue siendo por `code`, nunca por estado HTTP.

## Consecuencias
* **Positivas:** añadir un `code` no toca ficheros compartidos; imposible olvidar el estado HTTP de un error nuevo.
* **Negativas:** la columna `AppError` del catálogo usa `AppError.business('CODE')` para los códigos de negocio.
