package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.GetTimelineUseCase;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.TimelineItem;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;

/** Línea de tiempo unificada (bloques + entregas) para el inicio y la vista de asignatura. */
public class TimelineService implements GetTimelineUseCase {

    private static final Map<ActivityType, String> DEFAULT_TITLES = new EnumMap<>(Map.of(
            ActivityType.STUDY, "Estudio", ActivityType.SPORT, "Deporte", ActivityType.CLASS, "Clase",
            ActivityType.REST, "Descanso", ActivityType.MEAL, "Comida", ActivityType.SLEEP, "Sueño",
            ActivityType.EXAM, "Examen", ActivityType.DELIVERY, "Entrega", ActivityType.REVIEW, "Repaso"));

    private final CalendarBlockRepositoryPort blocks;
    private final DeadlineRepositoryPort deadlines;
    private final SubjectDirectoryPort subjects;

    public TimelineService(CalendarBlockRepositoryPort blocks, DeadlineRepositoryPort deadlines,
                           SubjectDirectoryPort subjects) {
        this.blocks = blocks;
        this.deadlines = deadlines;
        this.subjects = subjects;
    }

    @Override
    public List<TimelineItem> getTimeline(UUID userId, Instant from, Instant to, UUID subjectId) {
        Ranges.check(from, to, Ranges.MAX_QUERY_DAYS);
        return build(userId, from, to, subjectId);
    }

    /** Igual que {@link #getTimeline} pero con el límite de rango de la exportación. */
    List<TimelineItem> build(UUID userId, Instant from, Instant to, UUID subjectId) {
        List<CalendarBlock> blockList = blocks.findOverlapping(userId, from, to, subjectId);
        List<Deadline> deadlineList = deadlines.findAll(userId, new DeadlineRepositoryPort.Query(from, to, subjectId, false));
        Set<UUID> subjectIds = new HashSet<>();
        Stream.concat(blockList.stream().map(CalendarBlock::subjectId), deadlineList.stream().map(Deadline::subjectId))
                .filter(Objects::nonNull).forEach(subjectIds::add);
        Map<UUID, String> names = subjectIds.isEmpty() ? Map.of() : subjects.namesOf(userId, subjectIds);
        Set<UUID> deadlineIds = new HashSet<>();
        deadlineList.forEach(d -> deadlineIds.add(d.id()));

        List<TimelineItem> items = new ArrayList<>();
        for (CalendarBlock b : blockList) {
            UUID linked = b.details().deadlineId();
            if (linked != null && deadlineIds.contains(linked)) {
                continue;
            }
            String subjectName = b.subjectId() == null ? null : names.get(b.subjectId());
            String title = b.details().topics() != null ? b.details().topics()
                    : subjectName != null ? subjectName : DEFAULT_TITLES.get(b.type());
            items.add(new TimelineItem(TimelineItem.Kind.BLOCK, b.id(), b.type(), null, title, b.start(), b.end(),
                    b.subjectId(), subjectName, b.completed(), b.fixed(), b.immovable(), b.details().location(),
                    linked, b.details().challengeId(), b.details().milestoneId(), b.details().routineId(),
                    b.details().routineDayId()));
        }
        for (Deadline d : deadlineList) {
            items.add(new TimelineItem(TimelineItem.Kind.DEADLINE, d.id(), null, d.type(), d.title(), d.dueAt(),
                    d.dueAt(), d.subjectId(), d.subjectId() == null ? null : names.get(d.subjectId()), d.completed(),
                    false, false, null, d.id(), null, null, null, null));
        }
        items.sort(Comparator.comparing(TimelineItem::start).thenComparing(i -> i.kind().ordinal()));
        return items;
    }
}
