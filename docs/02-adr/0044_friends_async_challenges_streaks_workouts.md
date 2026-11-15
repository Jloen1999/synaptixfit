# ADR 0044 — «Con amigos» asíncrono: retos privados entre amigos, racha con un amigo y «Entrenamos juntos»

- **Fecha:** 2026-11-15
- **Estado:** aceptado

## Contexto

Fase C1 del plan premium. Ya existían amistades, bloqueos, muro, comentarios y notificaciones (módulo social), las
plantillas de reto que el servidor cuenta solo (ADR 0043) y la pausa de racha (ADR 0042). La investigación (estudio
ATU y apps de referencia) recomienda apoyo mutuo sano en lugar de búsqueda de reconocimiento: solo amigos mutuos,
privado por defecto, reacciones fijas sin chat, el número de ánimos solo para quien publica, bloquear y denunciar en
un toque y nunca datos de bienestar.

## Decisión

### 1. Un módulo «Con amigos» dentro de Social

- Paquetes `together` en cada capa del backend; tablas propiedad de Social (V1064), sin entidades JPA (`JdbcClient`).
  API en `/api/v1/together`; el cliente vive en `presentation/screens/social/together/`.
- **Un solo punto de entrada:** «Con amigos» (`/social/together`), con una fila en Progreso › Retos y un botón en
  Amigos. Desde una rutina, ⋮ › «Entrenar con amigos». Ninguna pestaña nueva.
- **Solo amigos mutuos** (amistad aceptada, sin bloqueo y cuenta activa, `TogetherPeople.ensureFriends`). Lo que no
  es tuyo o de lo que saliste es 404. De otra persona solo se ve nombre y foto.

### 2. Retos privados entre amigos

- Salen de una plantilla de reto (ADR 0043) y se cuentan con la **misma `ChallengeRule`** sobre la misma lectura de
  lo hecho (`ChallengeReferencePort.activity`), siempre desde cero; no se guarda ningún recuento.
- De **7 a 14 días**; de **2 a 25 personas** (quien crea y de 1 a 24 amigos). Interpretamos «2-25» como tamaño del
  grupo para permitir el reto de dos.
- **Juntos por defecto:** meta común = meta de cada persona (la de la plantilla en proporción a los días) × personas
  dentro. La barra enseña el total y quién ha aportado, sin cifras de cada uno. **Competición opcional:** puntos y
  clasificación. El **tope diario** (120 min de Pomodoro o una cosa al día en los retos «por suma») vale en los dos
  modos: así un día de exceso no decide nada (fórmulas en `formulas.md`).
- Plantillas de bienestar (registro diario) prohibidas (`FRIEND_CHALLENGE_TEMPLATE_NOT_ALLOWED`).
- Invitación → «Unirme» / «No, gracias». **Salir en un toque**, sin confirmar, con «Deshacer» (vuelve a entrar; vale
  mientras el reto siga en marcha y se siga siendo amigo de quien lo creó, sin bloqueos con nadie de dentro: tras un
  bloqueo no se vuelve y se responde 404).
- **Tablón sin texto:** una entrada por persona y día en que sumó (derivada de lo hecho, no se guarda) y cuatro
  reacciones fijas (👏 🔥 💪 ❤️), una por persona y entrada, y solo a entradas que existen (esa persona sumó ese día). **Cuántas reacciones tiene una entrada solo lo ve quien
  la publicó**; los demás solo ven la suya.
- Sin XP: el reto con amigos anima; el XP sigue saliendo de lo que se hace.

### 3. Racha con un amigo

- Proponer → aceptar (cuenta desde ese día) → terminar (confirmado: se pierden los días). **Como mucho 5** por
  persona, propuestas o activas.
- Cuenta lo que es **estudio o entreno hecho** según el servidor: repaso, test, Pomodoro o entreno (`CompletedWorkoutsSql`);
  nunca el registro diario. Si alguno de los dos tiene la **racha en pausa** ese día (ADR 0042), el día ni suma ni
  rompe; si no, un día sin los dos la rompe (vuelve a 0).
