# Autenticación

| Endpoint | Uso |
|---|---|
| `POST /api/v1/auth/register` | Alta con `email`, `password` (≥ 8, letras y números) y `fullName` |
| `POST /api/v1/auth/login` | Email y contraseña |
| `POST /api/v1/auth/google` | `idToken` obtenido con Google Sign-In en el cliente |
| `POST /api/v1/auth/refresh` | Renueva la sesión con el `refreshToken` |
| `POST /api/v1/auth/logout` | Revoca el `refreshToken` |
| `GET/PATCH /api/v1/me` | Cuenta del usuario autenticado |
| `PUT /api/v1/me/password` | Cambio de contraseña (revoca las demás sesiones) |

Las cuatro primeras devuelven `{ accessToken, accessTokenExpiresAt, refreshToken, tokenType, user }`.

## Tokens

- **Acceso:** JWT HS256, 15 min, `sub` = id del usuario, `role` = `USER` | `ADMIN`. Se envía como `Authorization: Bearer <token>`.
- **Refresco:** valor aleatorio de 30 días; en base de datos solo se guarda su hash SHA-256. Cada refresco lo **rota**; reutilizar uno ya rotado revoca todas las sesiones del usuario (detección de robo).
- El cliente guarda ambos en el almacenamiento seguro del sistema y renueva automáticamente ante un 401.

## Google

El backend verifica la firma del ID token con las claves públicas de Google, el emisor y la audiencia (`GOOGLE_CLIENT_IDS`). Si el email ya existe se vincula la cuenta; si no, se crea. En web el cliente usa el botón oficial de Google.

## Administración

Todo `/api/v1/admin/**` exige `role = ADMIN`. El rol se asigna desde el panel de administración (o, el primero, con SQL: `update usuarios set rol = 'admin' where email = '...'`).
