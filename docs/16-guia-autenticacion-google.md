# Guía Técnica: Implementación de Autenticación con Google (Flutter + Supabase)

## Objetivo
Proporcionar instrucciones precisas y deterministas para la implementación de la autenticación nativa de Google en una aplicación Flutter utilizando Supabase como backend (BaaS). Este documento está diseñado para ser consumido por un agente de Inteligencia Artificial especializado en desarrollo de software, asegurando una integración libre de errores y con experiencia nativa en iOS y Android.

---

## Arquitectura de la Solución
Para garantizar la mejor experiencia de usuario en dispositivos móviles y evitar los bloqueos de "WebView", se debe implementar el flujo nativo (**Native OAuth Flow**). 
1. Se utiliza el paquete `google_sign_in` para obtener los tokens directamente del sistema operativo (Google Play Services en Android y SafariViewController en iOS).
2. Se pasan el `idToken` y el `accessToken` al SDK de Supabase (`supabase_flutter`) mediante el método `signInWithIdToken()`.

---

## Fase 1: Configuración en Google Cloud Console (GCP)

1. **Creación del Proyecto y Pantalla de Consentimiento:**
   - Crear un proyecto en [Google Cloud Console](https://console.cloud.google.com/).
   - Configurar la **Pantalla de consentimiento de OAuth** (OAuth consent screen) como "Externa" (o "Interna" si es solo para la organización).
   - Añadir el dominio de Supabase (`<TU_PROYECTO_SUPABASE>.supabase.co`) a los dominios autorizados.

2. **Creación de Credenciales (OAuth Client IDs):**
   Se necesitan **tres (3)** Client IDs distintos, todos bajo el mismo proyecto de GCP.

   * **A. Web Client ID (Fundamental para Supabase y Android):**
     - Tipo de aplicación: Aplicación Web.
     - Orígenes autorizados en JS: `https://<TU_PROYECTO_SUPABASE>.supabase.co`
     - URI de redirección autorizados: `https://<TU_PROYECTO_SUPABASE>.supabase.co/auth/v1/callback`
     - *Nota:* Guardar el `Client ID` y el `Client Secret`.

   * **B. Android Client ID:**
     - Tipo de aplicación: Android.
     - Nombre del paquete: (ej. `com.synaptixfit.app` - revisar `android/app/build.gradle`).
     - Huella digital de certificado SHA-1: Obtenerla ejecutando `./gradlew signingReport` en la carpeta `android/` del proyecto.
     - *Nota:* Es imperativo generar un SHA-1 para `debug` y otro para `release` en producción.

   * **C. iOS Client ID:**
     - Tipo de aplicación: iOS.
     - ID del paquete (Bundle ID): (ej. `com.synaptixfit.app` - revisar `ios/Runner.xcodeproj/project.pbxproj`).
     - *Nota:* Guardar el `Client ID` y el `iOS URL scheme` (Reverse Client ID).

---

## Fase 2: Configuración en Supabase Dashboard

1. Ir a **Authentication > Providers > Google**.
2. Activar el proveedor Google.
3. Completar los campos con las credenciales del **Web Client ID** obtenidas en el paso 1.A:
   - **Client ID:** `<WEB_CLIENT_ID>`
   - **Client Secret:** `<WEB_CLIENT_SECRET>`
4. Activar la opción **"Skip nonce checks"** (Requerido para la autenticación nativa en iOS con `google_sign_in`).
5. Guardar la configuración.

---

## Fase 3: Configuración del Cliente Flutter

### 3.1. Dependencias (`pubspec.yaml`)
Asegurarse de tener instaladas las últimas versiones estables:
```yaml
dependencies:
  supabase_flutter: ^2.0.0 # Verificar versión actual
  google_sign_in: ^6.2.1
```

### 3.2. Configuración Nativa en iOS (`ios/Runner/Info.plist`)
Se debe registrar el `REVERSED_CLIENT_ID` (obtenido en el paso 1.C de GCP) para que la app pueda manejar el callback de autenticación.

```xml
<!-- Añadir dentro del <dict> principal en ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- REVERSED_CLIENT_ID de GCP (iOS Client ID) -->
            <string>com.googleusercontent.apps.XXXXXXXXXXXX-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx</string>
        </array>
    </dict>
</array>
```

### 3.3. Configuración Nativa en Android
Si el paso 1.B (Android Client ID + SHA-1) se completó correctamente, **no** se requiere configuración adicional en el manifiesto ni en Gradle para el paquete `google_sign_in`.

---

## Fase 4: Implementación en Dart (Código)

Para asegurar la escalabilidad, la lógica debe encapsularse en un repositorio o servicio de autenticación.

### Código de Ejecución de Auth
```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// IDs configurados en Google Cloud Console
  /// Se recomienda usar variables de entorno (.env) en producción
  static const String webClientId = 'TU_WEB_CLIENT_ID.apps.googleusercontent.com'; // Paso 1.A
  static const String iosClientId = 'TU_IOS_CLIENT_ID.apps.googleusercontent.com'; // Paso 1.C

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      // Inicia el flujo nativo
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        return null;
      }

      // Obtiene los tokens de Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('No se pudieron obtener los tokens de Google.');
      }

      // Intercambia los tokens de Google por una sesión en Supabase
      return await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      // Registrar error en el sistema de telemetría / logs
      rethrow;
    }
  }

  Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await _supabaseClient.auth.signOut();
  }
}
```

---

## Consideraciones Críticas para la IA Desarrolladora

1. **Jerarquía de Client IDs:**
   - Android usa el `serverClientId` (que es el **Web** Client ID) por debajo del capó para obtener el `idToken`. No se debe pasar el Android Client ID directamente en el constructor de `GoogleSignIn`.
   - iOS requiere explícitamente el `clientId` (que es el **iOS** Client ID) en el constructor de `GoogleSignIn`.
2. **Ambientes (Dev/Prod):**
   - El error `ApiException: 10` en Android ocurre en el 99% de los casos debido a que el SHA-1 usado en GCP no coincide con la firma del APK/AAB actual. Se debe recordar configurar tanto el SHA-1 de `debug.keystore` como el de la llave de producción en GCP.
3. **Manejo de Estado:**
   - Tras recibir el `AuthResponse`, Supabase emitirá automáticamente un evento `AuthState.signedIn`. El `Stream` de `Supabase.instance.client.auth.onAuthStateChange` debe ser utilizado (junto a Riverpod u otro gestor de estado) para actualizar la UI del router global (GoRouter u otro).
4. **Protección RLS:**
   - La tabla de usuarios (`public.usuarios`) debe tener un trigger configurado para insertar una fila automáticamente cuando un nuevo usuario se registre a través del esquema `auth.users` de Supabase (esto ya está implementado en la migración 0004 de SynaptixFit).

---

## Troubleshooting: Migración de Entorno (Nuevo SHA-1)

Cuando se migra el proyecto a otra máquina o entorno (por ejemplo, de Windows a WSL/Linux, o a otro equipo), se genera un **nuevo debug keystore** con un SHA-1 diferente. Si no se actualiza, el login de Google fallará con `ApiException: 10` en Android.

### Síntomas
- `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10, null, null)`
- El login nativo de Google abre la ventana de selección de cuenta pero falla al regresar a la app
- Funcionaba correctamente en el entorno anterior

### Solución paso a paso

#### 1. Obtener el nuevo SHA-1 del keystore del nuevo entorno

```bash
# Linux / WSL / macOS
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

Si `keytool` no está en el PATH, usar la ruta completa:

```bash
# Con JAVA_HOME definido
$JAVA_HOME/bin/keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

Alternativa con `gradlew` (funciona en cualquier SO):

```bash
cd app/android
./gradlew signingReport
```

#### 2. Registrar el nuevo SHA-1 en **DOS lugares** (ambos obligatorios)

| # | Consola | Ruta |
|---|---------|------|
| 1 | **Firebase Console** | Project Settings → Android app → SHA certificate fingerprints → **Añadir huella digital** |
| 2 | **Google Cloud Console** | APIs & Services → Credentials → OAuth 2.0 Client ID (tipo Android) → **SHA-1 certificate fingerprint** |

⚠️ **Importante:** No basta con Firebase Console. Google Cloud Console tiene su propia copia del SHA-1 en el OAuth Client ID de tipo Android. Ambos deben coincidir con el nuevo keystore.

#### 3. Re-descargar `google-services.json`

Tras añadir el SHA-1 en Firebase Console:
1. Ir a Firebase Console → Project Settings → Android app
2. Descargar `google-services.json` actualizado
3. Reemplazar `app/android/app/google-services.json` con el nuevo archivo

#### 4. Limpiar y reconstruir

```bash
cd app
flutter clean
flutter pub get
flutter run
```

---

## Troubleshooting: Loopback Server para Escritorio Linux

Cuando se ejecuta la app Flutter en escritorio Linux (no web), el flujo de autenticación con Google usa un **servidor loopback HTTP** en lugar de WebView o redirección de navegador. Este mecanismo es necesario porque los entornos de escritorio Linux no tienen un navegador embebido estándar como Android (Chrome Custom Tabs) o iOS (SFSafariViewController).

### Arquitectura del Loopback Server

El proyecto usa dos archivos con compilación condicional:

| Archivo | Plataforma | Propósito |
|---------|-----------|-----------|
| `app/lib/features/auth/infrastructure/loopback_auth_io.dart` | Linux, macOS, Windows (`dart:io`) | Implementación real: crea un `HttpServer` en `InternetAddress.loopbackIPv4` que escucha en un puerto aleatorio y espera el callback de Google OAuth |
| `app/lib/features/auth/infrastructure/loopback_auth_stub.dart` | Web | Stub que lanza `UnimplementedError` (en web se usa redirección estándar, no loopback) |

**Importación condicional en `auth_repository.dart`:**
```dart
import 'loopback_auth_stub.dart'
    if (dart.library.io) 'loopback_auth_io.dart';
```

### Funcionamiento del Servidor

1. Al iniciar el flujo de Google Sign-In, se llama a `iniciarServidorLoopback(puerto: 0)`.
2. El sistema operativo asigna un puerto aleatorio disponible en `127.0.0.1`.
3. Se construye una URL de redirección `http://127.0.0.1:{puerto}/callback` y se pasa a Google OAuth como `redirect_uri`.
4. Google abre el navegador del sistema, el usuario autoriza, y Google redirige al `localhost:{puerto}/callback`.
5. El servidor loopback recibe la petición en `/callback`, captura el `Uri` (con los tokens en los query params), devuelve una página HTML de confirmación y cierra.
6. La app extrae los tokens del `Uri` y continúa con `signInWithIdToken()`.

### Síntomas de Fallo en Linux

- El login de Google abre el navegador pero nunca retorna a la app (se queda esperando).
- Error en consola: `No se pudo iniciar servidor loopback: ...`
- Timeout después de 2 minutos sin respuesta.

### Causas Comunes y Soluciones

#### 1. Puerto en uso

Si otro proceso está usando puertos en el rango efímero, el loopback no puede bindear:

```bash
# Verificar puertos en uso
ss -tlnp | grep 127.0.0.1

# Solución: cerrar procesos que ocupen puertos o reiniciar
```

#### 2. Firewall bloqueando loopback

En algunas distribuciones Linux, `iptables` o `ufw` pueden bloquear conexiones loopback:

```bash
# Verificar reglas de loopback
sudo iptables -L INPUT -v -n | grep 127.0.0.1

# Asegurar que loopback está permitido (debería estarlo por defecto)
sudo iptables -A INPUT -i lo -j ACCEPT
```

#### 3. Navegador no redirige a localhost

Algunos navegadores (especialmente Firefox con configuraciones de privacidad estrictas) bloquean redirecciones a `localhost`:

- **Chrome/Chromium:** Funciona correctamente con `http://127.0.0.1:*`.
- **Firefox:** Verificar `network.proxy.allow_hijacking_localhost` en `about:config`.
- **Solución:** Usar Chromium como navegador predeterminado durante el desarrollo, o configurar Firefox para permitir `localhost`.

#### 4. WSL sin soporte de loopback

Si se ejecuta Flutter desde WSL (Windows Subsystem for Linux) pero el navegador está en Windows:

```bash
# WSL2 usa una IP virtual, no 127.0.0.1 real
# Solución: ejecutar la app con `flutter run -d linux` desde una terminal nativa de Linux,
# no desde WSL, o configurar el reenvío de puertos de WSL a Windows.
```

#### 5. Timeout de 2 minutos

El servidor loopback tiene un timeout de 2 minutos (`Duration(minutes: 2)`). Si el usuario tarda más de 2 minutos en completar la autenticación en el navegador, el `Completer` se completa con `null` y el flujo falla:

```dart
// En loopback_auth_io.dart
callback: completer.future.timeout(
  const Duration(minutes: 2),
  onTimeout: () => null,
),
```

**Solución:** Reintentar el login. La ventana de 2 minutos es suficiente para el 99% de los casos.

#### 6. Dependencia de `dart:io`

En entornos que no tienen `dart:io` (como Flutter Web), se usa automáticamente el stub. No es necesario configurar nada — la compilación condicional maneja esto:

```dart
// El stub lanza UnimplementedError si se invoca en web
Future<LoopbackServer> iniciarServidorLoopback({int puerto = 0}) async {
  throw UnimplementedError(
      'El servidor loopback no esta disponible en esta plataforma');
}
```

### Verificación Manual

Para verificar que el loopback server funciona correctamente en Linux:

```bash
# En una terminal, iniciar un servidor de prueba
python3 -c "import http.server; http.server.HTTPServer(('127.0.0.1', 8765), http.server.SimpleHTTPRequestHandler).serve_forever()"

# En otra terminal, verificar que responde
curl http://127.0.0.1:8765/
```

Si esto funciona, el loopback server de Flutter también debería funcionar, ya que ambos usan el mismo mecanismo de `127.0.0.1`.