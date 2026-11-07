# Publicar en Google Play

Guía para publicar la app Android de SynaptixFit. Se basa en lo que hace de verdad el código el 4 de noviembre de 2026 (ADR 0034). Antes de rellenar un formulario, comprueba que nada haya cambiado: si una respuesta ya no cuadra con el código, la que manda es el código.

## 1. Antes de empezar

| Requisito | Estado | Detalle |
|---|---|---|
| Política de privacidad pública | Lista al desplegar | `https://synaptixfit.jloenit.dev/privacidad` (en inglés, `/privacy`) |
| URL para pedir el borrado de la cuenta | Lista al desplegar | `https://synaptixfit.jloenit.dev/eliminar-cuenta` (en inglés, `/delete-account`) |
| Responsable y correo de privacidad | **Pendiente** | Variables `LEGAL_CONTROLLER_NAME` y `LEGAL_CONTACT_EMAIL` en Coolify. Sin ellas, las páginas dicen «pendiente de indicar» y **no se debe publicar** |
| Revisión jurídica de los textos | Recomendada | `backend/src/main/resources/legal/` (bases legales, transferencias a DeepSeek, edad mínima) |
| Paquete AAB firmado con clave de subida | **Pendiente** | Hoy `android/app/build.gradle.kts` firma `release` con la clave de depuración, así que no vale para Play (punto 5) |
| `targetSdk` | 36 | Lo fija Flutter (`flutter.targetSdkVersion`); Play exige el último o el anterior |
| `minSdk` | 24 (Android 7) | |
| Id de la app | `com.jloen.synaptixfit` | No se puede cambiar después de publicar |
| Versión | `pubspec.yaml` → `version: 1.0.0+1` | El número tras `+` (`versionCode`) debe subir en cada subida |

## 2. Prueba cerrada (cuentas personales)

Las cuentas de desarrollador **personales creadas después del 13 de noviembre de 2023** deben pasar antes por una prueba cerrada, que se puede abrir en cuanto exista el primer AAB firmado:

- al menos **12 testers** apuntados;
- durante **14 días seguidos**;
- después se solicita el acceso a producción.

Las cuentas de organización (con D-U-N-S) y las personales más antiguas no la necesitan. Consejos:

- Invita a 15 o 16 personas por si alguna se borra.
- Sigue subiendo versiones durante la prueba.
- Apunta qué te comentan: Google lo pregunta al pedir el acceso.

## 3. Permisos que declara la app

| Permiso | Para qué | Cuándo se pide |
|---|---|---|
| `INTERNET` | Hablar con la API | No se pide (normal) |
| `POST_NOTIFICATIONS` | Recordatorios de estudio, entreno, repasos y entregas | Paso «Permisos» al empezar, o al activar los recordatorios, siempre con explicación previa |
| `RECEIVE_BOOT_COMPLETED` | Reprogramar los recordatorios tras reiniciar el móvil | No se pide (normal) |
| `SCHEDULE_EXACT_ALARM` | Que el aviso de fin del Pomodoro llegue a su hora | Paso «Permisos» o Ajustes › Permisos. Sin él, los avisos son inexactos y llegan igual. La app **no** declara `USE_EXACT_ALARM`, que Play reserva a despertadores y calendarios |
| `CAMERA` | Fotografiar apuntes en papel para pasarlos a texto | Justo antes de abrir la cámara, con explicación y la galería como alternativa. `android.hardware.camera` es opcional |

La galería usa el selector de fotos del sistema y no necesita permiso de almacenamiento.

## 4. Formulario «Seguridad de los datos»

**¿Recoge o comparte datos?** Sí. **¿Cifrado en tránsito?** Sí (HTTPS, a través de Cloudflare). **¿Se puede pedir el borrado?** Sí: en la app (Perfil › Ajustes › Privacidad y datos › Eliminar mi cuenta), en la web y por correo. URL: `/eliminar-cuenta`.

«Compartir» en Play excluye a los proveedores que tratan datos por encargo nuestro: el servidor en OVH, Cloudflare R2, DeepSeek y Resend. Por eso no se marca ningún dato como **compartido**. La política sí los nombra.

