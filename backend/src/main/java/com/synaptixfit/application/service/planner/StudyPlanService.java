package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.planner.DeleteStudyPlanUseCase;
import com.synaptixfit.application.port.input.planner.GetStudyPlansUseCase;
import com.synaptixfit.application.port.input.planner.GetWeekPlanStatusUseCase;
import com.synaptixfit.application.port.input.planner.PrivatizeUserStudyPlansUseCase;
import com.synaptixfit.application.port.input.planner.RewardWeekPlanningUseCase;
import com.synaptixfit.application.port.input.planner.SaveWeeklyPlanUseCase;
import com.synaptixfit.domain.exception.planner.StudyPlanNotFoundException;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.StudyPlanRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Plan semanal y su experiencia. La experiencia de planificar se da sola ({@link #rewardWeek}, ADR 0038), la pide
 * {@link CalendarBlockService} al añadir eventos; {@code PUT /plans/{weekStart}} («Cerrar semana» de las apps
 * antiguas) sigue guardando nombre y visibilidad con la misma regla. Al pasar el perfil a privado
 * ({@code UserPrivacyChanged}) los planes pasan a privados.
 */
public class StudyPlanService implements SaveWeeklyPlanUseCase, GetStudyPlansUseCase, DeleteStudyPlanUseCase,
        PrivatizeUserStudyPlansUseCase, GetWeekPlanStatusUseCase, RewardWeekPlanningUseCase {

    private final StudyPlanRepositoryPort plans;
    private final CalendarBlockRepositoryPort blocks;
    private final DeadlineRepositoryPort deadlines;
    private final AwardExperienceUseCase award;
    private final RevokeExperienceUseCase revoke;
    private final PlannerZone zone;
    private final Clock clock;

    public StudyPlanService(StudyPlanRepositoryPort plans, CalendarBlockRepositoryPort blocks,
                            DeadlineRepositoryPort deadlines, AwardExperienceUseCase award,
                            RevokeExperienceUseCase revoke, PlannerZone zone, Clock clock) {
        this.plans = plans;
        this.blocks = blocks;
        this.deadlines = deadlines;
        this.award = award;
        this.revoke = revoke;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public Result savePlan(Command command) {
        LocalDate monday = PlannerZone.mondayOf(command.weekStart());
        StudyPlan plan = plans.findByUserAndWeek(command.userId(), monday)
                .orElseGet(() -> plans.saveIfAbsent(
                        newPlan(command.userId(), monday, command.name(), command.visibility())));
        plan.rename(command.name() == null || command.name().isBlank() ? null : command.name());
        plan.changeVisibility(command.visibility());
        StudyPlan saved = plans.save(plan);

        List<CalendarBlock> weekBlocks = weekBlocks(command.userId(), monday);
        weekBlocks.forEach(b -> b.attachToPlan(saved.id()));
        blocks.saveAll(weekBlocks);
        List<Deadline> weekDeadlines = deadlines.findAll(command.userId(),
                new DeadlineRepositoryPort.Query(zone.weekStart(monday), zone.weekEnd(monday), null, false));
        weekDeadlines.forEach(d -> {
            d.attachToPlan(saved.id());
            deadlines.save(d);
        });
        // Misma regla que sin botón: una app antigua que aún «cierra la semana» no gana más ni antes.
        int planned = StudyPlan.plannedEvents(weekBlocks);
        int xp = !saved.xpAwarded() && StudyPlan.rewardable(planned, monday, zone.today(clock.instant()))
                ? grant(saved, planned) : 0;
        return new Result(saved, weekBlocks.size(), weekDeadlines.size(), xp);
    }

    @Override
    public int rewardWeek(UUID userId, LocalDate day) {
        LocalDate monday = PlannerZone.mondayOf(day);
        LocalDate today = zone.today(clock.instant());
        Optional<StudyPlan> existing = plans.findByUserAndWeek(userId, monday);
        // Lo barato primero: ya dada o semana fuera de plazo no necesita contar eventos.
        if (existing.map(StudyPlan::xpAwarded).orElse(false)
                || !StudyPlan.rewardable(StudyPlan.MIN_PLANNED_EVENTS, monday, today)) {
            return 0;
        }
        int planned = StudyPlan.plannedEvents(weekBlocks(userId, monday));
        if (!StudyPlan.rewardable(planned, monday, today)) {
            return 0;
        }
        return grant(existing.orElseGet(() -> plans.saveIfAbsent(newPlan(userId, monday, null, null))), planned);
    }

    /**
     * Da la experiencia de planificar al plan (ya comprobada la regla). La anota antes con una actualización
     * condicional: si otra petición a la vez ya la anotó, esta no da nada (ADR 0019: nunca dos veces).
     */
    private int grant(StudyPlan plan, int planned) {
        int xp = StudyPlan.experienceFor(planned);
        if (!plans.markExperienceAwarded(plan.id(), xp)) {
            return 0;
        }
        award.award(plan.userId(), xp);
        plan.markExperienceAwarded(xp);
        return xp;
    }

    private static StudyPlan newPlan(UUID userId, LocalDate monday, String name, Visibility visibility) {
        return new StudyPlan(UUID.randomUUID(), userId,
                name == null || name.isBlank() ? "Plan " + monday.getDayOfMonth() + "/" + monday.getMonthValue() : name,
                monday, visibility, false, 0);
    }

    /** Eventos que empiezan en la semana del lunes {@code monday}. */
    private List<CalendarBlock> weekBlocks(UUID userId, LocalDate monday) {
        Instant from = zone.weekStart(monday);
        Instant to = zone.weekEnd(monday);
        return blocks.findOverlapping(userId, from, to, null).stream()
                .filter(b -> !b.start().isBefore(from) && b.start().isBefore(to))
                .toList();
    }

    /** «Cerrada» (para apps antiguas) si la semana ya tiene plan guardado. */
    @Override
    public GetWeekPlanStatusUseCase.Status status(UUID userId, LocalDate weekStart) {
        LocalDate monday = PlannerZone.mondayOf(weekStart);
        return plans.findByUserAndWeek(userId, monday)
                .map(p -> new GetWeekPlanStatusUseCase.Status(monday, true, p.xpPoints()))
                .orElse(new GetWeekPlanStatusUseCase.Status(monday, false, 0));
    }

    @Override
    public PageResult<StudyPlan> getPlans(UUID userId, PageRequest page) {
        return plans.findByUser(userId, page);
    }

    @Override
    public void deletePlan(UUID userId, UUID planId) {
        StudyPlan plan = plans.findById(planId)
                .filter(p -> p.userId().equals(userId))
                .orElseThrow(() -> new StudyPlanNotFoundException(planId));
        if (plan.xpPoints() > 0) {
            revoke.revoke(userId, plan.xpPoints());
        }
        plans.delete(plan.id());
    }

    @Override
    public int privatizeAll(UUID userId) {
        int changed = 0;
        for (StudyPlan plan : plans.findNonPrivateByUser(userId)) {
            if (plan.privatize()) {
                plans.save(plan);
                changed++;
            }
        }
        return changed;
    }
}
