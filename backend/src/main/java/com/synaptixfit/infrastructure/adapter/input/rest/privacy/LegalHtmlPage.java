package com.synaptixfit.infrastructure.adapter.input.rest.privacy;

import com.synaptixfit.domain.model.privacy.LegalBlock;
import com.synaptixfit.domain.model.privacy.LegalDocument;
import com.synaptixfit.domain.model.privacy.LegalDocumentKind;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Pinta un {@link LegalDocument} como página web pública (ADR 0034): la que enlaza Google Play. Sin scripts ni
 * recursos externos, legible en cualquier navegador y con modo oscuro. Todo el texto se escapa.
 */
final class LegalHtmlPage {

    /** Rutas públicas de nginx para cada documento. */
    static final Map<LegalDocumentKind, String> PUBLIC_PATHS = Map.of(
            LegalDocumentKind.PRIVACY, "/privacidad",
            LegalDocumentKind.TERMS, "/condiciones",
            LegalDocumentKind.ACCOUNT_DELETION, "/eliminar-cuenta");

    private static final Pattern LINKS = Pattern.compile(
            "(https://[\\w.\\-/?=&%#]+[\\w/])|([\\w.+\\-]+@[\\w\\-]+(?:\\.[\\w\\-]+)+)");

    private LegalHtmlPage() {
    }

    static String render(LegalDocument doc) {
        boolean english = "en".equals(doc.language());
        StringBuilder body = new StringBuilder();
        boolean inList = false;
        for (LegalBlock block : doc.blocks()) {
            if (block.type() != LegalBlock.Type.BULLET && inList) {
                body.append("</ul>\n");
                inList = false;
            }
            switch (block.type()) {
                case HEADING -> body.append("<h2>").append(inline(block.text())).append("</h2>\n");
                case PARAGRAPH -> body.append("<p>").append(inline(block.text())).append("</p>\n");
                case BULLET -> {
                    if (!inList) {
                        body.append("<ul>\n");
                        inList = true;
                    }
                    body.append("<li>").append(inline(block.text())).append("</li>\n");
                }
            }
        }
        if (inList) {
            body.append("</ul>\n");
        }

        String path = PUBLIC_PATHS.get(doc.kind());
        String other = english ? path + "?lang=es" : path + "?lang=en";
        String otherLabel = english ? "Leer en español" : "Read in English";
        StringBuilder nav = new StringBuilder();
        for (LegalDocumentKind k : LegalDocumentKind.values()) {
            String label = switch (k) {
                case PRIVACY -> english ? "Privacy policy" : "Política de privacidad";
                case TERMS -> english ? "Terms of use" : "Condiciones de uso";
                case ACCOUNT_DELETION -> english ? "Delete your account" : "Eliminar tu cuenta";
            };
            String href = PUBLIC_PATHS.get(k) + (english ? "?lang=en" : "");
            nav.append(k == doc.kind() ? "<span aria-current=\"page\">" + escape(label) + "</span>"
                    : "<a href=\"" + href + "\">" + escape(label) + "</a>").append(" · ");
        }
        nav.setLength(nav.length() - 3);
        String versionLabel = (english ? "Version of " : "Versión del ") + escape(doc.version());

        return """
                <!doctype html>
                <html lang="%s">
                <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <title>%s · SynaptixFit</title>
                <style>
                :root{color-scheme:light dark;--bg:#ffffff;--fg:#1c1b1f;--muted:#5f5c66;--line:#e3e1e8;--link:#3f6212}
                @media (prefers-color-scheme:dark){:root{--bg:#141317;--fg:#e8e6ec;--muted:#b4b1bb;--line:#2e2c33;--link:#bef264}}
                body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.6 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
                main{max-width:720px;margin:0 auto;padding:32px 16px 64px}
                h1{font-size:1.75rem;line-height:1.25;margin:0 0 8px}
                h2{font-size:1.2rem;margin:32px 0 8px}
                p,li{margin:8px 0}
                a{color:var(--link)}
                nav,.meta{color:var(--muted);font-size:.95rem}
                nav{border-bottom:1px solid var(--line);padding-bottom:16px;margin-bottom:24px}
                </style>
                </head>
                <body>
                <main>
                <nav>%s · <a href="%s" lang="%s">%s</a></nav>
                <h1>%s</h1>
                <p class="meta">SynaptixFit · %s</p>
                %s</main>
                </body>
                </html>
                """.formatted(escape(doc.language()), escape(doc.title()), nav, other, english ? "es" : "en",
                otherLabel, escape(doc.title()), versionLabel, body);
    }

    /** Página sencilla para un documento que no existe (respuesta 404 de la ruta HTML). */
    static String notFound(String language) {
        boolean english = language != null && language.toLowerCase(java.util.Locale.ROOT).startsWith("en");
        String title = english ? "Page not found" : "Página no encontrada";
        String text = english ? "This document does not exist. You can read the privacy policy instead."
                : "Este documento no existe. Puedes leer la política de privacidad.";
        String href = PUBLIC_PATHS.get(LegalDocumentKind.PRIVACY) + (english ? "?lang=en" : "");
        String link = english ? "Privacy policy" : "Política de privacidad";
        return """
                <!doctype html>
                <html lang="%s">
                <head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
                <title>%s · SynaptixFit</title>
                <style>body{margin:0;font:16px/1.6 system-ui,sans-serif}main{max-width:720px;margin:0 auto;padding:32px 16px}</style>
                </head>
                <body><main><h1>%s</h1><p>%s</p><p><a href="%s">%s</a></p></main></body>
                </html>
                """.formatted(english ? "en" : "es", title, title, text, href, link);
    }

    /** Escapa el texto y convierte en enlaces las direcciones web y los correos. */
    private static String inline(String text) {
        String escaped = escape(text);
        Matcher m = LINKS.matcher(escaped);
        StringBuilder out = new StringBuilder();
        while (m.find()) {
            String found = m.group();
            String href = m.group(1) != null ? found : "mailto:" + found;
            m.appendReplacement(out, Matcher.quoteReplacement("<a href=\"" + href + "\">" + found + "</a>"));
        }
        m.appendTail(out);
        return out.toString();
    }

    private static String escape(String s) {
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
}
