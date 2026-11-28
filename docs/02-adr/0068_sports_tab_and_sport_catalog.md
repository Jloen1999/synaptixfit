# ADR 0068 — Apartado «Deportes» y catálogo de deportes

- **Fecha:** 2026-11-28
- **Estado:** aceptado
- **Completa:** ADR 0033 (actividad apuntada), ADR 0037 (carreras con GPS), ADR 0039 y ADR 0055 (apartado «Correr»).
  Maqueta aprobada: «Deportes, gimnasio y calendario» (tanda 3).

## Contexto

El apartado se llamaba «Correr y deportes» pero solo hablaba de correr: un partido se apuntaba con un atajo suelto
(«Apuntar actividad») y un formulario general donde había que elegir «Tipo» y escribir el nombre. La actividad
guardaba una clase (`kind`: RUN/WALK/BIKE/SWIM/MATCH/OTHER), así que no se sabía si un partido era de fútbol o de
pádel ni cómo había acabado.

## Decisión

1. **Catálogo `Sport` en el servidor**, con código estable y categoría (`SportCategory`): `ENDURANCE` (RUN, WALK,
   BIKE, SWIM), `MATCH` (FOOTBALL, PADEL, TENNIS, BASKETBALL, VOLLEYBALL) y `OTHER` con nombre libre, que el servidor
   normaliza (sin espacios de más, 40 letras como mucho).
2. **La actividad apuntada gana `sport`, `sportName`, `mode` (`MATCH`|`TRAINING`), `result` (`WIN`|`DRAW`|`LOSS`) y
   `scoreText`** (marcador libre, 20 letras), agrupados en `SportDetails`. El modo solo vale en deportes de partido
   (por defecto, partido) y el resultado y el marcador solo en un partido: un entreno no los guarda. Un marcador más
   largo es un error de validación (no hay `code` nuevo).
3. **Compatibilidad:** `kind` se sigue aceptando y devolviendo. Sin `sport`, el servidor lo deduce de `kind` y, si
   era un partido, del título («Fútbol», «Pádel con Ana»; `Sport.fromLegacy`), y conserva el `kind` recibido. Con
   `sport`, el `kind` se deduce del deporte. `V1083` rellena las actividades ya guardadas con la misma regla; el
   resto queda como `OTHER` con su título de nombre.
4. **Sin reglas nuevas:** racha, XP, carga física y retos cuentan la actividad como siempre. El deporte y el
   resultado solo la describen.
5. **Cliente:** el apartado pasa a llamarse **«Deportes»**. Arriba, la carrera a medias o el entreno de hoy si los
   hay; debajo, una rejilla de tarjetas con foto (`SportGrid`): «Correr, andar o bici» (ancha), Fútbol, Pádel,
   Natación, Baloncesto, Tenis y «Otro deporte». Elegir el deporte es la acción: la rejilla no lleva botón relleno.
   «Apuntar actividad» deja de ser un atajo suelto: cada deporte lleva su «apuntar uno ya hecho».
   - «Correr, andar o bici» (`SportRunPage`): se elige cuál, «Empezar» (graba con el GPS de siempre, con el tipo ya
     elegido), «Apuntar una ya hecha» y «Crear entreno guiado».
   - Deporte de partido, natación y «otro deporte»: el mismo `PastActivityPage`/`PastActivityBloc`, con `sport`. El
     formulario general (con «Tipo» y «Día de mi rutina») sigue en Gimnasio y el historial.
   - «Otro deporte» (`OtherSportPage`): buscador con unos deportes frecuentes y «Añadir «x»».
6. **Una foto por deporte**, empaquetada con la app (`frontend/assets/images/sports/`, WebP de 1200 px y 120 KB como
   mucho, con autor y licencia en su `CREDITS.md`). Va con el patrón `AppCoverCard` (que ahora admite una foto
   empaquetada, `image`): la foto arriba y el texto sobre la superficie lisa, así cumple AA con cualquier foto.

## Consecuencias

- Una app anterior sigue apuntando y leyendo igual; solo no ve el resultado.
- El vóley está en el catálogo pero no tiene tarjeta: se elige en «Otro deporte».
- No hay «Los tuyos» (los deportes libres que más apunta cada persona): haría falta otro endpoint y su caso de uso
  en las dos partes; queda para cuando se pida.
- La foto de «Gimnasio» está descargada y acreditada, pero ese apartado aún no la usa.
