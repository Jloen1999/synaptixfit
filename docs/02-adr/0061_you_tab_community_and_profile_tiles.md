# ADR 0061 — Pestaña «Tú»: Comunidad, atajos de Retos y Perfil en tarjetitas

- **Fecha:** 2026-11-20
- **Estado:** aceptado (maqueta `inicio-calendario.html`, pantallas 5, 7 y 8, aprobada por el propietario el 19 nov 2026,
  tanda 3)
- **Cambia en parte:** ADR 0038 (la pestaña «Progreso» pasa a llamarse «Tú» y gana el apartado «Comunidad»), ADR 0044
  (las filas «Plantillas de retos» y «Con amigos» de Retos pasan a tarjetitas) y ADR 0059 (el icono «Comunidad» de Inicio
  ya no abre Amigos).

## Contexto

Lo social estaba repartido en pantallas sueltas sin una puerta clara: Amigos se abría desde el Perfil o desde el icono de
Inicio, el muro se llamaba «Comunidad» y se abría desde el Perfil o desde «Ver más cifras» de Progreso, «Con amigos» desde
una fila de Retos y los retos de la comunidad desde un enlace al final de la lista. El Perfil obligaba a bajar casi una
pantalla entera (cuenta, «Amigos y comunidad», perfil físico con todas sus cifras, perfil académico y sus filas) y
Ajustes era un engranaje de la barra. En Retos, «Nuevo reto» era un botón flotante que tapaba la lista y había dos
tarjetas grandes antes de los retos.

## Decisión

### «Tú» en vez de «Progreso»

- La quinta pestaña se llama **«Tú»** (icono de persona, `AppIcons.tabYou`). La ruta sigue siendo `/progress` y la rama
  del router no cambia: los avisos, las celebraciones y los enlaces de siempre siguen llegando.
- **Sin barra de título:** arriba, tu foto y tu nombre con «Ver perfil» y una flecha (`_YouHeader`). Toda la fila es un
  botón que abre el Perfil con `push` (es pantalla completa).
- Cuatro apartados, **cada uno con su icono** (icono encima del texto, 56 px de alto; con el texto grande, 72):
  Resumen · Retos · Insignias · **Comunidad** (`ProgressTab.community`, `?tab=community`, `ProgressPaths.community`;
  icono de grupo propio, `AppIcons.communityTab`, distinto del de tu lista de amigos). Se desplazan solo si el apartado
  más ancho no cabe en su cuarta parte del ancho: se mide con `context.textWidth` (a 320 px, en francés o con el texto
  al 120 % ya pasa), no solo con el tamaño de letra.
- El nombre de la cabecera es el encabezado de la pestaña para el lector.

### Tú › Comunidad (`CommunityTab`, `CommunityBloc`)

- Arriba, si hay, **la solicitud de amistad** más reciente con «Aceptar» (el único botón relleno de la pantalla; el
  lector oye «Aceptar a Luis») y «Rechazar» (icono con borde, aparte; «Rechazar a Luis»); «Ver las N» lleva a Amigos › Recibidas. Se contesta con los mismos casos de uso
  que Amigos (`AcceptFriendRequestUseCase`, `RejectFriendRequestUseCase`).
- Cuatro tarjetitas: **Mis amigos** (con cuántos), **Buscar** (abre Amigos con el buscador enfocado,
  `/social/friends/search`), **Muro** y **Retos de otros** (`/challenges/community`).
- **«Con amigos ahora»:** hasta tres filas con lo que está en marcha (invitaciones por contestar, salas de estudio,
  entrenos juntos, retos con amigos y rachas activas), cada una abre lo suyo; «Ver todo» abre «Con amigos». Qué filas
  salen y en qué orden lo decide el estado (`CommunityState.togetherNow`, con su test); la página solo pone textos,
  iconos y destinos.
- **«Lo último del muro»:** la tarjeta que antes estaba plegada en el Resumen (`CommunityPreviewCard`) se muda aquí; el
  Resumen ya no pide el muro (`GetProgressOverviewUseCase` sin `getCommunityPreview`) y Comunidad lo lee con
  `GetCommunityPreviewUseCase`.
- No se duplica ninguna pantalla: Amigos, Muro, «Con amigos» y los retos de la comunidad siguen siendo las de siempre y su
  flecha «Volver» sin pila lleva a Tú › Comunidad (`SocialExternalPaths.community`).
- Lee en paralelo solicitudes, amigos, «Con amigos» y muro. Solicitudes y amigos son obligatorios (si fallan, error con
  «Reintentar»); «Con amigos» y el muro, opcionales (su sección dice «No se ha podido cargar»). Se refresca sola con los
  cambios sociales (`DataTopic.social`), no con los del canal en directo (cambian demasiado a menudo).

### Tú › Retos

