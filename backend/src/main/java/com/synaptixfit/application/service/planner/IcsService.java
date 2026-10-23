package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.ExportIcsUseCase;
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
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/**
 * Importación y exportación iCalendar.
 *
 * <p>Importar es idempotente: cada evento se identifica por su UID (restricción única
 * {@code (usuario_id, ics_uid)} en bloques y en entregas) y volver a importar actualiza.
 */
public class IcsService implements ImportIcsUseCase, ExportIcsUseCase {

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
    public Result importIcs(Command command) {
        SubjectRef subject = subjects.findOwned(command.userId(), command.subjectId())
                .orElseThrow(() -> new PlannerSubjectNotFoundException(command.subjectId()));
        String url = command.url() != null && !command.url().isBlank() ? command.url() : subject.icsUrl();
        if (url == null || url.isBlank()) {
            throw new IcsUrlMissingException();
        }
        List<IcsEvent> events = IcsCalendar.parse(feed.download(toUri(url)), zone.zone());
        if (events.size() > MAX_EVENTS) {
            events = events.subList(0, MAX_EVENTS);
        }
        List<IcsEvent> matching = events.stream()
                .filter(e -> SubjectMatcher.mentions(e.summary(), subject.name(), subject.code()))
                .toList();
        Match match = matching.isEmpty() ? Match.NONE : matching.size() == events.size() ? Match.FULL : Match.PARTIAL;
        if (match == Match.NONE && !command.force()) {
            return new Result(match, events.size(), 0, 0, 0, 0, 0, 0, false);
        }
        List<IcsEvent> selected = command.force() ? events : matching;
        // Un UID repetido dentro del mismo calendario se importa una vez (gana el primero).
        Map<String, IcsEvent> byUid = new LinkedHashMap<>();
        selected.forEach(e -> byUid.putIfAbsent(e.uid(), e));

        Instant now = clock.instant();
        Map<String, CalendarBlock> existingBlocks = blocks.findByIcsUids(command.userId(), byUid.keySet());
        Map<String, Deadline> existingDeadlines = deadlines.findByIcsUids(command.userId(), byUid.keySet());
        int classes = 0;
        int exams = 0;
        int deliveries = 0;
        int created = 0;
        int updated = 0;
        List<CalendarBlock> toSave = new ArrayList<>();
        for (IcsEvent event : byUid.values()) {
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
                    deadline = Deadline.builder().id(UUID.randomUUID()).userId(command.userId())
                            .subjectId(subject.id()).title(title)
                            .type(exam ? DeadlineType.EXAM : DeadlineType.ASSIGNMENT).dueAt(event.start())
                            .difficulty(Priority.MEDIUM).description(description).icsUid(event.uid())
                            .createdAt(now).updatedAt(now).build();
                    created++;
                } else {
                    deadline.update(title, exam ? DeadlineType.EXAM : DeadlineType.ASSIGNMENT, event.start(), null,
                            description, subject.id(), false, now);
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
            CalendarBlock.Details details = new CalendarBlock.Details(subject.id(),
                    truncate(event.summary(), CalendarBlock.TOPICS_MAX), truncate(event.location(), CalendarBlock.LOCATION_MAX),
                    Priority.MEDIUM, false, null, null, null, null, null, null, deadlineId);
            CalendarBlock block = existingBlocks.get(event.uid());
            if (block == null) {
                block = CalendarBlock.builder().id(UUID.randomUUID()).userId(command.userId()).range(range)
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
        conflicts.refresh(command.userId(), saved, List.of());
        saved.stream().map(b -> PlannerZone.mondayOf(zone.localDate(b.start()))).distinct()
                .forEach(monday -> weeklyLoads.refresh(command.userId(), monday));
        return new Result(match, events.size(), matching.size(), classes, exams, deliveries, created, updated, true);
    }

    @Override
    public String exportIcs(UUID userId, Instant from, Instant to) {
        Ranges.check(from, to, Ranges.MAX_EXPORT_DAYS);
        return IcsCalendar.render(timeline.build(userId, from, to, null), clock.instant());
    }

    /** Solo http(s) o webcal (que se descarga por https); evita esquemas locales como file: o jar:. */
    static URI toUri(String url) {
        String value = url.strip();
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
