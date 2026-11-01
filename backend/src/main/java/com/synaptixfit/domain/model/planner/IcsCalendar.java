package com.synaptixfit.domain.model.planner;

import java.nio.charset.StandardCharsets;
import java.time.DateTimeException;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Lectura y escritura del formato iCalendar (RFC 5545), limitado a lo que necesita el planificador:
 * VEVENT con UID, SUMMARY, DESCRIPTION, LOCATION, CATEGORIES, DTSTART, DTEND/DURATION y STATUS.
 *
 * <p>No expande reglas de recurrencia (RRULE): se importa solo la primera ocurrencia. Los calendarios
 * universitarios habituales publican cada sesión como un evento propio.
 */
public final class IcsCalendar {

    private static final DateTimeFormatter LOCAL_DATE_TIME = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss");
    private static final DateTimeFormatter UTC_STAMP =
            DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'").withZone(ZoneOffset.UTC);
    private static final LocalTime ALL_DAY_START = LocalTime.of(9, 0);

    private IcsCalendar() {
    }

    // ------------------------------------------------------------------ lectura

    /** Nombre del calendario ({@code X-WR-CALNAME}), o vacío si no lo trae. */
    public static String calendarName(String raw) {
        return header(raw, "X-WR-CALNAME");
    }

    /** Descripción del calendario ({@code X-WR-CALDESC}; p. ej. «Asignatura: Programación»), o vacío. */
    public static String calendarDescription(String raw) {
        return header(raw, "X-WR-CALDESC").replace("\\,", ",");
    }

    private static String header(String raw, String name) {
        for (String line : unfold(raw)) {
            if (line.toUpperCase(Locale.ROOT).startsWith(name)) {
                int colon = line.indexOf(':');
                return colon < 0 ? "" : line.substring(colon + 1).strip();
            }
        }
        return "";
    }

    /**
     * Inicio del curso académico que contiene {@code today}: el 1 de septiembre de ese año o del anterior. Lo
     * que terminó antes no se importa: los calendarios de los profesores acumulan cursos pasados (uno real
     * tenía 945 eventos desde 2012).
     */
    public static java.time.LocalDate academicYearStart(java.time.LocalDate today) {
        int year = today.getMonthValue() >= 9 ? today.getYear() : today.getYear() - 1;
        return java.time.LocalDate.of(year, 9, 1);
    }

    /**
     * Extrae los eventos del texto ICS. Los eventos sin DTSTART válido o cancelados se ignoran.
     *
     * @param defaultZone zona para horas «flotantes» o con TZID desconocido
     */
    public static List<IcsEvent> parse(String raw, ZoneId defaultZone) {
        List<IcsEvent> events = new ArrayList<>();
        Map<String, Property> current = null;
        for (String line : unfold(raw)) {
            String upper = line.toUpperCase(Locale.ROOT);
            if (upper.equals("BEGIN:VEVENT")) {
                current = new HashMap<>();
            } else if (upper.equals("END:VEVENT")) {
                if (current != null) {
                    toEvent(current, defaultZone).ifPresent(events::add);
                }
                current = null;
            } else if (current != null) {
                Property p = Property.parse(line);
                if (p != null) {
                    current.putIfAbsent(p.name(), p);
                }
            }
        }
        return events;
    }

