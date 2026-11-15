# ADR 0052 — Foto de perfil desde la galería o la cámara

- **Fecha:** 2026-11-15
- **Estado:** aceptado

## Contexto

Fase 1B del plan de mejoras. «Editar cuenta» pedía la **dirección de internet** de la foto de perfil, escrita a mano.
Nadie sabe hacerlo desde el móvil. El servidor solo guardaba ese texto.

Los archivos de los usuarios están en un bucket **privado** de R2 (`R2_PUBLIC_BASE_URL` vacío, ADR 0024) y se
descargan con URL firmada, que caduca. Pero la foto de perfil se pinta en muchas listas (amigos, comunidad, «Con
amigos», Inicio) con una imagen normal, sin cabecera de sesión, y con una dirección estable.

## Decisión

- **API** (en `/api/v1/me`, donde ya vive la cuenta):
  - `POST /me/avatar` (multipart, campo `file`, una imagen) → devuelve la cuenta (`AccountResponse`).
  - `DELETE /me/avatar` → quita la foto (también la de Google) y devuelve la cuenta.
  - `GET /avatars/{usuario}/{foto}.jpg` → **público** (como una imagen cualquiera), `image/jpeg`,
    `Cache-Control: public, max-age=86400`. Solo sirve la foto **actual** de esa cuenta: una anterior o borrada da
    404 (`AVATAR_NOT_FOUND`) sin tocar R2.
- **Casos de uso** (`AvatarService`): `UploadAvatarUseCase`, `RemoveAvatarUseCase` y `ReadAvatarUseCase`. Reglas en
  `ProfilePhoto` (dominio):
  - formato por **firma** (JPEG, PNG o WEBP, con `ImageHeader`), no por nombre ni tipo declarado
    (`AVATAR_INVALID_IMAGE`); como mucho 10 MB y 40 MP (`AVATAR_TOO_LARGE`);
  - `AvatarImagePort` (adaptador `AvatarImageAdapter`, con `ImagePixels` del ADR 0051): abre la foto reducida,
    **recorta el cuadrado central**, la reduce a **512 × 512** y la gira según su orientación EXIF (recortar antes de
    girar da el mismo cuadrado y mueve menos píxeles); JPEG sin metadatos (ni GPS);
  - se guarda con `FileStoragePort.put` (nuevo) en `avatares/<usuario>/<uuid>.jpg`: un nombre nuevo en cada cambio,
    así ninguna caché enseña la foto anterior; después se **vuelve a leer la cuenta** (abrir y subir la foto tarda
    segundos y, sin transacción, guardar la copia leída al principio pisaría la XP, la racha o una baja hechas
    entretanto), se apunta la dirección y, por último, se borra la anterior **con mejor esfuerzo** (un fallo deja un archivo huérfano, nunca una cuenta sin foto válida). Solo se
    borra lo que es de la app y de esa cuenta (`ProfilePhoto.storedKey`): nunca una foto de Google.
  - Sin R2 configurado: `STORAGE_UNAVAILABLE` (503, código existente) y la cuenta no cambia.
- **Dirección:** `${AVATAR_BASE_URL}/api/v1/avatars/...`; vacía o sin poner, `APP_PUBLIC_URL`, porque el nginx del cliente
  reenvía `/api/` al backend por el dominio de la app (sirve con cualquier operador, ADR 0024). La foto pasa por el
  backend (unos 40 KB) y Cloudflare la guarda un día en caché.
- **Sin transacción** en estos casos de uso: cada uno hace una sola escritura en la base de datos y el resto es abrir
  la imagen y hablar con R2.
- **Borrado de datos:** al anonimizar o eliminar la cuenta, `UserDataEraser` vacía la carpeta entera
  `avatares/<usuario>/` (`FileStoragePort.deleteFolder`, nuevo: lista por prefijo y borra en lotes), así se van también
  las fotos sueltas (un borrado que falló, dos subidas a la vez). Al vaciar el contenido no, porque la cuenta la sigue
  usando. Un fallo de R2 se cuenta en el informe y no bloquea el borrado.
- **Cliente:** en «Editar cuenta» el avatar es el botón «Cambiar foto» / «Poner foto» y abre una hoja con «Elegir de
  la galería», «Hacer una foto» (solo Android e iOS; cámara delantera, permiso con `ensureDevicePermission`) y
  «Quitar foto» (si hay; se confirma). La foto elegida se ve antes en un círculo (`BoxFit.cover`: el mismo cuadrado
  central que recorta el servidor) con «Usar esta foto», «Elegir otra» y «Cancelar»; se guarda al momento
  (`ProfilePhotoBloc`) y pasa la cuenta a `SessionBloc`. Ya no hay campo de dirección. El selector de fotos es uno
  (`widgets/photo_pick.dart`), compartido con el escaneo de apuntes. Sin dependencias nativas nuevas.
- **Privacidad:** la política (versión `2026-11-16`) dice cómo se guarda, quién la ve y cuándo se borra.

## Consecuencias

- **Positivas:** poner foto es elegirla o hacerla; la foto guardada es pequeña, derecha y sin datos de ubicación.
- **Negativas:** cada foto no cacheada pasa por el backend (lectura de R2); con mucho tráfico, valorar un bucket
  público solo para avatares.
- **A vigilar:** la dirección es pública para quien la tenga (como el nombre, ya visible para quien puede encontrar
  a la persona); tras quitar la foto, una copia en caché puede verse hasta un día.
- El `PATCH /me` con `avatarUrl` sigue existiendo por compatibilidad (versiones antiguas de la app), pero ya no puede
  cambiar ni quitar una foto subida a la app: eso solo con `/me/avatar`, que también borra el archivo.
- Si cambia el dominio de la app, las direcciones guardadas seguirán con el anterior: harían falta una migración de
  datos o guardar solo la ruta y componerla al responder. `ProfilePhoto.storedKey` no mira el dominio, así que borrar
  y servir siguen funcionando.
- `image_picker` se usa en `presentation/widgets/photo_pick.dart` (ya se usaba así en el escaneo): abre una pantalla del
  sistema y devuelve bytes, sin estado ni permisos propios; los permisos siguen en `data/` (`ensureDevicePermission`).
