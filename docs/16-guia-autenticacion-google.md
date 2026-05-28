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