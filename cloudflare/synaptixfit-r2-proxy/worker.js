/**
 * Cloudflare Worker: synaptixfit-r2-proxy
 *
 * Este Worker actúa como proxy para subir/descargar/borrar archivos en
 * Cloudflare R2 (GIFs de ejercicios, imágenes, etc.).
 * También incluye un proxy para descargar calendarios .ics (evita CORS).
 *
 * DESPLIEGUE RECOMENDADO (vía Wrangler CLI):
 *   1. Instala Wrangler: npm i -g wrangler
 *   2. Autentícate: npx wrangler login
 *   3. Ajusta "bucket_name" en wrangler.jsonc al bucket R2 real
 *   4. Despliega: npx wrangler deploy
 *
 * ALTERNATIVA (Cloudflare Dashboard):
 *   1. Ve a https://dash.cloudflare.com
 *   2. Workers & Pages → synaptixfit-r2-proxy → Edit Code
 *   3. Settings → Bindings → Add R2 Bucket Binding:
 *      Variable name : R2_BUCKET
 *      R2 Bucket     : (el bucket de SynaptixFit)
 *   4. Pega este código completo y haz Deploy.
 *   5. Copia la URL del Worker (.workers.dev) al .env de la app Flutter.
 */

// ─── CORS helpers ────────────────────────────────────────────────────────────

const OPEN_CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Max-Age': '86400',
};

function getR2CorsHeaders(request) {
  const origin = request.headers.get('Origin');
  const allowedOrigins = [
    'https://synaptixfit.com',
  ];

  let allowedOrigin;
  if (origin && origin.startsWith('http://localhost')) {
    allowedOrigin = origin;
  } else if (allowedOrigins.includes(origin)) {
    allowedOrigin = origin;
  } else {
    allowedOrigin = allowedOrigins[0];
  }

  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Content-Length, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

// ─── HANDLER PRINCIPAL ───────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // ── /_proxy/ics — CORS abierto (*) ──────────────────────────────────────
    if (url.pathname === '/_proxy/ics') {
      if (request.method === 'OPTIONS') {
        return new Response(null, { status: 204, headers: OPEN_CORS });
      }

      if (request.method !== 'POST') {
        return new Response(JSON.stringify({ error: 'Usa POST' }), {
          status: 405,
          headers: { ...OPEN_CORS, 'Content-Type': 'application/json' },
        });
      }

      try {
        const body = await request.json();
        const targetUrl = body?.url;
        if (!targetUrl) {
          return new Response(JSON.stringify({ error: 'Falta campo "url"' }), {
            status: 400,
            headers: { ...OPEN_CORS, 'Content-Type': 'application/json' },
          });
        }

        const icsResp = await fetch(targetUrl, {
          headers: {
            'User-Agent': 'SynaptixFit/1.0 (Calendar Sync)',
            'Accept': 'text/calendar, text/plain, */*',
          },
          redirect: 'follow',
        });

        if (!icsResp.ok) {
          return new Response(JSON.stringify({
            error: `El servidor respondió ${icsResp.status}`,
            status: icsResp.status,
          }), {
            status: 502,
            headers: { ...OPEN_CORS, 'Content-Type': 'application/json' },
          });
        }

        const icsText = await icsResp.text();
        return new Response(icsText, {
          status: 200,
          headers: {
            ...OPEN_CORS,
            'Content-Type': 'text/plain; charset=utf-8',
          },
        });
      } catch (err) {
        console.error('[ics-proxy] Error:', err);
        return new Response(JSON.stringify({
          error: 'Error al descargar el calendario',
          detail: err.message,
        }), {
          status: 500,
          headers: { ...OPEN_CORS, 'Content-Type': 'application/json' },
        });
      }
    }

    // ── R2 — CORS restringido ───────────────────────────────────────────────
    const corsHeaders = getR2CorsHeaders(request);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    // Guarda: verificar que el binding R2_BUCKET existe antes de usarlo
    if (!env.R2_BUCKET) {
      console.error('[synaptixfit-r2-proxy] Binding R2_BUCKET no configurado en este Worker.');
      return new Response(JSON.stringify({
        error: 'Configuración incompleta del servidor',
        message: 'El binding R2_BUCKET no está configurado. Agrega el binding en Cloudflare Dashboard → Workers & Pages → synaptixfit-r2-proxy → Settings → Bindings, o despliega con `npx wrangler deploy` usando wrangler.jsonc.',
      }), {
        status: 503,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    try {
      const key = url.pathname.replace(/^\//, '');

      if (!key) {
        return new Response(JSON.stringify({ error: 'Ruta de archivo requerida' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

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
            'Cache-Control': 'public, max-age=31536000, immutable',
            'ETag': object.etag,
          },
        });
      }

      if (request.method === 'PUT') {
        const contentType = request.headers.get('Content-Type') ?? 'application/octet-stream';
        const body = await request.arrayBuffer();

        await env.R2_BUCKET.put(key, body, {
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

      if (request.method === 'DELETE') {
        await env.R2_BUCKET.delete(key);

        return new Response(JSON.stringify({ success: true, message: 'Archivo eliminado', key }), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      return new Response(JSON.stringify({ error: 'Método no permitido' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });

    } catch (error) {
      console.error('[synaptixfit-r2-proxy] Error:', error, error?.stack);
      return new Response(JSON.stringify({
        error: 'Error interno del servidor',
        message: error?.message ?? String(error ?? 'Error desconocido'),
        name: error?.name ?? 'Error',
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};
