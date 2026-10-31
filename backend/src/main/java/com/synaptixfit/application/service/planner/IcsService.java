package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.ExportIcsUseCase;
import com.synaptixfit.application.port.input.planner.ImportGeneralCalendarUseCase;
import com.synaptixfit.application.port.input.planner.ImportIcsUseCase;
import com.synaptixfit.domain.exception.planner.IcsUrlMissingException;
import com.synaptixfit.domain.exception.planner.InvalidIcsUrlException;
import com.synaptixfit.domain.exception.planner.PlannerSubjectNotFoundException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.IcsCalendar;
import com.synaptixfit.domain.model.planner.IcsEvent;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.CalendarUrls;
import com.synaptixfit.domain.model.planner.SubjectMatcher;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.IcsFeedPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.net.URI;
import java.net.URISyntaxException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;

/**
 * Importación y exportación iCalendar.
 *
 * <p>Importar es idempotente: cada evento se identifica por su UID (restricción única
 * {@code (usuario_id, ics_uid)} en bloques y en entregas) y volver a importar actualiza.
 */
public class IcsService implements ImportIcsUseCase, ImportGeneralCalendarUseCase, ExportIcsUseCase {

    /** Tope de eventos por importación (protege de calendarios desmesurados). */
    static final int MAX_EVENTS = 3000;

    private final SubjectDirectoryPort subjects;
    private final CalendarBlockRepositoryPort blocks;
    private final DeadlineRepositoryPort deadlines;
    private final IcsFeedPort feed;
    private final TimelineService timeline;
    private final WeeklyLoadService weeklyLoads;
    private final PlannerZone zone;
    private final Clock clock;
    private final ConflictFlagger conflicts;

    public IcsService(SubjectDirectoryPort subjects, CalendarBlockRepositoryPort blocks,
                      DeadlineRepositoryPort deadlines, IcsFeedPort feed, TimelineService timeline,
                      WeeklyLoadService weeklyLoads, PlannerZone zone, Clock clock) {
        this.subjects = subjects;
        this.blocks = blocks;
        this.deadlines = deadlines;
        this.feed = feed;
        this.timeline = timeline;
        this.weeklyLoads = weeklyLoads;
        this.zone = zone;
        this.clock = clock;
        this.conflicts = new ConflictFlagger(blocks);
    }

    @Override
    public Result importIcs(ImportIcsUseCase.Command command) {
        SubjectRef subject = subjects.findOwned(command.userId(), command.subjectId())
                .orElseThrow(() -> new PlannerSubjectNotFoundException(command.subjectId()));
        String url = command.url() != null && !command.url().isBlank() ? command.url() : subject.icsUrl();
        if (url == null || url.isBlank()) {
            throw new IcsUrlMissingException();
        }
        Downloaded calendar = download(url);
        List<IcsEvent> events = calendar.events();
        List<IcsEvent> matching = events.stream()
                .filter(e -> SubjectMatcher.mentions(e.summary(), subject.name(), subject.code()))
                .toList();
        // Calendario propio de la asignatura (su nombre la menciona, p. ej. «2_3_GIIT_EC») cuyos eventos no
        // repiten el nombre: todos son de ella.
        if (matching.isEmpty() && SubjectMatcher.mentions(calendar.name(), subject.name(), subject.code())) {
            matching = events;
        }
        Match match = matching.isEmpty() ? Match.NONE : matching.size() == events.size() ? Match.FULL : Match.PARTIAL;
        if (match == Match.NONE && !command.force()) {
            return new Result(match, events.size(), 0, 0, 0, 0, 0, 0, false);
        }
        List<IcsEvent> selected = command.force() ? events : matching;
        return save(command.userId(), selected, e -> subject.id(), match, events.size(), matching.size());
    }

    /**
     * Calendario general (Moodle): solo exámenes y entregas, sin avisos de apertura, cada uno en la asignatura
     * que mencione su título, categoría o descripción. Las clases vienen del horario de cada asignatura.
     */
    @Override
    public Result importGeneral(ImportGeneralCalendarUseCase.Command command) {
        if (command.url() == null || command.url().isBlank()) {
            throw new IcsUrlMissingException();
        }
        List<IcsEvent> events = download(command.url()).events();
        List<SubjectRef> active = subjects.findActive(command.userId());
        List<IcsEvent> selected = events.stream()
                .filter(e -> e.category() != IcsEvent.Category.CLASS && !e.isOpeningNotice())
                .toList();
        Map<String, UUID> subjectOf = new HashMap<>();
        for (IcsEvent e : selected) {
            e.subjectHints().stream()
                    .flatMap(hint -> active.stream().filter(s -> SubjectMatcher.mentions(hint, s.name(), s.code())))
                    .findFirst()
                    .ifPresent(s -> subjectOf.put(e.uid(), s.id()));
        }
        Match match = selected.isEmpty() ? Match.NONE : Match.FULL;
        return save(command.userId(), selected, e -> subjectOf.get(e.uid()), match, events.size(), subjectOf.size());
    }

    private record Downloaded(String name, List<IcsEvent> events) {
    }

    /** Solo lo que termina en el curso académico actual o después (antes de aplicar el tope de eventos). */
    private Downloaded download(String url) {
        String raw = feed.download(toUri(url));
        Instant from = IcsCalendar.academicYearStart(LocalDate.ofInstant(clock.instant(), zone.zone()))
                .atStartOfDay(zone.zone()).toInstant();
        List<IcsEvent> events = IcsCalendar.parse(raw, zone.zone()).stream()
                .filter(e -> !(e.end() == null ? e.start() : e.end()).isBefore(from))
                .toList();
        return new Downloaded(IcsCalendar.calendarName(raw),
                events.size() > MAX_EVENTS ? events.subList(0, MAX_EVENTS) : events);
    }

