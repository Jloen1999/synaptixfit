package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.planner.GetWeekBalanceUseCase;
import com.synaptixfit.application.port.input.planner.GetWeeklyLoadsUseCase;
import com.synaptixfit.application.port.input.planner.SyncWeeklyLoadUseCase;
import com.synaptixfit.application.port.input.planner.UpdateWeeklyWellbeingUseCase;
import com.synaptixfit.domain.exception.planner.PlannerRangeTooLargeException;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.model.planner.PlannerProfile;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.WeekBalance;
import com.synaptixfit.domain.model.planner.WeeklyAcademicLoad;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.FocusSessionRepositoryPort;
import com.synaptixfit.domain.port.output.planner.PlannerProfilePort;
import com.synaptixfit.domain.port.output.planner.WeeklyLoadRepositoryPort;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Carga académica semanal y balance estudio/deporte.
 *
 * <p>Los demás servicios del planificador llaman a {@link #refresh} tras completar bloques o
 * entregas para que la carga de esa semana esté siempre al día (como hacía la app antigua). El
 * bonus semanal de estudio se concede al llegar al objetivo y se retira si la semana vuelve a
 * quedar por debajo (desmarcar o borrar bloques), para que no se pueda ganar y deshacer.
 */
public class WeeklyLoadService implements SyncWeeklyLoadUseCase, UpdateWeeklyWellbeingUseCase, GetWeeklyLoadsUseCase,
        GetWeekBalanceUseCase {

    private final WeeklyLoadRepositoryPort loads;
    private final CalendarBlockRepositoryPort blocks;
    private final FocusSessionRepositoryPort focusSessions;
    private final DeadlineRepositoryPort deadlines;
    private final PlannerProfilePort profiles;
    private final AwardExperienceUseCase award;
    private final RevokeExperienceUseCase revoke;
    private final PlannerZone zone;

    public WeeklyLoadService(WeeklyLoadRepositoryPort loads, CalendarBlockRepositoryPort blocks,
                             FocusSessionRepositoryPort focusSessions, DeadlineRepositoryPort deadlines,
                             PlannerProfilePort profiles, AwardExperienceUseCase award, RevokeExperienceUseCase revoke,
                             PlannerZone zone) {
        this.loads = loads;
        this.blocks = blocks;
        this.focusSessions = focusSessions;
        this.deadlines = deadlines;
        this.profiles = profiles;
        this.award = award;
        this.revoke = revoke;
        this.zone = zone;
    }

    @Override
    public Result syncWeek(UUID userId, LocalDate weekStart) {
        return refresh(userId, weekStart);
    }

    /** Recalcula la semana que contiene {@code date}. */
    Result refresh(UUID userId, LocalDate date) {
        LocalDate monday = PlannerZone.mondayOf(date);
        WeeklyAcademicLoad load = loads.findByUserAndWeek(userId, monday)
                .orElseGet(() -> WeeklyAcademicLoad.empty(UUID.randomUUID(), userId, monday));
        Instant from = zone.weekStart(monday);
        Instant to = zone.weekEnd(monday);
        long planned = 0;
        long actual = 0;
        Set<UUID> completedBlocks = new HashSet<>();
        for (CalendarBlock b : weekBlocks(userId, monday)) {
            if (b.type().countsAsStudy()) {
                planned += b.range().minutes();
                if (b.completed()) {
                    actual += b.range().minutes();
                    completedBlocks.add(b.id());
                }
            }
        }
        actual += FocusSession.focusMinutesOutside(
                focusSessions.findByUserBetween(userId, monday, monday.plusDays(6)), completedBlocks);
        List<Deadline> week = deadlines.findAll(userId, new DeadlineRepositoryPort.Query(from, to, null, false));
        int exams = (int) week.stream().filter(d -> d.type() == DeadlineType.EXAM).count();
        load.refresh(planned, actual, exams, week.size() - exams);
        int goal = profiles.findAcademic(userId).map(PlannerProfile.Academic::weeklyStudyGoalHours)
                .orElse(PlannerProfile.Academic.DEFAULT_WEEKLY_GOAL_HOURS);
        int xp = 0;
        if (load.qualifiesForStudyExperience(goal)) {
            award.award(userId, WeeklyAcademicLoad.STUDY_EXPERIENCE);
            load.markExperienceAwarded();
            xp = WeeklyAcademicLoad.STUDY_EXPERIENCE;
        } else if (load.losesStudyExperience(goal)) {
            revoke.revoke(userId, WeeklyAcademicLoad.STUDY_EXPERIENCE);
            load.markExperienceRevoked();
            xp = -WeeklyAcademicLoad.STUDY_EXPERIENCE;
        }
        return new Result(loads.save(load), xp);
    }

    @Override
    public WeeklyAcademicLoad updateWellbeing(Command command) {
        LocalDate monday = PlannerZone.mondayOf(command.weekStart());
        WeeklyAcademicLoad load = loads.findByUserAndWeek(command.userId(), monday)
                .orElseGet(() -> refresh(command.userId(), monday).load());
        load.updateWellbeing(command.stressLevel(), command.sleepHours(), command.notes());
        return loads.save(load);
    }

    @Override
    public List<WeeklyAcademicLoad> getWeeklyLoads(UUID userId, LocalDate from, LocalDate to) {
        if (from.isAfter(to) || ChronoUnit.DAYS.between(from, to) > 3 * 366) {
            throw new PlannerRangeTooLargeException();
        }
        return loads.findByUserBetween(userId, PlannerZone.mondayOf(from), PlannerZone.mondayOf(to));
    }

    @Override
    public WeekBalance getBalance(UUID userId, LocalDate weekStart) {
        return WeekBalance.of(weekBlocks(userId, PlannerZone.mondayOf(weekStart)));
    }

    /** Bloques que empiezan dentro de la semana (un bloque se cuenta en la semana de su inicio). */
    private List<CalendarBlock> weekBlocks(UUID userId, LocalDate monday) {
        Instant from = zone.weekStart(monday);
        Instant to = zone.weekEnd(monday);
        return blocks.findOverlapping(userId, from, to, null).stream()
                .filter(b -> !b.start().isBefore(from) && b.start().isBefore(to))
                .toList();
    }
}
