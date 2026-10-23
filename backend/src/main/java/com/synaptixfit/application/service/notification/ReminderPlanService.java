package com.synaptixfit.application.service.notification;

import com.synaptixfit.application.port.input.notification.GetReminderPlanUseCase;
import com.synaptixfit.domain.model.notification.NotificationPreferences;
import com.synaptixfit.domain.model.notification.ReminderPlan;
import com.synaptixfit.domain.model.notification.ReminderPlanner;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.notification.NotificationPreferencesRepositoryPort;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import com.synaptixfit.domain.port.output.user.UsageFocusPort;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Implementa {@link GetReminderPlanUseCase}: reúne preferencias, enfoque de uso, repasos vencidos y
 * bloques del planificador y deja que {@link ReminderPlanner} decida. Solo lee lo que se va a avisar.
 */
public class ReminderPlanService implements GetReminderPlanUseCase {

    /** Igual que el listado de repasos vencidos: el número del aviso no pasa de aquí. */
    static final int MAX_COUNTED_REVIEWS = 100;

    private final NotificationPreferencesRepositoryPort preferences;
    private final UsageFocusPort focus;
    private final StudyMaterialRepositoryPort materials;
    private final CalendarBlockRepositoryPort blocks;
    private final SubjectDirectoryPort subjects;
    private final ReminderPlanner planner;
    private final Clock clock;
    private final ZoneId zone;

    public ReminderPlanService(NotificationPreferencesRepositoryPort preferences, UsageFocusPort focus,
                               StudyMaterialRepositoryPort materials, CalendarBlockRepositoryPort blocks,
                               SubjectDirectoryPort subjects, ReminderPlanner planner, Clock clock, ZoneId zone) {
        this.preferences = preferences;
        this.focus = focus;
        this.materials = materials;
        this.blocks = blocks;
        this.subjects = subjects;
        this.planner = planner;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public ReminderPlan getReminderPlan(UUID userId, int days) {
        Instant now = clock.instant();
        Instant end = ReminderPlanner.horizonEnd(now, days);
        NotificationPreferences prefs = preferences.findByUserId(userId)
                .orElseGet(() -> NotificationPreferences.defaults(userId, now));
        UsageFocus usageFocus = focus.focusOf(userId);

        int dueReviews = ReminderPlanner.wantsReviews(prefs, usageFocus)
                ? materials.findDue(userId, now, MAX_COUNTED_REVIEWS).size() : 0;
        List<ReminderPlanner.Block> upcoming = ReminderPlanner.wantsBlocks(prefs, usageFocus)
                ? toBlocks(userId, blocks.findOverlapping(userId, now, end, null)) : List.of();

        return planner.plan(new ReminderPlanner.Input(dueReviews, upcoming, prefs, usageFocus, now, zone, days));
    }

    /** Título del aviso: los temas del bloque o, si no hay, el nombre de su asignatura. */
    private List<ReminderPlanner.Block> toBlocks(UUID userId, List<CalendarBlock> found) {
        Set<UUID> subjectIds = found.stream()
                .filter(b -> b.details().topics() == null)
                .map(CalendarBlock::subjectId).filter(Objects::nonNull).collect(Collectors.toSet());
        Map<UUID, String> names = subjectIds.isEmpty() ? Map.of() : subjects.namesOf(userId, subjectIds);
        return found.stream().map(b -> new ReminderPlanner.Block(b.id(), b.type(), b.start(),
                b.details().topics() != null ? b.details().topics()
                        : b.subjectId() == null ? null : names.get(b.subjectId()),
                b.completed())).toList();
    }
}
