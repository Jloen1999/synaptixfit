# 0002. Usar Flutter con BLoC, get_it y freezed en el cliente

* **Estado:** Aprobado
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
El cliente usaba Riverpod con providers que mezclaban acceso a datos, reglas y estado de pantalla. La plantilla corporativa exige el perfil `frontend-flutter-bloc` para todo frontend Flutter.

## Decisión
Se reescribe el cliente en `frontend/` con el perfil Flutter + BLoC: capas `domain`/`data`/`presentation`, `get_it` como raíz de composición, `flutter_bloc` como coordinador de estado (bloc por pantalla), `freezed` para modelos, eventos y estados, `go_router` para la navegación y `Result<T, AppError>` en lugar de excepciones fuera de `data/`. El cliente HTTP es Dio contra el backend propio.

## Consecuencias
* **Positivas:** estado predecible y testeable con `bloc_test`; misma estructura que el resto de proyectos de la empresa.
* **Negativas:** reescritura completa de la interfaz; más código de generación (`build_runner`).