    /** Guarda (o actualiza por UID) los eventos como bloques y entregas; {@code subjectOf} da la asignatura de cada uno. */
    private Result save(UUID userId, List<IcsEvent> selected, Function<IcsEvent, UUID> subjectOf, Match match,
                        int totalEvents, int matchingEvents) {
        // Un UID repetido dentro del mismo calendario se importa una vez (gana el primero).
        Map<String, IcsEvent> byUid = new LinkedHashMap<>();
        selected.forEach(e -> byUid.putIfAbsent(e.uid(), e));

        Instant now = clock.instant();
        Map<String, CalendarBlock> existingBlocks = blocks.findByIcsUids(userId, byUid.keySet());
        Map<String, Deadline> existingDeadlines = deadlines.findByIcsUids(userId, byUid.keySet());
        int classes = 0;
        int exams = 0;
        int deliveries = 0;
        int created = 0;
        int updated = 0;
        List<CalendarBlock> toSave = new ArrayList<>();
        for (IcsEvent event : byUid.values()) {
            UUID subjectId = subjectOf.apply(event);
            IcsEvent.Category category = event.category();
            UUID deadlineId = null;
            ActivityType type = ActivityType.CLASS;
            if (category != IcsEvent.Category.CLASS) {
                boolean exam = category == IcsEvent.Category.EXAM;
                type = exam ? ActivityType.EXAM : ActivityType.DELIVERY;
                Deadline deadline = existingDeadlines.get(event.uid());
                String title = truncate(event.summary(), Deadline.TITLE_MAX);
                String description = truncate(event.description(), Deadline.DESCRIPTION_MAX);
                if (deadline == null) {
                    deadline = Deadline.builder().id(UUID.randomUUID()).userId(userId)
                            .subjectId(subjectId).title(title)
                            .type(exam ? DeadlineType.EXAM : DeadlineType.ASSIGNMENT).dueAt(event.start())
                            .difficulty(Priority.MEDIUM).description(description).icsUid(event.uid())
                            .createdAt(now).updatedAt(now).build();
                    created++;
                } else {
                    deadline.update(title, exam ? DeadlineType.EXAM : DeadlineType.ASSIGNMENT, event.start(), null,
                            description, subjectId, false, now);
                    updated++;
                }
                deadlineId = deadlines.save(deadline).id();
                if (exam) {
                    exams++;
                } else {
                    deliveries++;
                }
            } else {
                classes++;
            }
            Instant end = event.end().isBefore(event.start().plus(Duration.ofMinutes(TimeRange.MIN_MINUTES)))
                    ? event.start().plus(Duration.ofMinutes(TimeRange.MIN_MINUTES)) : event.end();
            TimeRange range = new TimeRange(event.start(), end);
            CalendarBlock.Details details = new CalendarBlock.Details(subjectId,
                    truncate(event.summary(), CalendarBlock.TOPICS_MAX), truncate(event.location(), CalendarBlock.LOCATION_MAX),
                    Priority.MEDIUM, false, null, null, null, null, null, null, deadlineId);
            CalendarBlock block = existingBlocks.get(event.uid());
            if (block == null) {
                block = CalendarBlock.builder().id(UUID.randomUUID()).userId(userId).range(range)
                        .dayOfWeek(zone.dayOfWeek(range.start())).type(type).details(details)
                        .fixed(false).immovable(true).icsUid(event.uid()).createdAt(now).build();
                created++;
            } else {
                block.syncFromSource(range, zone.dayOfWeek(range.start()), type, details);
                updated++;
            }
            toSave.add(block);
        }
        List<CalendarBlock> saved = blocks.saveAll(toSave);
        conflicts.refresh(userId, saved, List.of());
        saved.stream().map(b -> PlannerZone.mondayOf(zone.localDate(b.start()))).distinct()
                .forEach(monday -> weeklyLoads.refresh(userId, monday));
        return new Result(match, totalEvents, matchingEvents, classes, exams, deliveries, created, updated, true);
    }

    @Override
    public String exportIcs(UUID userId, Instant from, Instant to) {
        Ranges.check(from, to, Ranges.MAX_EXPORT_DAYS);
        return IcsCalendar.render(timeline.build(userId, from, to, null), clock.instant());
    }

    /** Solo http(s) o webcal (que se descarga por https); evita esquemas locales como file: o jar:. */
    static URI toUri(String url) {
        // Enlaces de Google Calendar del Campus Virtual («embed?src=…»): se descarga su ICS público.
        String value = CalendarUrls.normalize(url);
        if (value.toLowerCase(Locale.ROOT).startsWith("webcal://")) {
            value = "https://" + value.substring("webcal://".length());
        }
        try {
            URI uri = new URI(value);
            String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase(Locale.ROOT);
            if (!(scheme.equals("http") || scheme.equals("https")) || uri.getHost() == null) {
                throw new InvalidIcsUrlException();
            }
            return uri;
        } catch (URISyntaxException e) {
            throw new InvalidIcsUrlException();
        }
    }

    private static String truncate(String value, int max) {
        if (value == null) {
            return null;
        }
        return value.length() > max ? value.substring(0, max) : value;
    }
}
