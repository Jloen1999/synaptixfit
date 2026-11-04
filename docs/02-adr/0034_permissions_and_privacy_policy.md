# ADR 0034 — Permisos del móvil explicados y política de privacidad pública

- **Estado:** aceptado
- **Fecha:** 2026-11-04

## Contexto

La app va a publicarse en Google Play, que exige:

- una política de privacidad en una URL pública;
- una URL desde la que pedir el borrado de la cuenta;
- que los permisos se pidan cuando hacen falta.

Hasta ahora:

1. Solo se pedía el permiso de notificaciones, al activar los recordatorios, y nada explicaba antes para qué servía. La cámara (fotografiar apuntes, ADR 0040) se abría sin preguntar: si estaba denegada, solo había un aviso, sin camino para arreglarlo.
2. Android 14 niega por defecto las alarmas exactas (`SCHEDULE_EXACT_ALARM`).
3. No había política de privacidad, ni condiciones de uso, ni constancia de que alguien las hubiera aceptado.

El usuario decidió que el responsable de los datos y el correo de contacto se configuren en el servidor, sin escribirlos nunca en el código.

## Decisión

### Permisos

- **Qué se pide:** notificaciones, alarmas exactas y cámara (`DevicePermission`), con `permission_handler` solo en `data/` (el test de arquitectura lo impide en `domain/` y `presentation/`). En web y escritorio no hay nada que pedir (`notApplicable`).
- **Al configurar la app:** paso «Permisos» (`/permissions-intro`), una vez por dispositivo. Cada permiso dice para qué sirve y qué pasa sin él, con «Permitir» y «Ahora no».
  - Se abre al terminar el onboarding o, a quien ya lo hizo, desde Inicio, después de comprobar el onboarding.
  - Volver atrás cuenta como «Continuar».
  - «Permitir» las notificaciones usa el mismo caso de uso que el interruptor «Recordatorios · En este móvil»: así también los activa y no se vuelven a ofrecer.
- **Justo antes de la acción:** `ensureDevicePermission`, antes de fotografiar apuntes o activar los recordatorios.
  - Si ya está permitido, no enseña nada.
  - Si no, abre una hoja corta que explica, con «Permitir» (o «Abrir ajustes del móvil» si el sistema ya no vuelve a preguntar) y una alternativa sin permiso (la galería).
  - Al volver de los ajustes del sistema se comprueba solo (`AppLifecycleListener`).
- **Ajustes › Permisos del móvil:** el estado de cada uno y su acción.
- **Android:** `CAMERA` declarado, con `android.hardware.camera` opcional para que Play no oculte la app en móviles sin cámara. Con el permiso declarado, `image_picker` también lo pide si hiciera falta.
- **Sin alarmas exactas:** los recordatorios ya son inexactos; solo el fin del Pomodoro intenta ser exacto y, sin permiso, también es inexacto. Llega igual, con unos minutos de margen.

### Política de privacidad y condiciones

- **Una sola fuente de los textos:** `backend/src/main/resources/legal/<documento>.<idioma>.md` (privacidad, condiciones, borrado de cuenta; español y, como cortesía, inglés).
  - Son texto sencillo: `#` título, `##` sección, `-` punto.
  - Llevan marcadores (`{{RESPONSABLE}}`, `{{CORREO}}`, `{{VERSION}}`, `{{APP_URL}}`) que rellena `LegalDocument.compose`.
  - El responsable y el correo salen de `LEGAL_CONTROLLER_NAME` y `LEGAL_CONTACT_EMAIL`. Sin ellos, el texto dice «pendiente de indicar»: mejor un hueco honesto que un dato inventado.
  - Lo que se dice está comprobado en el código: qué se manda a DeepSeek (nunca nombre ni correo, ni datos del ciclo), que las fotos de apuntes no se guardan, qué proveedores hay.
- **Público y sin sesión:**
  - `GET /api/v1/legal/{document}`, en JSON, para la app.
  - `GET /api/v1/legal/{document}/page`, en HTML sin scripts y con una CSP estricta, para la web.
  - nginx publica `/privacidad`, `/condiciones` y `/eliminar-cuenta` (y `/privacy`, `/terms`, `/delete-account` en inglés), que son las URL para Google Play.
