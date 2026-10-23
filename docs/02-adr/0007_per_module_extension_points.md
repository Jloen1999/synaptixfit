# 0007. Dar a cada módulo sus propios puntos de extensión

* **Estado:** Aprobado
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
Registrar dependencias, rutas, textos y beans en un único fichero por capa provoca conflictos cuando varios módulos evolucionan a la vez.

## Decisión
- **Backend:** una `<Feature>BeanConfiguration` por funcionalidad en `infrastructure/config/`.
- **Cliente:** un fichero por módulo para el registro en cada capa (`<modulo>_data_di.dart`, `<modulo>_domain_di.dart`, `<modulo>_presentation_di.dart`), las rutas (`<modulo>_routes.dart`), los textos (`l10n/parts/app_es_<modulo>.arb`, que `tool/merge_arb.dart` une en el `app_es.arb` generado) y los mensajes de error. Los tokens de diseño viven en `docs/05-design/tokens.json` y `tool/generate_tokens.dart` genera `tokens.g.dart`.

## Consecuencias
* **Positivas:** cambios de módulos independientes sin conflictos; la raíz de composición solo orquesta.
* **Negativas:** dos pasos de generación más (`merge_arb`, `generate_tokens`) antes de `flutter gen-l10n`.
