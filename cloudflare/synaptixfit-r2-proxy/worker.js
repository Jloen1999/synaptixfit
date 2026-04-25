/**
 * Cloudflare Worker: synaptixfit-r2-proxy
 *
 * Este Worker actúa como proxy para subir/descargar/borrar archivos en
 * Cloudflare R2 (GIFs de ejercicios, imágenes, etc.).
 *
 * IMPORTANTE: Este archivo es de REFERENCIA.
 * Copia y pega este código en Cloudflare Dashboard:
 *   https://dash.cloudflare.com
 *   → Workers & Pages → synaptixfit-r2-proxy → Edit Code
 *
 * CONFIGURACIÓN REQUERIDA EN CLOUDFLARE DASHBOARD:
 *   1. Crear Worker llamado "synaptixfit-r2-proxy"
 *   2. En Settings → Bindings → Add R2 Bucket Binding:
 *      Variable name : R2_BUCKET
 *      R2 Bucket     : (el bucket de SynaptixFit)
 *   3. Pegar este código y hacer Deploy.
 *   4. Copiar la URL del Worker (.workers.dev) al .env de la app Flutter.
 */

// ─── CORS ────────────────────────────────────────────────────────────────────

function getCorsHeaders(request) {
  const origin = request.headers.get('Origin');
  const allowedOrigins = [
    'http://localhost:5173',         // Desarrollo web local (Flutter web / Vite)
    'http://localhost:3000',         // Desarrollo alternativo
    'https://synaptixfit.com',       // Producción web (actualiza con tu dominio real)
  ];

  const allowedOrigin = allowedOrigins.includes(origin)
    ? origin
    : allowedOrigins[allowedOrigins.length - 1];

  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Content-Length, Authorization',
    'Access-Control-Max-Age': '86400', // 24 horas de caché preflight
  };
}

// ─── HANDLER PRINCIPAL ───────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const corsHeaders = getCorsHeaders(request);

    // Manejar preflight (OPTIONS) para CORS
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    try {
      // Extraer la key del objeto R2 desde el path
      // Ejemplo: /ejercicios/gifs/0001.gif → ejercicios/gifs/0001.gif
      const key = url.pathname.replace(/^\//, '');

      if (!key) {
        return new Response(JSON.stringify({ error: 'Ruta de archivo requerida' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // ── GET: Descargar archivo desde R2 ──────────────────────────────────
      if (request.method === 'GET') {
        const object = await env.R2_BUCKET.get(key);

        if (!object) {
          return new Response(JSON.stringify({ error: 'Archivo no encontrado' }), {
            status: 404,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        return new Response(object.body, {
          headers: {
            ...corsHeaders,
            'Content-Type': object.httpMetadata?.contentType ?? 'application/octet-stream',
            'Content-Length': object.size.toString(),
            'Cache-Control': 'public, max-age=31536000, immutable', // Caché de 1 año
            'ETag': object.etag,
          },
        });
      }

      // ── PUT: Subir archivo a R2 ───────────────────────────────────────────
      if (request.method === 'PUT') {
        const contentType = request.headers.get('Content-Type') ?? 'application/octet-stream';

        await env.R2_BUCKET.put(key, request.body, {
          httpMetadata: { contentType },
        });

        return new Response(JSON.stringify({
          success: true,
          key,
          url: `${url.origin}/${key}`,
        }), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // ── DELETE: Eliminar archivo de R2 ───────────────────────────────────
      if (request.method === 'DELETE') {
        await env.R2_BUCKET.delete(key);

        return new Response(JSON.stringify({ success: true, message: 'Archivo eliminado', key }), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Método no soportado
      return new Response(JSON.stringify({ error: 'Método no permitido' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });

    } catch (error) {
      // Nunca exponer stack traces en producción — útil solo en desarrollo
      console.error('[synaptixfit-r2-proxy] Error:', error);
      return new Response(JSON.stringify({
        error: 'Error interno del servidor',
        message: error.message,
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};
