# 0017. Cambiar el idioma en el cliente y que el servidor solo dé códigos

* **Estado:** Aprobado
* **Fecha:** 2026-10-24
* **Autores:** SynaptixFit

## Contexto
La app solo estaba en español. Se quiere elegir entre español, inglés, francés y portugués sin
romper nada. Hay tres fuentes de texto: la interfaz (ARB del cliente), lo que escribe la IA
(resúmenes, cuestionarios, rutinas, sugerencias) y las notificaciones automáticas, que el servidor
guardaba ya redactadas en español. Los catálogos (ejercicios, insignias, universidades) son datos en
español.

## Decisión
* **Interfaz:** un fragmento ARB por módulo e idioma (`parts/app_<idioma>_<modulo>.arb`);
  `tool/merge_arb.dart` genera `app_es.arb` (plantilla con metadatos) y `app_en/fr/pt.arb`. El
  idioma se elige en Ajustes (o «Como el dispositivo», con español si el del dispositivo no está) y
  se guarda en el dispositivo, igual que la apariencia. Fechas y números siguen a
  `Intl.defaultLocale`, que la app fija al resolver su idioma.
* **IA:** el cliente envía su idioma en `Accept-Language`; los adaptadores de IA lo leen
  (`AiLanguage`) para pedir el texto en ese idioma. El dominio no sabe de idiomas. Fuera de una
  petición (tareas en segundo plano) escriben en español.
* **Notificaciones automáticas:** llevan un código y sus datos (`codigo_mensaje`,
  `parametros_mensaje`, `V900`) y el cliente pone el texto, como ya hacía con el banner de Inicio y
  los errores. Título y descripción se siguen guardando en español como respaldo (avisos antiguos y
  los escritos a mano por la administración).
* **Catálogos:** el español sigue siendo el canónico (las reglas de rutinas buscan palabras en los
  nombres). Los nombres de los ejercicios y el vocabulario de entrenamiento (músculos, material y
  partes del cuerpo) tienen su traducción en `ejercicio_nombres` y `vocabulario_nombres` (`V930`):
  nombres técnicos como se dicen en un gimnasio de cada idioma (portugués de Portugal: «curl»,
  «haltere»). El adaptador `CatalogTranslationsJdbcAdapter` los tiene en memoria por idioma (y la
  vacía al confirmar un cambio) y los DTO REST los aplican según `Accept-Language`
  (`LocalizedNames`); la búsqueda encuentra también por el nombre traducido. Descripciones e
  instrucciones de ejercicios, insignias y titulaciones siguen en español. La administración
  recibe siempre el español (`ExerciseResponse.canonical`): edita el canónico y, si viera la
  traducción, la guardaría encima.
* **Ejercicios nuevos o renombrados desde el panel:** al escribir el nombre en español, la IA
  propone el nombre técnico en inglés, francés y portugués (`POST /admin/exercises/name-suggestions`,
  mismo criterio que la traducción del catálogo) y la administración lo revisa en el formulario
  antes de guardar. Se guarda con el ejercicio, en la misma transacción (campo `translations` del
  alta o edición; si se omite, no cambia), y se ve al momento. La propuesta no se guarda sola: así
  ninguna traducción automática llega a la app sin que alguien la mire.

## Consecuencias
* **Positivas:** cambiar de idioma no necesita al servidor ni recargar; la IA responde en el idioma
  de quien la usa; una notificación se lee en el idioma de quien la recibe aunque la provoque otra
  persona. El test `translations_test.dart` impide claves sin traducir o marcadores perdidos.
* **Negativas:** cada texto nuevo hay que traducirlo a tres idiomas más; las descripciones e
  instrucciones de ejercicios, las insignias y las titulaciones aparecen en español en los demás
  idiomas; las traducciones de nombres son automáticas (IA con pistas de openGym) y conviene que
  las revise alguien nativo; el vocabulario (músculos, material, partes del cuerpo) solo se traduce con migraciones y,
  como se guarda por su nombre español, si se renombra un término se pierde su traducción; `LocalizedNames`
  lee el idioma del hilo de la petición, así que un DTO construido fuera de ella sale en español; lo ya generado por la IA queda
  en el idioma en que se generó.