- «A Ana le falta su parte de hoy» es una línea en la fila de la racha. **«Recordárselo»** (opcional) avisa al amigo
  como mucho **una vez al día** y solo si yo ya hice la mía; si el amigo apagó los avisos de racha («Más avisos»), no
  le llega (no se le dice a quien lo manda, para no revelar sus preferencias). Es un aviso social: también respeta sus
  preferencias y silencio.

### 4. «Entrenamos juntos»

- Quien invita elige su rutina (el día siguiente por hacer, o uno concreto) y de **1 a 4 amigos**, para **hoy**.
- **Cada uno con su sesión normal.** Decisión sobre la rutina: a quien no la tiene se le **copia en pausa** en «Mis
  rutinas», marcada «Copiada de Ana» (`CopyRoutineForFriendUseCase`); si ya tenía una copia de esa rutina, se reutiliza.
  Así la sesión en vivo, sus cronómetros, el borrador sin conexión y el historial son los de siempre, sin tocarlos; la
  copia en pausa no cambia su rutina en curso ni crea eventos en su calendario, y se puede eliminar después. Se
  descartó una sesión «prestada» sin copia porque obligaba a cambiar la sesión en vivo y su modelo.
- `GET /together/workouts/by-session/{id}` responde **204** si la sesión no es de entrenar juntos (lo normal), sin
  error que tapar en el cliente.
- En la sesión en vivo, un panel plegable enseña por ejercicio quién lo tiene **hecho / por hacer** (por hueco, con
  las series de trabajo planificadas). **Consulta cada 12 s** (15 s en el detalle) mientras la pantalla está abierta,
  sin WebSocket; un fallo de red no cambia nada.
- Al terminar, una **tarjeta conjunta** (en el resumen de la sesión y en el detalle): quiénes, mis minutos y cuántos
  ejercicios. Nunca pesos, repeticiones ni esfuerzo de los demás.

### 5. Privacidad y moderación

- Nunca se comparten bienestar, ciclo, fatiga, sueño, registro diario, peso corporal ni ubicación.
- **Bloquear y denunciar en un toque** desde el menú de cada persona en cada pantalla nueva. Bloquear usa el bloqueo
  de siempre. Denunciar crea una fila en `denuncias_usuario` (sin texto: solo dónde pasó) que la administración ve en
  su cola de moderación como «Persona» y quita al revisarla. Una denuncia sin revisar de la misma persona a la
  misma otra basta: repetirla no llena la cola.
- **Al bloquear o dejar de ser amigos** se publica `FriendshipEnded` y se sale de lo compartido entre los dos
  (`TogetherCleanupService`): la racha se termina; en lo que creó uno, el otro sale; entre dos invitados de una
  tercera persona, sale quien bloquea (dejar de ser amigos no obliga, porque los invitados no tenían que ser amigos
  entre sí).
- **Borrado y exportación:** las filas de la persona se borran al vaciar y al anonimizar la cuenta (y en cascada al
  eliminarla) y salen en su exportación (sus participaciones, rachas, reacciones puestas y denuncias hechas).
- `LegalTerms.CURRENT_VERSION` **no sube** en esta fase: la política se ha redactado y la versión nueva la decidirá el
  propietario al final de la fase C2.

## Consecuencias

- Nueva migración V1064, 21 casos de uso en el backend y otros tantos en el cliente; catálogo de errores, eventos,
  fórmulas, modelo de datos, Google Play y política de privacidad actualizados.
- Lo que suma cada persona se calcula en cada lectura (N personas × una lectura de lo hecho); con 25 personas es
  asumible. Si creciera, se guardaría un recuento por evento como en los retos propios.
- Quien recibe una rutina copiada la conserva en pausa: es su copia y la puede eliminar. Si quien invita cambia
  después ese día de su rutina, se copia la versión nueva (resuelto en el cierre del plan premium, ADR 0045).
- Los topes de amigos (24 y 4) también los conoce el cliente para limitar el selector; el servidor manda y responde
  `TOGETHER_GROUP_SIZE` si no se cumplen.
