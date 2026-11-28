# ADR 0069 — Apartado «WOD»: pizarra, cronómetro por formato y marcas

- **Fecha:** 2026-11-28
- **Estado:** aceptado
- **Completa:** ADR 0037 (apartados de Entreno), ADR 0068 (catálogo `Sport` y actividad apuntada).
  Maqueta aprobada: «Deportes, gimnasio y calendario» (tanda 4).

## Contexto

Entreno tenía «Gimnasio» y «Deportes». Faltaba el entreno del día por formato (el «WOD» de un box): una pizarra
con lo que toca, un cronómetro que entiende el formato y dónde apuntar la marca. No se usa el nombre de la marca
registrada que popularizó este tipo de entreno: el apartado se llama **WOD**.

## Decisión

1. **Servidor, módulo `wod` (dueño: Entrenamiento).** `Wod` (día, plantilla opcional y su pizarra, `WodDefinition`:
   título y fuerza opcionales, formato, límite, rondas y de 1 a 12 movimientos con cantidad, unidad y kilos Rx y
   adaptado) y `WodResult` (división, tipo de marca, valor, `capped`). Tablas `wods` y `resultados_wod` (`V1084`),
   con `JdbcClient` como las carreras; los movimientos van en `jsonb`.
2. **Las reglas de cada formato viven en `WodDefinition`:** «por tiempo» lleva de 1 a 50 rondas y límite opcional;
   AMRAP y EMOM exigen límite (EMOM, en minutos enteros: sus rondas son esos minutos); Tabata son siempre 8 rondas
   de 20 s + 10 s. El límite va de 1 a 60 minutos.
3. **Cómo se apunta lo decide el formato** (`WodFormat.scoreType`): tiempo en «por tiempo» (o repeticiones con
   `capped` si se acabó el límite), rondas + repeticiones en AMRAP y repeticiones en EMOM y Tabata. El cliente puede
   no mandar `scoreType`; si lo manda, solo vale el del formato o `LOAD` (la carga de la parte de fuerza, en kg
   enteros, que no compite por la mejor marca). Un tiempo por encima del límite se rechaza.
4. **«El mismo WOD» es la misma huella** (`WodDefinition.signature`: formato, límite, rondas y movimientos; ni el
   título ni la fuerza). Un movimiento de plantilla cuenta por su código, así da igual el idioma. La **mejor marca**
   se calcula en el servidor por huella y división (`WodResult.best`): terminar gana a quedarse en el límite; en
   tiempo gana el menor y en lo demás el mayor; a igualdad, la primera.
5. **Plantillas de ejemplo en código** (`WodTemplates`, 8, sin material o con poco, de 4 a 20 minutos), con códigos
   estables; el nombre de cada una y de cada movimiento lo pone el cliente en es/en/fr/pt, como los entrenos de
   carrera. Los nombres son propios y neutros. Sin WOD propio hoy, la pizarra enseña la plantilla del día (rotan por
   fecha) y lo dice (`example`).
6. **Guardar una marca crea su actividad** con `LogPastActivityUseCase` y `sport = WOD` (nuevo en el catálogo
   `Sport`, categoría `OTHER`): racha, XP, carga y retos cuentan sin reglas nuevas. La actividad acaba «ahora» y
   dura lo que marcó el cronómetro (o el tiempo, o el límite), con el mínimo del planificador (10 min). Sin
   esfuerzo indicado cuenta 7 de 10. La marca de una plantilla aún sin usar manda la pizarra entera y el servidor
   crea el WOD de la persona en la misma transacción.
7. **Cliente.** Tercer apartado `TrainingSection.wod` (`WodHomePage`): «Añadir mi WOD» (con borde), la pizarra
   (`WodBoardCard`: pastilla «WOD de ejemplo», titular del formato, movimientos con la cantidad en negrita, Rx /
   Adaptado con su explicación, mejor marca y la de hoy, «Editar» y «Cambiar por otro»), **«Empezar cronómetro»**
   como única acción rellena, «Apuntar marca» y «Mis marcas». No se añade ninguna fuente: la pizarra usa la del
   tema con cifras de ancho fijo.
8. **WOD en marcha** (`WodLivePage`, pantalla completa, siempre con el tema oscuro): la foto del gimnasio ya
   empaquetada bajo un velo de la superficie oscura al 85 % (`TokensOpacity.coverScrimMax`), que garantiza el
   contraste del texto con cualquier foto. Las fases del reloj son dominio puro (`WodTimer`): hacia delante con
   límite en «por tiempo», cuenta atrás en AMRAP, por minutos en EMOM y 20 s / 10 s × 8 en Tabata. El lector solo
   oye los cambios de fase o de ronda, nunca cada segundo. Las pausas no cuentan.
9. **La cuenta no sobrevive a salir de la pantalla:** guardarla en el teléfono y recuperarla (como la sesión de
   gimnasio) no salía barato en esta tanda. A cambio, salir con el reloj en marcha pregunta antes.

## Consecuencias

- Borrar un WOD borra sus marcas; las actividades ya apuntadas se quedan (y su XP y su carga).
- Una app anterior ve la actividad de un WOD con `kind = OTHER`; `sport = WOD` no lo conoce y lo ignora.
- Cerrar la app a mitad de un WOD pierde el cronómetro (se puede apuntar la marca a mano).
- Queda fuera de esta tanda: leer el WOD de una foto de la pizarra, libras y la tabla entre amigos.
