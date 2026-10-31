# 0022. Resumen semanal por correo con doble confirmación

* **Estado:** Aprobado
* **Fecha:** 2026-10-31
* **Autores:** SynaptixFit

## Contexto
Los avisos del móvil llegan solo si la app está instalada y con permiso. Un resumen semanal por correo recuerda
lo hecho y lo que viene a quien usa la web o tiene los avisos desactivados. El envío ya existe (Resend, ADR 0021).
El registro no verifica el correo: si bastara con activar una casilla, alguien podría hacer que otra persona
recibiera correos de nuestro dominio.

## Decisión
* **Opcional y con doble confirmación:** se activa en Ajustes › Notificaciones. Con una cuenta de Google (correo
  ya verificado por Google) queda activo; si no, queda pendiente y se manda un correo con un enlace para
  confirmarlo. Solo se guarda la huella del token de confirmación (`suscripciones_resumen_semanal`, V980), que
  caduca a los 7 días. Volver a pulsar no manda otro correo hasta pasados 10 minutos (y nginx limita la ruta),
  para que nadie use la app para inundar un buzón.
* **Baja con un clic:** cada resumen lleva un enlace para darse de baja y las cabeceras `List-Unsubscribe` y
  `List-Unsubscribe-Post` (la baja también funciona por POST, como la piden Gmail y otros). El token de baja se
  guarda tal cual porque va en todos los correos y solo sirve para darse de baja.
* **Contenido:** las cifras de la semana salen del mismo caso de uso que Inicio (`GetDashboardUseCase`): estudio,
  entrenamientos (con los planificados), bloques hechos y racha; y las entregas y exámenes de los 7 días
  siguientes. Una semana sin nada que contar no manda correo. El idioma es el de la app al activarlo.
* **Envío:** tarea programada el domingo cada hora de 19 a 23 (zona del planificador, `WEEKLY_EMAIL_CRON`). Cada
  suscripción recuerda la última semana enviada (`markSent` solo marca si sigue activa, para no resucitar una
  baja hecha durante el envío; es una actualización con su propia transacción, porque el envío no va en una):
  repetir la tarea o reiniciar el servidor no duplica correos, y si Resend falla
  se reintenta en la pasada siguiente. Cada envío lleva la cabecera `Idempotency-Key` `weekly/<usuario>/<lunes>`,
  así que un reintento tras un corte de red tampoco duplica. Los envíos van en fila (600 ms entre uno y otro,
  por el límite de peticiones de Resend), cada usuario por separado: un fallo no deshace ni frena a los demás y
  se registra cuántos fallaron.
* **Páginas de los enlaces:** HTML sencillo del backend en el idioma de la suscripción. Abrir el enlace (GET)
  solo muestra un botón; la acción se hace con POST. Así los analizadores de enlaces de los correos, que abren
  las URL solos, no confirman ni dan de baja a nadie. La baja por POST es idempotente (un enlace ya usado muestra
  la misma página). El nginx del cliente no registra esas rutas (el token va en la query) y las limita por IP.
* **Aceptado:** si un administrador cambia el correo de una cuenta, la suscripción sigue con el correo nuevo sin
  volver a confirmar (el cambio lo hace alguien de confianza).

## Consecuencias
* **Positivas:** quien no abre la app recibe un motivo para volver; respeta el consentimiento y la baja inmediata.
* **Negativas:** depende del cupo de Resend (100 correos al día en el plan gratuito): con más de 100 suscritos
  activos habría que pasar a un plan de pago o repartir el envío.
* **A vigilar:** la zona horaria es la del planificador para todos (la app es para España); si hubiera usuarios
  en otras zonas, guardar la suya en la suscripción.
