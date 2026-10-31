# 0021. Recuperar la contraseña por correo con Resend

* **Estado:** Aprobado
* **Fecha:** 2026-10-31
* **Autores:** SynaptixFit

## Contexto
Quien olvida la contraseña no tiene forma de volver a entrar: solo puede cambiarla con la sesión abierta. Hace
falta un correo con un enlace. El backend no enviaba correos; el propietario creó una cuenta de Resend con el
dominio `notifications.jloenit.dev` verificado (región eu-west-1).

## Decisión
* **Proveedor:** Resend por su API REST (`POST /emails`), desde el adaptador `ResendEmailClient`. Clave en
  `RESEND_API_KEY` (secreta), remitente en `MAIL_FROM` y base de los enlaces en `APP_PUBLIC_URL`. Sin clave no se
  envía nada (se registra un aviso), así que el desarrollo y los tests no mandan correos reales.
* **Puertos:** el dominio solo conoce `PasswordResetMailerPort` («envía el enlace a este correo»). El texto, el
  idioma (el de la petición, ADR 0017) y el enlace los pone el adaptador, como los prompts de la IA.
* **Enlace:** token de 256 bits; en la BD solo su huella SHA-256 (`restablecimientos_contrasena`, V970). Caduca a
  los 30 minutos, sirve una vez y pedir otro anula los anteriores. El token va en el fragmento
  (`/#/reset-password?token=…`): el navegador no lo envía al servidor y no queda en los registros de los proxies.
* **Sin enumerar cuentas:** `POST /auth/password-reset` responde siempre 202 con el mismo cuerpo. El correo sale
  en segundo plano y solo tras confirmarse la transacción (si hay rollback no sale): la llamada a Resend no se nota
  en el tiempo de respuesta. Queda una diferencia de milisegundos (con cuenta se escriben filas), aceptada porque
  el registro ya revela si un correo existe (`AUTH_EMAIL_ALREADY_REGISTERED`).
* **Correo sin el nombre del usuario:** el nombre lo escribe quien se registra, sin verificar el correo; con él se
  podría colar texto engañoso («entra en …») en un correo de nuestro dominio. El saludo es genérico.
* **Límites:** 3 correos por usuario y hora (más se ignoran en silencio), para que nadie llene el buzón de otro, y
  5 peticiones por minuto e IP en el nginx del cliente, para que nadie agote el cupo diario de Resend con muchas
  cuentas.
* **Un solo uso de verdad:** el token se lee con bloqueo de fila (`SELECT … FOR UPDATE`): dos confirmaciones a la
  vez se hacen una detrás de otra y la segunda ya lo ve usado.
* **Al cambiarla:** `POST /auth/password-reset/confirm` valida primero la contraseña nueva (si es débil, el enlace
  sigue sirviendo), la guarda y **cierra todas las sesiones**: quien pidió el enlace puede no ser quien tiene la
  sesión abierta. Las cuentas solo de Google también pueden usarlo para ponerse una contraseña.
* **Al terminar, la app cierra también la sesión del dispositivo** (si la había) y lleva al inicio de sesión.

## Consecuencias
* **Positivas:** recuperación sin intervención del administrador; un proveedor más se cambia tocando un adaptador.
* **Negativas:** depende de Resend (plan gratuito: 100 correos al día y 3.000 al mes); si Resend falla, el correo
  no llega y solo queda en el registro del servidor.
* **Aceptado:**
  - los tokens de acceso ya emitidos siguen valiendo hasta que caducan (`JWT_ACCESS_TTL`, 15 minutos);
  - el límite por hora cuenta y luego inserta, así que varias peticiones simultáneas pueden pasar de 3;
  - quien conozca un correo puede anular el enlace pendiente pidiendo otro.
* **Configuración:** sin `RESEND_API_KEY` la API sigue respondiendo 202 pero no sale ningún correo; al arrancar se
  avisa en el registro, igual que si `APP_PUBLIC_URL` no es `https://`. En producción ambas son obligatorias.
* **A vigilar:** si se añade el resumen semanal por correo, necesitará consentimiento y un enlace para darse de
  baja.
