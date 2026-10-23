package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.planner.InvalidBlockTimeRangeException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;

/**
 * Convierte el patrón semanal de clases (lunes 9:00-11:00…) en ocurrencias fechadas entre el inicio
 * y el fin de clases del semestre.
 *
 * <p>Cada ocurrencia es un bloque {@code clase} no fijo pero inamovible ({@code es_hito_inamovible})
 * con un {@code ics_uid} sintético estable ({@code ai-<asignatura>-<yyyyMMdd>-<HHmm>}): volver a
 * escanear el mismo horario actualiza los bloques en lugar de duplicarlos.
 */
public final class WeeklyPatternMaterializer {

    /** Tope de semanas por clase, por si las fechas del semestre son absurdas. */
    public static final int MAX_WEEKS = 30;
    private static final DateTimeFormatter DAY = DateTimeFormatter.BASIC_ISO_DATE;

    private WeeklyPatternMaterializer() {
    }

    /** Resultado de la materialización. */
    public record Result(List<CalendarBlock> blocks, int classes, List<String> unmatchedSubjects) {
    }

    public static Result materialize(UUID userId, List<ScheduleEntry> entries, List<SubjectRef> subjects,
                                     LocalDate semesterStart, LocalDate semesterEnd, PlannerZone zone,
                                     Supplier<UUID> ids, Instant now) {
        List<CalendarBlock> blocks = new ArrayList<>();
        Set<String> unmatched = new LinkedHashSet<>();
        Set<String> seenUids = new LinkedHashSet<>();
        for (ScheduleEntry entry : entries) {
            if (entry.dayOfWeek() < 1 || entry.dayOfWeek() > 7 || entry.start() == null || entry.end() == null) {
                continue;
            }
            Optional<SubjectRef> subject = SubjectMatcher.match(entry.subjectCode(), entry.subjectName(), subjects);
            if (subject.isEmpty() && entry.subjectName() != null && !entry.subjectName().isBlank()) {
                unmatched.add(entry.subjectName().strip());
            }
            String key = slug(entry.subjectCode() != null && !entry.subjectCode().isBlank()
                    ? entry.subjectCode() : entry.subjectName());
            String topics = entry.classKind() == null ? entry.subjectName()
                    : entry.subjectName() + (entry.classKind() == ClassKind.THEORY ? " (Teoría)" : " (Práctica)");

            int delta = (entry.dayOfWeek() - semesterStart.getDayOfWeek().getValue() + 7) % 7;
            LocalDate date = semesterStart.plusDays(delta);
            for (int week = 0; !date.isAfter(semesterEnd) && week < MAX_WEEKS; week++, date = date.plusWeeks(1)) {
                TimeRange range;
                try {
                    range = new TimeRange(zone.at(date, entry.start()), zone.at(date, entry.end()));
                } catch (InvalidBlockTimeRangeException e) {
                    break;
                }
                String uid = "ai-" + key + "-" + date.format(DAY) + "-"
                        + String.format("%02d%02d", entry.start().getHour(), entry.start().getMinute());
                if (!seenUids.add(uid)) {
                    continue;
                }
                CalendarBlock.Details details = new CalendarBlock.Details(
                        subject.map(SubjectRef::id).orElse(null), topics,
                        entry.room() == null || entry.room().isBlank() ? null : entry.room(),
                        Priority.MEDIUM, false, entry.classKind(), null, null, null, null, null, null);
                blocks.add(CalendarBlock.builder()
                        .id(ids.get())
                        .userId(userId)
                        .range(range)
                        .dayOfWeek(entry.dayOfWeek())
                        .type(ActivityType.CLASS)
                        .details(details)
                        .fixed(false)
                        .immovable(true)
                        .icsUid(uid)
                        .createdAt(now)
                        .build());
            }
        }
        return new Result(blocks, entries.size(), List.copyOf(unmatched));
    }

    static String slug(String text) {
        String normalized = SubjectMatcher.normalize(text).replace(' ', '-');
        return normalized.isEmpty() ? "clase" : normalized;
    }
}
