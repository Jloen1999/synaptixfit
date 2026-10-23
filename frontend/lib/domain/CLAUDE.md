# Capa domain (Flutter)

Rol: dominio + casos de uso. Es el centro y no conoce a nadie.

- Solo puede importar Dart, `freezed_annotation` y otras piezas de `domain/`.
- Prohibido importar `data/`, `presentation/`, Firebase, clientes HTTP o `flutter_bloc`. El test `test/architecture/dependency_rule_test.dart` lo comprueba.
- Modelos y estados inmutables con `@freezed`.
- Los casos de uso devuelven `Result<T, AppError>`; nunca lanzan excepciones.
- Un caso de uso = un archivo con su `Contract` + implementación.
- Los contratos de repositorio se llaman `*RepositoryContract` y viven en `repositories/`.
- `AppError` es sellado: una variante nueva requiere su caso en `ErrorMapper` (data) y su texto en el `.arb` (presentation).
