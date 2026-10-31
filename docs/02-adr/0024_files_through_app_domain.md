# 0024. Archivos y medios a través del dominio de la app

* **Estado:** Aprobado
* **Fecha:** 2026-10-31
* **Autores:** SynaptixFit

## Contexto
El cliente hablaba directamente con Cloudflare R2:
- subía y descargaba los archivos (apuntes, plan docente) con URL firmadas de `<cuenta>.r2.cloudflarestorage.com`;
- mostraba los vídeos e imágenes de los ejercicios desde la dirección pública de desarrollo `pub-….r2.dev`.

En España, Movistar, Vodafone, Orange, DIGI y MásMóvil bloquean durante los partidos de LaLiga IP compartidas de
Cloudflare. El 31 de octubre de 2026 las de R2 estaban bloqueadas y las del dominio de la app no. En el móvil:
- no se veían los vídeos;
- subir un plan docente fallaba con «sin conexión».

Además, `r2.dev` tiene límite de peticiones, no pasa por la caché y Cloudflare no lo recomienda en producción.

## Decisión
* **Todo pasa por `synaptixfit.jloenit.dev`.** El nginx del cliente (en el servidor, fuera de España) reenvía:
  - `/storage/` → R2 (`R2_UPSTREAM`), para las subidas y descargas firmadas. El backend firma como siempre y
    cambia solo el origen de la URL (`R2_PROXY_BASE_URL`). nginx reenvía la misma ruta con el mismo `Host`, así
    que la firma sigue valiendo. Sin registro de acceso, porque la consulta lleva la firma.
  - `/media/ejercicios/` → bucket público (`MEDIA_UPSTREAM`), solo esa carpeta. El backend sirve las URL de los
    ejercicios con `MEDIA_PUBLIC_BASE_URL` aunque la BD guarde `pub-….r2.dev`, sin migrar datos. Cloudflare las
    guarda en caché (`Cache-Control: public, max-age=604800`).
* **El DNS de R2 se resuelve en cada petición** (resolver de Docker). Si R2 no está configurado, nginx arranca
  igual.
* **`R2_PUBLIC_BASE_URL` sigue vacío:** los archivos de los usuarios no se publican; se descargan con URL
  firmada.
* En local, con las variables vacías, todo funciona como antes (directo a R2).

## Consecuencias
* **Positivas:**
  - funciona con cualquier operador y sin pasos manuales en Cloudflare;
  - el cliente ya no necesita CORS en R2;
  - los vídeos quedan en la caché de Cloudflare.
* **Negativas:**
  - las subidas y las descargas de archivos de usuario consumen ancho de banda del VPS;
  - los vídeos solo lo consumen cuando no están en la caché.
* **A vigilar:**
  - si se bloquearan las IP del propio dominio, la app entera quedaría afectada, no solo los archivos;
  - con mucho tráfico de vídeo, conectar un dominio propio al bucket y apuntar ahí `MEDIA_PUBLIC_BASE_URL`.
