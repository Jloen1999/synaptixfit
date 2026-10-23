package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.planner.InvalidBlockTimeRangeException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Reglas deterministas de las sugerencias de planificación: el plan heurístico (cuando la IA no está
 * disponible) y el saneado de las propuestas de la IA.
 */
public final class WeekPlanSuggestions {

    static final LocalTime STUDY_FROM = LocalTime.of(16, 0);
    static final LocalTime SPORT_FROM = LocalTime.of(18, 0);
    static final LocalTime DAY_LIMIT = LocalTime.of(22, 0);
    private static final int[] SPORT_DAYS = {1, 3, 5, 2, 4};

    private WeekPlanSuggestions() {
    }

    /** Propuesta con su origen. */
    public record Suggestion(List<SuggestedBlock> blocks, Source source) {

        public double studyHours() {
            return blocks.stream().filter(b -> b.type() == ActivityType.STUDY)
                    .mapToLong(b -> java.time.Duration.between(b.start(), b.end()).toMinutes()).sum() / 60.0;
        }

        public int sportSessions() {
            return (int) blocks.stream().filter(b -> b.type() == ActivityType.SPORT).count();
        }
    }

    /** Origen de la propuesta. */
    public enum Source {
        AI,
        HEURISTIC
    }

    /**
     * Plan heurístico heredado: estudio repartido de lunes a viernes desde las 16:00 (1-2 bloques al
     * día), deporte a las 18:00 en lunes, miércoles, viernes, martes y jueves (por ese orden). Las
     * asignaturas con entregas más próximas van primero. Respeta los huecos ocupados y no propone nada
     * en el pasado ni después de las 22:00.
     */
    public static List<SuggestedBlock> heuristic(PlanningInbox inbox, PlannerZone zone, Instant now) {
        List<SuggestedBlock> result = new ArrayList<>();
        List<CalendarBlock> busy = new ArrayList<>(inbox.busyBlocks());
        List<SubjectRef> subjects = prioritizedSubjects(inbox);
        double hoursPerDay = inbox.studyHoursTarget() / 5.0;
        int subjectCursor = 0;
        if (hoursPerDay >= 0.5) {
            int blocksPerDay = Math.max(1, Math.min(2, (int) Math.ceil(hoursPerDay / 1.5)));
            long minutes = Math.round(Math.min(inbox.maxStudyBlockMinutes(), hoursPerDay * 60 / blocksPerDay) / 30.0) * 30;
            minutes = Math.max(TimeRange.MIN_MINUTES, minutes);
            for (int day = 0; day < 5; day++) {
                LocalDate date = inbox.weekStart().plusDays(day);
                for (int b = 0; b < blocksPerDay; b++) {
                    Optional<TimeRange> slot = freeSlot(date, STUDY_FROM, minutes, busy, zone, now);
                    if (slot.isEmpty()) {
                        break;
                    }
                    SubjectRef subject = subjects.isEmpty() ? null : subjects.get(subjectCursor++ % subjects.size());
                    result.add(new SuggestedBlock(ActivityType.STUDY, slot.get().start(), slot.get().end(),
                            subject == null ? null : subject.id(), subject == null ? null : subject.name(),
                            null, null, "Repaso general"));
                    busy.add(placeholder(slot.get()));
                }
            }
        }
        RoutineRef routine = inbox.routines().isEmpty() ? null : inbox.routines().get(0);
        int sessions = 0;
        for (int i = 0; i < SPORT_DAYS.length && sessions < inbox.sportSessionsTarget(); i++) {
            LocalDate date = inbox.weekStart().plusDays(SPORT_DAYS[i] - 1L);
            Optional<TimeRange> slot = freeSlot(date, SPORT_FROM, inbox.minutesPerSportSession(), busy, zone, now);
            if (slot.isPresent()) {
                result.add(new SuggestedBlock(ActivityType.SPORT, slot.get().start(), slot.get().end(), null, null,
                        routine == null ? null : routine.id(), routine == null ? null : routine.name(), null));
                busy.add(placeholder(slot.get()));
                sessions++;
            }
        }
        result.sort(Comparator.comparing(SuggestedBlock::start));
        return result;
    }