| Tipo de dato (Play) | ¿Se recoge? | Obligatorio | Para qué (Play) | Notas |
|---|---|---|---|---|
| Información personal › Nombre | Sí | Sí | Funcionalidad de la app, gestión de la cuenta | Nombre del perfil |
| Información personal › Dirección de correo | Sí | Sí | Gestión de la cuenta, comunicaciones de la app | Inicio de sesión, recuperar contraseña, resumen semanal opcional |
| Información personal › IDs de usuario | Sí | Sí | Gestión de la cuenta | Id interno; id de Google si se entra con Google |
| Información personal › Otra información | Sí | No | Funcionalidad, personalización | Universidad, carrera, curso, asignaturas, horario y fecha de nacimiento (opcional, ADR 0036: edad para las kcal y las propuestas, y felicitar el cumpleaños; nunca en el perfil público; se borra al vaciar o eliminar la cuenta y sale en la exportación de la persona) |
| Salud y forma física › Información de salud | Sí | No | Funcionalidad, personalización | Registro diario (sueño, estrés, agujetas, zonas con dolor) y «Mi ciclo» (opcional, con consentimiento explícito) |
| Salud y forma física › Información de forma física | Sí | No | Funcionalidad, personalización | Rutinas, sesiones, series, pesos, actividades, sexo, peso y altura del perfil de bienestar (la edad se calcula con la fecha de nacimiento o es la que se dio antes) |
| Fotos y vídeos › Fotos | Sí | No | Funcionalidad | Fotos de apuntes: se leen para pasarlas a texto y **no se guardan** (marcar «tratado de forma efímera») |
| Archivos y documentos | Sí | No | Funcionalidad | Archivos que sube la persona (Cloudflare R2) |
| Mensajes › Otros mensajes en la app | Sí | No | Funcionalidad | Publicaciones y comentarios de la comunidad |
| Actividad en la app › Interacciones | Sí | Sí | Funcionalidad, analíticas propias | Progreso, XP, rachas e insignias (sin herramientas de analítica de terceros) |
| Actividad en la app › Otro contenido generado | Sí | No | Funcionalidad | Apuntes, preguntas de repaso y respuestas |
| Información y rendimiento de la app › Registros de fallos | No | — | — | No hay SDK de fallos |
| Identificadores del dispositivo | No | — | — | No se usa id de publicidad |
| Ubicación exacta | Sí | No | Funcionalidad de la app (grabar carreras: distancia, ritmo, desnivel y mapa de la ruta); opcional | Solo mientras se graba una carrera, con la app en uso o con el servicio en primer plano y su aviso fijo; nunca `ACCESS_BACKGROUND_LOCATION`. La ruta es privada, se cifra en tránsito, se borra con la carrera o la cuenta y se puede pedir su borrado (ADR 0037) |

No hay publicidad ni venta de datos.

## 5. Declaraciones de la consola

- **Aplicación de salud** (Contenido de la app › Apps de salud): sí trata datos de salud. Casos de uso:
  - fitness y bienestar (entrenamiento y registro diario);
  - seguimiento del ciclo menstrual, opcional.

  No es un dispositivo médico ni da diagnósticos. Así lo dicen las condiciones y la pantalla «Mi ciclo».
- **Público objetivo:** mayores de 18, o como mínimo 16 o más (estudiantes universitarios). No está dirigida a menores. Las condiciones fijan un mínimo de 14 años, que es la edad de consentimiento en España.
- **Contenido generado por usuarios:** sí (comunidad). Hay denuncia de contenido y moderación por administradores.
- **Anuncios:** no.
- **Acceso a la app para la revisión:** crea una cuenta de prueba con correo y contraseña para el revisor. Nunca uses una cuenta real.
- **Clasificación de contenido:** cuestionario IARC. Sin violencia, sin apuestas, con interacción entre usuarios.

## 6. Firmar y compilar el AAB

1. Genera la clave de subida **fuera del repositorio**, en `%USERPROFILE%\.config\synaptixfit\`, con `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`. Guarda las contraseñas en un gestor y haz una copia de seguridad de la clave: sin ella no se puede actualizar la app.
2. Crea `android/key.properties` (excluido de git) apuntando a esa clave.
3. Cambia la firma `release` de `build.gradle.kts` para que la lea.
4. Activa la «Firma de apps de Google Play» (Play guarda la clave de la app y tú solo la de subida).
5. Compila con `flutter build appbundle --release --dart-define-from-file=<copia temporal de config con la API de producción>` y sube `build/app/outputs/bundle/release/app-release.aab`.

## Servicio en primer plano de tipo ubicación (ADR 0037)

Play Console › Contenido de la app › **Permisos de servicios en primer plano** pide justificar `FOREGROUND_SERVICE_LOCATION`:

- **Tipo:** `location` (servicio `GeolocatorLocationService` del paquete `geolocator`).
- **Qué hace la persona:** pulsa «Empezar a correr» para grabar una carrera, un paseo o una salida en bici con el GPS.
- **Por qué hace falta un servicio en primer plano:** la carrera debe seguir grabándose con la pantalla apagada y el móvil en el bolsillo; sin él, Android corta el GPS. Se para al pulsar «Pausar y salir», «Terminar» o «Descartar».
- **Qué ve la persona:** el aviso fijo «Grabando tu carrera · 3,2 km · 18:40» mientras dura.
- **Vídeo:** grabar de 20 a 30 s de la app: Entreno › Correr › «Empezar a correr» → permiso de ubicación con su explicación → pantalla apagada → aviso fijo → «Terminar».
- **Permisos declarados:** `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE` y `FOREGROUND_SERVICE_LOCATION`. **No** se declara `ACCESS_BACKGROUND_LOCATION`: la ubicación solo se usa con la app en uso o con el servicio en primer plano iniciado por la persona, así que no hace falta el formulario de ubicación en segundo plano.
