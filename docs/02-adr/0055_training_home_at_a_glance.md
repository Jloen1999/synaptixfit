# ADR 0055 — Entreno al grano: «Hoy toca», atajos arriba y la semana de un vistazo

- **Fecha:** 2026-11-17
- **Estado:** aceptado (maqueta «Entreno, rediseño» v4 aprobada «tal cual» por el propietario el 15 nov 2026)

## Contexto

Fase 3B del plan de mejoras. Al abrir Entreno › Gimnasio, la tarjeta del próximo entreno tenía unos nueve datos
(barra, «2/4 días», «Semana 2 de 6 · Sesión 3 de 4», lista de ejercicios y tres botones), «2/4 días» salía dos veces
y los atajos (ejercicios, plantillas, comunidad, plan semanal) estaban al final: había que bajar del todo. Correr
abría con el mapa sin decir qué tocaba hoy, cuatro cifras de la semana y textos largos al final.

## Decisión

### Gimnasio (cliente)

De arriba abajo, lo que se ve sin desplazarse en un móvil:

1. **Hoy toca** (`_TodayCard`). Sin rutinas: «Aún no tienes rutinas» y «Elegir una plantilla» (el único botón
   destacado; abajo, «O crea la tuya» con la IA o a mano). Con rutinas pero ninguna en curso, lo dice tal cual. Con
   un ciclo terminado no sale: su tarjeta ya dice qué hacer. Con día: foto, «Hoy» (o «Tocaba el lunes» en ámbar, o la
   fecha) con el nombre de la rutina en gris al lado (baja de línea con letra grande), el nombre de la sesión grande,
   «≈ 45 min · 6 ejercicios» y «Empezar» (o «Continuar»). «Ver rutina» es un botón de icono. El avance del ciclo y «Saltar este día» pasan al detalle de la rutina.
2. **Atajos** (`TrainingQuickActions`, compartido con Correr): Sesión libre (icono propio, no el rayo de las kcal),
   Plantillas, Ejercicios, Historial y Más (Plan semanal, Comunidad, Entrenar con amigos). El historial sale de la barra
   superior. Con letra grande pasan a varias filas (`AppTileGrid`), no se deslizan fuera de la vista. Van juntos en una
   tarjeta y con texto de 14 px: sobre el fondo gris y a 12 px, el círculo de color pesa más que el texto y la
   comprobación de contraste de los tests lo toma por fondo.
3. **Esta semana** (`TrainingWeekStrip`): siete puntos de lunes a domingo (hecho ✓, toca con aro, nada) y «N de M
   entrenos». Hoy va en color y con una rayita, no solo con color. Tocar un día hecho abre ese entreno; uno que toca,
   la rutina. El lector lee «Miércoles, Hoy: toca entrenar».
4. **¿Qué tal estás hoy?**: plegada y sin contestar, tres caras contestan la energía de un toque y abren las otras
   dos preguntas (sueño y agujetas). Las caras son botones propios, fuera de la fila que pliega.
5. **Mis rutinas** en carrusel con foto, estado, nombre y lo que toca; «Nueva rutina» es la última tarjeta.
6. Sugerencias en una línea plegada.

### Correr (cliente)

1. Arriba, un solo botón destacado: la carrera a medias («Seguir con la carrera»), si no **Hoy toca**
   (`_TodayRunCard`: «Hoy», el entreno, la hora y cuánto dura, y «Salir a correr») y, si no hay, «Salir a correr»
   directo. El mapa ya no está en Correr: sale al empezar a grabar, así que Correr no pide la ubicación al abrirse.
2. Atajos: Crear entreno, Apuntar partido e Historial, y «Correr libre» solo si arriba ya hay otro botón (si no, sería
   el mismo «Salir a correr»). El historial sale de la barra superior.
3. Dos cifras de la semana (distancia y tiempo en movimiento) con «Compartir»; la gráfica, el desnivel y las salidas
   se van (el detalle está en Progreso y la imagen compartida los sigue llevando).
4. «Próximo»: el siguiente entreno del calendario en una línea y «Ver todos (N)» despliega el resto. «Últimas»: las
   dos últimas actividades y «Ver todas». Después, tus entrenos de carrera.
5. La ayuda de la batería solo está en la pantalla de grabar.
6. En web y escritorio, el aviso de que se graba con el móvil y los mismos atajos.

### La semana la calcula el servidor

`GET /api/v1/training/week` (`GetTrainingWeekUseCase`, en `RoutineProgressService`) devuelve los siete días con
`state` (`DONE`, `PLANNED`, `FREE`), `today` y `sessionId`, más `done` y `total`.

- **Hecho:** día con al menos una sesión terminada, de rutina o libre. El día se cuenta en la zona de la app
  (`synaptixfit.insights.default-zone`, la misma que el resto de Entreno, no la de cada persona). Si hubo dos, se abre
  la última (regla en `TrainingWeek.of`). Un día con entreno cuenta como hecho aunque tocara otro: si hoy tocaba la
  rutina y se hizo una sesión libre, hoy ya se entrenó y el día de rutina sigue esperando al siguiente.
- **Toca:** `RoutineSchedule.upcoming`, la misma regla del «próximo día» extendida: el próximo día en su fecha (hoy si
  va con retraso o está en curso) y los siguientes en su día de la semana preferido, cada uno después del anterior.
  Es una previsión para pintar la semana; la rutina sigue avanzando al ritmo real. Solo el próximo día mira el
  calendario: los siguientes van a su día de la semana, porque su bloque se puede mover en cuanto se entrene el anterior.
- Los días pasados sin entrenar no «tocan»: lo que no se hizo pasa al siguiente día, no se marca como fallo.
- `total` = hechos + los que aún tocan. Sin rutina en curso, solo cuentan los hechos.

## Consecuencias

- Una consulta nueva y ligera (`TrainingSessionRepositoryPort.completedBetween`); el cliente no repite la regla.
- Gimnasio se reordena: las claves de la guía de la primera vez (ADR 0049) se movieron con sus partes («Hoy toca»,
  «Mis rutinas», el atajo Plantillas).
- Se quitan 13 textos que ya no usa ninguna pantalla.