    private static java.util.Optional<IcsEvent> toEvent(Map<String, Property> props, ZoneId zone) {
        Property dtStart = props.get("DTSTART");
        if (dtStart == null) {
            return java.util.Optional.empty();
        }
        Property status = props.get("STATUS");
        if (status != null && status.value().equalsIgnoreCase("CANCELLED")) {
            return java.util.Optional.empty();
        }
        try {
            boolean allDay = dtStart.isDateOnly();
            Instant start = dtStart.toInstant(zone);
            Instant end = null;
            Property dtEnd = props.get("DTEND");
            if (dtEnd != null && !allDay) {
                end = dtEnd.toInstant(zone);
            } else if (props.containsKey("DURATION") && !allDay) {
                end = start.plus(parseDuration(props.get("DURATION").value()));
            }
            if (end == null || !end.isAfter(start)) {
                end = start.plus(Duration.ofHours(1));
            }
            String summary = text(props.get("SUMMARY"));
            if (summary == null) {
                summary = "Sin título";
            }
            String uid = text(props.get("UID"));
            if (uid == null) {
                uid = fallbackUid(summary, dtStart.value());
            }
            return java.util.Optional.of(new IcsEvent(uid, summary, text(props.get("DESCRIPTION")),
                    text(props.get("LOCATION")), start, end, allDay, text(props.get("CATEGORIES"))));
        } catch (RuntimeException e) {
            // Fecha mal formada: el evento se ignora sin abortar la importación.
            return java.util.Optional.empty();
        }
    }

    /** Une las líneas plegadas (las que empiezan por espacio o tabulador continúan la anterior). */
    static List<String> unfold(String raw) {
        List<String> lines = new ArrayList<>();
        if (raw == null) {
            return lines;
        }
        StringBuilder current = null;
        for (String line : raw.split("\r?\n|\r")) {
            if (!line.isEmpty() && (line.charAt(0) == ' ' || line.charAt(0) == '\t')) {
                if (current != null) {
                    current.append(line, 1, line.length());
                }
                continue;
            }
            if (current != null) {
                lines.add(current.toString().strip());
            }
            current = new StringBuilder(line);
        }
        if (current != null) {
            lines.add(current.toString().strip());
        }
        return lines;
    }

    static Duration parseDuration(String value) {
        String v = value.strip().toUpperCase(Locale.ROOT);
        boolean negative = v.startsWith("-");
        v = v.replaceFirst("^[+-]", "");
        Duration d;
        if (v.matches("P\\d+W")) {
            d = Duration.ofDays(7L * Long.parseLong(v.substring(1, v.length() - 1)));
        } else {
            d = Duration.parse(v);
        }
        return negative ? d.negated() : d;
    }

    private static String text(Property p) {
        if (p == null || p.value().isBlank()) {
            return null;
        }
        return p.value().replace("\\n", "\n").replace("\\N", "\n").replace("\\,", ",")
                .replace("\\;", ";").replace("\\\\", "\\").strip();
    }

    static String fallbackUid(String summary, String dtStart) {
        int hash = 0;
        for (byte b : (summary + dtStart).getBytes(StandardCharsets.UTF_8)) {
            hash = 31 * hash + b;
        }
        return "sxf-" + Integer.toHexString(hash);
    }

    /** Propiedad de contenido: {@code NOMBRE;PARAM=valor:valor}. */
    private record Property(String name, Map<String, String> params, String value) {

        static Property parse(String line) {
            int colon = indexOfValueSeparator(line);
            if (colon <= 0) {
                return null;
            }
            String[] head = line.substring(0, colon).split(";");
            Map<String, String> params = new HashMap<>();
            for (int i = 1; i < head.length; i++) {
                int eq = head[i].indexOf('=');
                if (eq > 0) {
                    params.put(head[i].substring(0, eq).toUpperCase(Locale.ROOT),
                            head[i].substring(eq + 1).replace("\"", ""));
                }
            }
            return new Property(head[0].toUpperCase(Locale.ROOT), params, line.substring(colon + 1));
        }

        /** Primer ':' fuera de comillas (los valores de parámetros pueden llevar ':'). */
        private static int indexOfValueSeparator(String line) {
            boolean quoted = false;
            for (int i = 0; i < line.length(); i++) {
                char c = line.charAt(i);
                if (c == '"') {
                    quoted = !quoted;
                } else if (c == ':' && !quoted) {
                    return i;
                }
            }
            return -1;
        }

        boolean isDateOnly() {
            return "DATE".equalsIgnoreCase(params.get("VALUE")) || value.strip().matches("\\d{8}");
        }