- Fila de **cuatro tarjetitas** (`ChallengeShortcuts`, con `AppTileGrid`): **Nuevo** (la hoja rápida de siempre, sobre el
  color principal), **Plantillas**, **Con amigos** y **De otros** (`AppIcons.communityChallenges`, el mismo que
  «Retos de otros» en Comunidad). Desaparecen el botón flotante, las dos tarjetas grandes
  y el enlace del final. El lector oye «Nuevo reto», «Plantillas de retos», «Retos con amigos» y «Retos de otros» (el
  nombre contiene siempre el texto visible, WCAG 2.5.3).
- Cada cifra lleva su palabra: «3 de 8 tareas», «2 de 4 sesiones» (antes «3/8»).

### Perfil en tarjetitas

- La cuenta en una tarjeta compacta: foto, nombre, correo y visibilidad (cada uno en su línea, sin cortarse), la racha
  (chip que abre Tú › Resumen con `go`) y «Editar» (botón con borde). «Editar» baja de línea si no cabe al lado: con el
  texto grande o si la tarjeta mide menos de `TokensLayout.cardActionsInlineMin` (escalado), como `UserTile`.
- **Seis tarjetitas:** Amigos (con el número de solicitudes, en globo y en texto), Muro, Cómo me ven (perfil público, con
  su visibilidad), **Físico** («58 kg · 165 cm»; «Sin completar» si faltan peso y altura), **Académico** (el grado o «Sin completar») y Ajustes.
  Físico solo si la persona hace deporte; Académico, solo si estudia. Ajustes ya no está en la barra (un solo camino).
- Físico y Académico abren su **ficha completa** (`/profile/physical`, `/profile/studies`, `ProfilePhysicalPage` y
  `ProfileStudiesPage`): los datos de antes, con «Editar», «Ver la evolución» o grados, asignaturas y matrícula. Cada una
  lee el perfil con su `ProfileBloc`, así también se abren en frío.
- La sugerencia de la fecha de nacimiento y el aviso de terminar el onboarding van debajo de las tarjetitas, con botón
  tonal en vez de texto de color.
- La flecha «Volver» sin pila del Perfil lleva a «Tú» (`ProfilePaths.you`).

### Inicio

- El icono «Comunidad» de la cabecera (con el número de solicitudes, `pendingFriendRequests`) abre Tú › Comunidad
  (`HomeExternalPaths.community`, con `go`), donde las solicitudes recibidas salen arriba. La guía de primer uso de Inicio
  lo explica así.

### Nombres

- El muro se llama **«Muro»** en todas partes (título de la pantalla, tarjetitas); «Comunidad» es el apartado de «Tú».
- Los avisos que decían «Progreso › Retos» dicen «Tú › Retos».

### Direcciones

- No se quita ninguna ruta: `/challenges`, `/progress/badges`, `/social`, `/social/friends` y
  `/social/friends/requests` siguen funcionando (avisos y enlaces viejos). Nuevas: `/progress?tab=community`,
  `/community` (redirige allí), `/social/friends/search`, `/profile/physical` y `/profile/studies`.

## Consecuencias

- Lo social tiene una puerta (Tú › Comunidad) y el Perfil cabe en una pantalla.
- `AppShortcutTile` (`widgets/`) es la tarjetita de acceso compartida: icono en un cuadrado de color, nombre, detalle
  (hasta tres líneas) y globo opcional (más de 99: `socialBadgeOverflow`); se anuncia como un botón con nombre y
  detalle. Va siempre en `AppShortcutGrid`, con **una sola regla de ancho**: cada tarjetita mide al menos
  `TokensSize.quickActionMinWidth` y nunca menos que su palabra más larga (medida con el tamaño de letra de la persona).
  Si no caben, `AppTileGrid` las pasa a filas de la mitad; ninguna palabra se parte («Publicacio/nes»), tampoco en
  francés, portugués o al 200 %. Así Retos queda en una fila de cuatro y Comunidad en 2 × 2 en un móvil de 390 px.
- Los atajos de Entreno (`TrainingQuickActions`) siguen aparte: van juntos dentro de una sola tarjeta, con el icono en
  un círculo de 48 px como zona de toque principal, sin detalle ni globo, con claves para la guía de primer uso y con
  sus tests de Gimnasio y Correr. Pasarlos a `AppShortcutTile` cambiaría su aspecto aprobado (ADR 0055) sin ganar
  nada para la persona; si un día se rediseñan, la variante sería una `AppShortcutTile` sin tarjeta.
- Una petición más al abrir Comunidad (cuatro en paralelo) y una menos al abrir el Resumen.

## Desviaciones de la maqueta

- Comunidad lleva una cuarta tarjetita, «Retos de otros», porque los retos de la comunidad también son lo social que
  estaba suelto; con cuatro, la rejilla queda en 2 × 2 en un móvil (la maqueta tenía tres en fila).
- Se ve una sola solicitud con «Aceptar» (la maqueta enseñaba una): así hay un único botón relleno; «Ver las N» lleva al
  resto.
- Comunidad termina con «Lo último del muro» (no estaba en la maqueta): es la tarjeta que salía en el Resumen y se muda
  aquí en vez de perderse.
