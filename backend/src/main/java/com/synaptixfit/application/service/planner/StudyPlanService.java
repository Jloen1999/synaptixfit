package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.planner.DeleteStudyPlanUseCase;
import com.synaptixfit.application.port.input.planner.GetStudyPlansUseCase;
import com.synaptixfit.application.port.input.planner.GetWeekPlanStatusUseCase;
import com.synaptixfit.application.port.input.planner.PrivatizeUserStudyPlansUseCase;
import com.synaptixfit.application.port.input.planner.SaveWeeklyPlanUseCase;
import com.synaptixfit.domain.exception.planner.StudyPlanNotFoundException;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.StudyPlanRepositoryPort;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Plan semanal. Corrige el fallo de la app antigua, que no podía guardar el plan por valores de
 * visibilidad heredados ('publico'/'privado'): aquí la visibilidad es siempre private/friends/public.
 * Al pasar el perfil a privado ({@code UserPrivacyChanged}) todos los planes pasan a privados.
 */
public class StudyPlanService implements SaveWeeklyPlanUseCase, GetStudyPlansUseCase, DeleteStudyPlanUseCase,
        PrivatizeUserStudyPlansUseCase, GetWeekPlanStatusUseCase {

    private final StudyPlanRepositoryPort plans;
    private final CalendarBlockRepositoryPort blocks;
    private final DeadlineRepositoryPort deadlines;
    private final AwardExperienceUseCase award;
    private final RevokeExperienceUseCase revoke;
    private final PlannerZone zone;

    public StudyPlanService(StudyPlanRepositoryPort plans, CalendarBlockRepositoryPort blocks,
                            DeadlineRepositoryPort deadlines, AwardExperienceUseCase award,
                            RevokeExperienceUseCase revoke, PlannerZone zone) {
        this.plans = plans;
        this.blocks = blocks;
        this.deadlines = deadlines;
        this.award = award;
        this.revoke = revoke;
        this.zone = zone;
    }

    @Override
    public Result savePlan(Command command) {
        LocalDate monday = PlannerZone.mondayOf(command.weekStart());
        StudyPlan plan = plans.findByUserAndWeek(command.userId(), monday)
                .orElseGet(() -> new StudyPlan(UUID.randomUUID(), command.userId(),
                        command.name() == null || command.name().isBlank()
                                ? "Plan " + monday.getDayOfMonth() + "/" + monday.getMonthValue() : command.name(),
                        monday, command.visibility(), false, 0));
        plan.rename(command.name() == null || command.name().isBlank() ? null : command.name());
        plan.changeVisibility(command.visibility());
        StudyPlan saved = plans.save(plan);

        Instant from = zone.weekStart(monday);
        Instant to = zone.weekEnd(monday);
        List<CalendarBlock> weekBlocks = blocks.findOverlapping(command.userId(), from, to, null).stream()
                .filter(b -> !b.start().isBefore(from) && b.start().isBefore(to))
                .toList();
        weekBlocks.forEach(b -> b.attachToPlan(saved.id()));
        blocks.saveAll(weekBlocks);
        List<Deadline> weekDeadlines = deadlines.findAll(command.userId(),
                new DeadlineRepositoryPort.Query(from, to, null, false));
        weekDeadlines.forEach(d -> {
            d.attachToPlan(saved.id());
            deadlines.save(d);
        });

        // Solo cuentan los bloques planificados por el usuario (no los fijos ni los importados).
        int planned = (int) weekBlocks.stream().filter(b -> !b.fixed() && b.icsUid() == null).count();
        int xp = 0;
        if (!saved.xpAwarded()) {
            xp = StudyPlan.experienceFor(planned);
            award.award(command.userId(), xp);
            saved.markExperienceAwarded(xp);
            plans.save(saved);
        }
        return new Result(saved, weekBlocks.size(), weekDeadlines.size(), xp);
    }

    /** Cerrada si ya tiene plan guardado (eso es lo que hace «Cerrar semana»). */
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