        Instant toInstant(ZoneId defaultZone) {
            String v = value.strip();
            if (isDateOnly()) {
                LocalDate date = LocalDate.parse(v.substring(0, 8), DateTimeFormatter.BASIC_ISO_DATE);
                return date.atTime(ALL_DAY_START).atZone(zoneFor(defaultZone)).toInstant();
            }
            if (v.toUpperCase(Locale.ROOT).endsWith("Z")) {
                return LocalDateTime.parse(v.substring(0, 15), LOCAL_DATE_TIME).toInstant(ZoneOffset.UTC);
            }
            return LocalDateTime.parse(v.substring(0, 15), LOCAL_DATE_TIME).atZone(zoneFor(defaultZone)).toInstant();
        }

        private ZoneId zoneFor(ZoneId defaultZone) {
            String tzid = params.get("TZID");
            if (tzid == null) {
                return defaultZone;
            }
            try {
                return ZoneId.of(tzid);
            } catch (DateTimeException e) {
                return defaultZone;
            }
        }
    }

    // ------------------------------------------------------------------ escritura

    /** Exporta la línea de tiempo como calendario iCalendar (instantes en UTC). */
    public static String render(List<TimelineItem> items, Instant stamp) {
        StringBuilder out = new StringBuilder();
        appendLine(out, "BEGIN:VCALENDAR");
        appendLine(out, "VERSION:2.0");
        appendLine(out, "PRODID:-//SynaptixFit//Planner//ES");
        appendLine(out, "CALSCALE:GREGORIAN");
        appendLine(out, "X-WR-CALNAME:SynaptixFit");
        for (TimelineItem item : items) {
            appendLine(out, "BEGIN:VEVENT");
            appendLine(out, "UID:" + item.kind().name().toLowerCase(Locale.ROOT) + "-" + item.id() + "@synaptixfit");
            appendLine(out, "DTSTAMP:" + UTC_STAMP.format(stamp));
            appendLine(out, "DTSTART:" + UTC_STAMP.format(item.start()));
            if (item.kind() == TimelineItem.Kind.BLOCK) {
                appendLine(out, "DTEND:" + UTC_STAMP.format(item.end()));
            }
            appendLine(out, "SUMMARY:" + escape(item.title()));
            if (item.location() != null) {
                appendLine(out, "LOCATION:" + escape(item.location()));
            }
            String category = item.kind() == TimelineItem.Kind.BLOCK
                    ? item.blockType().code() : item.deadlineType().name().toLowerCase(Locale.ROOT);
            appendLine(out, "CATEGORIES:" + escape(category));
            if (item.subjectName() != null) {
                appendLine(out, "DESCRIPTION:" + escape(item.subjectName()));
            }
            if (item.completed()) {
                appendLine(out, "STATUS:CONFIRMED");
            }
            appendLine(out, "END:VEVENT");
        }
        appendLine(out, "END:VCALENDAR");
        return out.toString();
    }

    static String escape(String text) {
        return text.replace("\\", "\\\\").replace(";", "\\;").replace(",", "\\,").replace("\r\n", "\\n")
                .replace("\n", "\\n");
    }

    /** Pliega las líneas a 75 octetos (RFC 5545 §3.1) y termina en CRLF. */
    private static void appendLine(StringBuilder out, String line) {
        byte[] bytes = line.getBytes(StandardCharsets.UTF_8);
        if (bytes.length <= 75) {
            out.append(line).append("\r\n");
            return;
        }
        int count = 0;
        int limit = 75;
        StringBuilder chunk = new StringBuilder();
        for (int i = 0; i < line.length(); ) {
            int cp = line.codePointAt(i);
            int size = new String(Character.toChars(cp)).getBytes(StandardCharsets.UTF_8).length;
            if (count + size > limit) {
                out.append(chunk).append("\r\n ");
                chunk.setLength(0);
                count = 0;
                limit = 74;
            }
            chunk.appendCodePoint(cp);
            count += size;
            i += Character.charCount(cp);
        }
        out.append(chunk).append("\r\n");
    }
}