    /**
     * Descarta las propuestas inválidas de la IA: fuera de la semana, en el pasado, de menos de 30
     * minutos, que acaban después de las 22:00 o que se solapan con lo ya ocupado o entre sí. Resuelve
     * asignaturas y rutinas por id conocido.
     */
    public static List<SuggestedBlock> sanitize(List<SuggestedBlock> proposed, PlanningInbox inbox,
                                                PlannerZone zone, Instant now) {
        Instant weekStart = zone.weekStart(inbox.weekStart());
        Instant weekEnd = zone.weekEnd(inbox.weekStart());
        Map<UUID, SubjectRef> subjects = inbox.subjects().stream()
                .collect(Collectors.toMap(SubjectRef::id, Function.identity(), (a, b) -> a));
        Map<UUID, RoutineRef> routines = inbox.routines().stream()
                .collect(Collectors.toMap(RoutineRef::id, Function.identity(), (a, b) -> a));
        List<CalendarBlock> busy = new ArrayList<>(inbox.busyBlocks());
        List<SuggestedBlock> accepted = new ArrayList<>();
        for (SuggestedBlock s : proposed.stream().sorted(Comparator.comparing(SuggestedBlock::start)).toList()) {
            if (s.type() != ActivityType.STUDY && s.type() != ActivityType.SPORT) {
                continue;
            }
            TimeRange range;
            try {
                range = new TimeRange(s.start(), s.end());
            } catch (InvalidBlockTimeRangeException e) {
                continue;
            }
            boolean inWeek = !range.start().isBefore(weekStart) && !range.end().isAfter(weekEnd);
            boolean sameDay = zone.localDate(range.start()).equals(zone.localDate(range.end()));
            boolean beforeLimit = !zone.localTime(range.end()).isAfter(DAY_LIMIT);
            if (!inWeek || !sameDay || !beforeLimit || range.start().isBefore(now)
                    || !ScheduleConflicts.overlapping(range, busy, null).isEmpty()) {
                continue;
            }
            SubjectRef subject = s.subjectId() == null ? null : subjects.get(s.subjectId());
            RoutineRef routine = s.routineId() == null ? null : routines.get(s.routineId());
            accepted.add(new SuggestedBlock(s.type(), range.start(), range.end(),
                    subject == null ? null : subject.id(), subject == null ? s.subjectName() : subject.name(),
                    routine == null ? null : routine.id(), routine == null ? s.routineName() : routine.name(),
                    s.topic()));
            busy.add(placeholder(range));
        }
        return accepted;
    }

    private static List<SubjectRef> prioritizedSubjects(PlanningInbox inbox) {
        Map<UUID, Instant> nearest = inbox.deadlines().stream()
                .filter(d -> d.subjectId() != null && !d.completed())
                .collect(Collectors.toMap(Deadline::subjectId, Deadline::dueAt, (a, b) -> a.isBefore(b) ? a : b));
        return inbox.subjects().stream()
                .sorted(Comparator.comparing((SubjectRef s) -> nearest.getOrDefault(s.id(), Instant.MAX))
                        .thenComparing(s -> -s.perceivedDifficulty()))
                .toList();
    }

    private static Optional<TimeRange> freeSlot(LocalDate date, LocalTime from, long minutes,
                                                List<CalendarBlock> busy, PlannerZone zone, Instant now) {
        Instant start = zone.at(date, from);
        if (start.isBefore(now)) {
            start = now;
        }
        return ScheduleConflicts.firstFreeSlot(minutes, start, zone.at(date, DAY_LIMIT), busy);
    }

    private static CalendarBlock placeholder(TimeRange range) {
        return CalendarBlock.builder().id(UUID.randomUUID()).userId(new UUID(0, 0)).range(range).build();
    }
}
