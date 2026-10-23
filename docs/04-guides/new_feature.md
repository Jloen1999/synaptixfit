# Añadir una funcionalidad

Orden de dentro hacia fuera; primero el backend, después el cliente. Ejemplo: «marcar un apunte como favorito».

## Backend (`backend/`)

1. **Dominio:** `domain/model/academic/Note.java` → método `markFavorite()`; si hace falta, excepción en `domain/exception/academic/` con su `code`.
2. **Caso de uso:** `application/port/input/academic/MarkNoteFavoriteUseCase.java` + implementación en el servicio de la feature.
3. **Persistencia:** columna nueva → migración `V<n>__academic_note_favorite.sql`; entidad y mapper.
4. **REST:** endpoint en el controller de la feature con su DTO.
5. **Composición:** bean en `AcademicBeanConfiguration` con `tx.wrap(...)`.
6. **Errores:** fila en `docs/03-api/errors.md` por cada `code` nuevo.
7. **Tests:** unitario del servicio (con `new` y dobles) y, si toca persistencia o REST, el `*IT` del módulo.

## Cliente (`frontend/`)

1. `domain/use_cases/academic/mark_note_favorite_use_case.dart` (+ método en el contrato del repositorio).
2. `data/remote_data_source/academic/` → llamada Dio; `data/repository/` → implementación con `guard()`.
3. Registro en `academic_data_di.dart` y `academic_domain_di.dart`.
4. Evento y estado en el bloc de la pantalla; la página solo envía el evento y pinta.
5. Textos en `l10n/parts/app_es_academic.arb`; texto de los `code` nuevos en `academic_error_messages.dart`.
6. `dart run build_runner build --delete-conflicting-outputs && dart run tool/merge_arb.dart && flutter gen-l10n`.
7. Test del bloc con `bloc_test`.

## Antes de terminar

`./mvnw test -Pintegration` · `flutter analyze && flutter test` · regenerar `docs/03-api/openapi.yaml` si cambió la API · documentación actualizada en el mismo cambio.