- **Aceptación con constancia:** `aceptaciones_legales` (V1043) guarda una fila por versión aceptada y fecha (responsabilidad proactiva del RGPD). `LegalTerms.CURRENT_VERSION` es la fecha de la versión vigente, y cambiarla obliga a aceptar de nuevo.
  - **Registro con correo:** casilla obligatoria «He leído y acepto…» con enlaces. El alta (`POST /auth/register`) lleva `acceptedLegalVersion` y el servidor guarda la aceptación **en la misma transacción** que la cuenta: no hay cuenta sin constancia. Las apps antiguas no la envían y se les pide al entrar.
  - **Al entrar en la app**, si hace falta (entrar con Google por primera vez, o versión nueva), el router lleva a la pantalla completa `/legal-acceptance` **antes** que al onboarding o al paso «Permisos» (`LegalAcceptanceBloc`, una sola instancia que consulta el router). No se salta con «atrás»; la otra salida es «Cerrar sesión». Sin conexión no bloquea: se vuelve a comprobar al entrar.
  - Se acepta la versión que la persona ha visto (`PUT /me/legal-acceptance` con esa versión). Si cambió mientras la leía, el servidor responde `LEGAL_VERSION_OUTDATED` (409) y la app enseña la nueva.
- **Borrado y exportación:** las aceptaciones salen en la exportación y se borran al anonimizar y al eliminar la cuenta. Al vaciar el contenido se conservan, porque la cuenta sigue en uso.

### Consentimiento aparte para los datos de salud

- El registro diario (sueño, estrés, energía, agujetas, dolor) son datos de salud (art. 9 RGPD). Aceptar la política no basta: hace falta un consentimiento **explícito y separado**.
- `consentimientos_salud` (V1044) guarda cuándo se dio y, si se retiró, cuándo. Sin él, `PUT /training/check-ins/today` responde `HEALTH_CONSENT_REQUIRED` (422) y no guarda nada.
- La app lo pide la primera vez que alguien usa el registro (completo o rápido) con una hoja que explica para qué se usa, una casilla y «Dar permiso y seguir» (`ensureHealthConsent`). Se consulta y se retira en Ajustes › Privacidad y datos (`GET`/`PUT`/`DELETE /me/health-consent`).
- Al retirarlo se borra el registro de hoy (el único que usan la adaptación de la sesión y la generación de rutinas) y, si la persona lo elige, todos los anteriores.
- «Mi ciclo» mantiene su propio consentimiento al activarlo (ADR 0033).
- La exportación que pide un administrador no lleva el registro diario ni el ciclo: solo la de su dueño (`UserDataExportPort.Requester`).

## Consecuencias

- Las URL públicas existen desde el despliegue. Hasta que se configuren `LEGAL_CONTROLLER_NAME` y `LEGAL_CONTACT_EMAIL` en Coolify, dicen «pendiente», y así **no** se debe publicar en Google Play.
- Cambiar un texto legal es un despliegue. Si el cambio es de fondo, hay que subir `CURRENT_VERSION` para que todos lo acepten de nuevo.
- **iOS:** `permission_handler` necesita las macros `PERMISSION_CAMERA=1` y `PERMISSION_NOTIFICATIONS=1` en el `Podfile`, que se genera en la primera compilación en macOS. Los textos de `Info.plist` ya están.
- Los textos los ha redactado el equipo de desarrollo. Antes de publicar conviene que los revise alguien con formación jurídica: bases legales, transferencias internacionales (DeepSeek) y edad mínima.
- Requisitos de Google Play y respuestas de sus formularios: `docs/06-ops/google-play.md`.
- Quien ya tenía registros diarios antes de V1044 tendrá que dar el permiso la próxima vez que haga el registro; sus registros anteriores se conservan y puede borrarlos al retirarlo.
- Si `APP_URL` no está configurada, las frases de los textos que la citan se quitan enteras en lugar de quedar rotas.
