# 0001. Usar arquitectura limpia con núcleo de roles agnóstico

* **Estado:** Aprobado
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
La primera versión mezclaba responsabilidades: los "providers" de la app consultaban la base de datos directamente, había lógica de negocio repartida entre el cliente, triggers y funciones SQL, y archivos de miles de líneas. Cambiar una regla obligaba a tocar varias capas y no había forma automática de detectar dependencias indebidas.

## Decisión
Todas las partes siguen el núcleo de `docs/01-architecture/core.md`: dominio en el centro sin dependencias, casos de uso de una sola acción, adaptadores intercambiables y una raíz de composición. Cada stack se rige por su perfil (`docs/01-architecture/profiles/`) y la regla de dependencia se verifica con un test en cada parte.

## Consecuencias
* **Positivas:** reglas de negocio localizables y testeables sin infraestructura; frontera verificada automáticamente; nuevas tecnologías como adaptadores.
* **Negativas:** más archivos y algo de código de mapeo entre capas.
