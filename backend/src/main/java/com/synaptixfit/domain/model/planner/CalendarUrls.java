package com.synaptixfit.domain.model.planner;

import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Locale;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Convierte los enlaces de Google Calendar que se ven en el Campus Virtual (calendario incrustado
 * {@code …/calendar/embed?src=ID} o compartido {@code …/calendar/u/0?cid=BASE64}) en la dirección de su
 * ICS público ({@code https://calendar.google.com/calendar/ical/ID/public/basic.ics}). Así el estudiante puede
 * pegar el enlace tal cual lo encuentra. El resto de direcciones no cambian.
 */
public final class CalendarUrls {

    private static final Pattern GOOGLE_HOST = Pattern.compile("^(www\\.)?(calendar\\.)?google\\.com$");
    private static final Pattern PARAM = Pattern.compile("(?:^|&)(src|cid)=([^&]+)");

    private CalendarUrls() {
    }

    /** La dirección del ICS si es un enlace de Google Calendar reconocible; si no, la misma. */
    public static String normalize(String url) {
        if (url == null) {
            return null;
        }
        String value = url.strip();
        return googleCalendarId(value).map(CalendarUrls::googleIcs).orElse(value);
    }

    static String googleIcs(String calendarId) {
        return "https://calendar.google.com/calendar/ical/"
                + URLEncoder.encode(calendarId, StandardCharsets.UTF_8) + "/public/basic.ics";
    }

    private static Optional<String> googleCalendarId(String url) {
        java.net.URI uri;
        try {
            uri = java.net.URI.create(url);
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
        String host = uri.getHost() == null ? "" : uri.getHost().toLowerCase(Locale.ROOT);
        String path = uri.getRawPath() == null ? "" : uri.getRawPath();
        String query = uri.getRawQuery();
        // Ya es un ICS (…/ical/…/basic.ics) o no es de Google Calendar: se deja como está.
        if (!GOOGLE_HOST.matcher(host).matches() || !path.startsWith("/calendar") || path.contains("/ical/")
                || query == null) {
            return Optional.empty();
        }
        Matcher m = PARAM.matcher(query);
        while (m.find()) {
            String value = URLDecoder.decode(m.group(2), StandardCharsets.UTF_8).strip();
            if (value.isEmpty()) {
                continue;
            }
            if (m.group(1).equals("src")) {
                return Optional.of(value);
            }
            // «cid» es el id en Base64 (a veces sin relleno).
            try {
                String decoded = new String(Base64.getUrlDecoder().decode(value.replace('+', '-').replace('/', '_')),
                        StandardCharsets.UTF_8).strip();
                if (decoded.contains("@") || decoded.endsWith("calendar.google.com")) {
                    return Optional.of(decoded);
                }
            } catch (IllegalArgumentException e) {
                // No era Base64: se prueba con el siguiente parámetro.
            }
        }
        return Optional.empty();
    }
}
