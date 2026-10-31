# 0020. Suscripción al calendario con un enlace privado (feed ICS)

* **Estado:** Aprobado
* **Fecha:** 2026-10-30
* **Autores:** SynaptixFit

## Contexto
La exportación `.ics` existente descarga el calendario una vez: los cambios posteriores no llegan al calendario
del usuario. Para verlo siempre al día en Google Calendar, Apple Calendar u Outlook, esos servicios tienen que
poder pedir el calendario cada pocas horas **sin iniciar sesión** (no envían el JWT de la app). La escritura con
la API de Google Calendar exige una verificación de Google que puede tardar meses y solo cubre Google.

## Decisión
* **Enlace privado por usuario** `GET /api/v1/planner/calendar-feed/{token}.ics`, ruta pública en `SecurityConfig`
  (solo GET y HEAD de `/*.ics`; el resto de `/planner` sigue pidiendo sesión). El token tiene 256 bits aleatorios (`SecureRandom`, base64url): no es adivinable.
* **Solo se guarda su huella SHA-256** (`suscripciones_calendario.token_hash`, V960). El token en claro se devuelve
  una vez al crearlo (`POST /api/v1/planner/calendar-feed`), como una contraseña: la BD filtrada no permite leer
  calendarios.
* **Uno por usuario**: crear otro sustituye al anterior; `DELETE` lo revoca; un token desconocido o revocado da
  404 `PLANNER_CALENDAR_FEED_NOT_FOUND`. Borrar la cuenta lo borra en cascada.
* **Mismo contenido que la exportación manual** (`ExportIcsUseCase`): bloques y entregas de hace 30 días a dentro
  de 180, con `Cache-Control: no-store` y `X-Robots-Tag: noindex`.
* **El token no queda en los registros:** el nginx del cliente atiende esa ruta sin registro de acceso ni de
  errores y con un límite de 30 peticiones por minuto e IP; el backend no registra rutas. Traefik y Cloudflare
  también ven la ruta: sus registros de acceso deben estar desactivados o enmascarados (`REQUISITOS-INFRA.md`).
* El cliente compone la URL con su dirección de la API y ofrece la variante `webcal://` para abrir la app de calendario.

## Consecuencias
* **Positivas:** funciona con cualquier calendario sin verificaciones de terceros ni OAuth; revocable al instante.
* **Negativas:** quien tenga el enlace ve el planificador (se avisa al crearlo); Google refresca cada varias horas;
  el enlace no se puede volver a mostrar (hay que crear otro).
* **A vigilar:** el enlace no se revoca solo al cambiar la contraseña ni al cerrar sesión en todos los
  dispositivos; quien crea que se ha filtrado debe crear otro o desactivarlo. Si se añade «cerrar sesión en
  todos los dispositivos», debería revocarlo también.

## Importación de calendarios por URL (misma fase)
* El Campus Virtual (Moodle) exporta un calendario general: `ImportGeneralCalendarUseCase` trae solo exámenes y
  entregas, cada uno en la asignatura que mencionen el título o las categorías (la descripción, solo como último
  recurso), sin clases ni avisos de apertura. Mismo endpoint `POST /planner/ics/import`, sin `subjectId`.
* **SSRF:** el backend descarga una URL del usuario. Cada salto, incluidas las redirecciones (que se siguen a mano,
  como mucho 3), debe ser http(s) a los puertos 80/443 y resolver solo a IP públicas. También se excluyen CGNAT,
  ULA, NAT64 y los demás rangos especiales. Tope de 5 MB y de 30 s para la descarga entera.
* **Riesgos residuales:** el cliente HTTP vuelve a resolver el nombre al conectar (DNS rebinding); se cubre con el
  filtrado de salida del contenedor (`REQUISITOS-INFRA.md`). La descarga ocurre dentro de la transacción del caso de
  uso, igual que las llamadas a la IA del proyecto; el tope de 30 s acota cuánto retiene una conexión.
