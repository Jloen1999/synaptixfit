package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.GetWeekPlanStatusUseCase;
import static com.synaptixfit.application.service.planner.PlannerFakes.at;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.planner.SaveWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.planner.UpdateWeeklyWellbeingUseCase;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.PlannerProfile;
import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.model.planner.WeekBalance;
import com.synaptixfit.domain.model.planner.WeeklyAcademicLoad;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class StudyPlanAndWeeklyLoadServiceTest {

    private PlannerFakes f;
    private StudyPlanService plans;
    private WeeklyLoadService loads;

    @BeforeEach
    void setUp() {
        f = new PlannerFakes();
        loads = f.weeklyLoadService();
        plans = f.studyPlanService();
    }

    private CalendarBlock block(ActivityType type, Instant start, int minutes, boolean completed, String icsUid) {
        return f.blocks.save(CalendarBlock.builder().id(UUID.randomUUID()).userId(f.user)
                .range(TimeRange.ofMinutes(start, minutes)).type(type).completed(completed).icsUid(icsUid).build());
    }

    @Test
    void savingThePlanFromAnOldAppFollowsTheSameRuleAndReusesTheWeekPlan() {
        block(ActivityType.STUDY, at(1, 16, 0), 60, false, null);
        block(ActivityType.SPORT, at(2, 18, 0), 60, false, null);
        block(ActivityType.REVIEW, at(4, 18, 0), 60, false, null);
        block(ActivityType.CLASS, at(3, 9, 0), 120, false, "ai-x-20261022-0900");
        block(ActivityType.STUDY, at(8, 16, 0), 60, false, null);

        SaveWeeklyPlanUseCase.Result first = plans.savePlan(
                new SaveWeeklyPlanUseCase.Command(f.user, PlannerFakes.MONDAY.plusDays(2), null, Visibility.FRIENDS));
        // Los dobles en memoria comparten instancia: se captura el nombre antes de volver a guardar.
        String firstName = first.plan().name();
        SaveWeeklyPlanUseCase.Result second = plans.savePlan(
                new SaveWeeklyPlanUseCase.Command(f.user, PlannerFakes.MONDAY, "Semana dura", null));

        assertThat(first.xpAwarded()).isEqualTo(115);
        assertThat(first.blockCount()).isEqualTo(4);
        assertThat(firstName).isEqualTo("Plan 19/10");
        assertThat(first.plan().weekStart()).isEqualTo(PlannerFakes.MONDAY);
        assertThat(second.xpAwarded()).isZero();
        assertThat(second.plan().id()).isEqualTo(first.plan().id());
        assertThat(second.plan().name()).isEqualTo("Semana dura");
        assertThat(second.plan().visibility()).isEqualTo(Visibility.FRIENDS);
        assertThat(f.plans.store).hasSize(1);
        assertThat(f.xp.of(f.user)).isEqualTo(115);
        assertThat(f.blocks.store.values()).filteredOn(b -> first.plan().id().equals(b.studyPlanId())).hasSize(4);
    }

    @Test
    void savingAWeekWithTooFewEventsGivesNoExperienceYet() {
        block(ActivityType.STUDY, at(1, 16, 0), 60, false, null);
        assertThat(plans.status(f.user, PlannerFakes.MONDAY.plusDays(3)))
                .isEqualTo(new GetWeekPlanStatusUseCase.Status(PlannerFakes.MONDAY, false, 0));

        plans.savePlan(new SaveWeeklyPlanUseCase.Command(f.user, PlannerFakes.MONDAY, null, null));

        GetWeekPlanStatusUseCase.Status closed = plans.status(f.user, PlannerFakes.MONDAY.plusDays(6));
        assertThat(closed.closed()).isTrue();
        assertThat(closed.xpAwarded()).isZero();
        assertThat(plans.status(f.otherUser, PlannerFakes.MONDAY).closed()).isFalse();

        // El plan ya existe sin experiencia: al llegar al tercer evento se da igual.
        block(ActivityType.STUDY, at(2, 16, 0), 60, false, null);
        block(ActivityType.REVIEW, at(3, 16, 0), 60, false, null);
        assertThat(plans.rewardWeek(f.user, PlannerFakes.MONDAY)).isEqualTo(115);
        assertThat(plans.status(f.user, PlannerFakes.MONDAY).xpAwarded()).isEqualTo(115);
    }

    @Test
    void deletingThePlanRevokesTheExactExperienceSoItCannotBeFarmed() {
        block(ActivityType.STUDY, at(1, 16, 0), 60, false, null);
        block(ActivityType.STUDY, at(2, 16, 0), 60, false, null);
        block(ActivityType.SPORT, at(3, 18, 0), 60, false, null);
        var result = plans.savePlan(new SaveWeeklyPlanUseCase.Command(f.user, PlannerFakes.MONDAY, null, null));
        assertThat(f.xp.of(f.user)).isEqualTo(115);
        plans.deletePlan(f.user, result.plan().id());
        assertThat(f.xp.of(f.user)).isZero();
        assertThatThrownBy(() -> plans.deletePlan(f.otherUser, result.plan().id()))
                .extracting("code").isEqualTo("PLAN_NOT_FOUND");
    }

    @Test
    void aWeekThatAlreadyGaveItsExperienceNeverGivesItAgain() {
        f.plans.save(new StudyPlan(UUID.randomUUID(), f.user, "Plan", PlannerFakes.MONDAY, null, true, 115));
        for (int day = 0; day < 4; day++) {
            block(ActivityType.STUDY, at(day, 18, 0), 60, false, null);
        }
        assertThat(plans.rewardWeek(f.user, PlannerFakes.MONDAY)).isZero();
        assertThat(plans.savePlan(new SaveWeeklyPlanUseCase.Command(f.user, PlannerFakes.MONDAY, null, null))
                .xpAwarded()).isZero();
        assertThat(f.xp.of(f.user)).isZero();
    }

    @Test
    void onlyEventsThePersonPlannedCountTowardsThePlanningExperience() {
        // Clase fija, importada, repaso creado por el repaso espaciado y sueño: ninguno es planificar.
        f.blocks.save(CalendarBlock.builder().id(UUID.randomUUID()).userId(f.user)
                .range(TimeRange.ofMinutes(at(1, 9, 0), 60)).type(ActivityType.CLASS).fixed(true).build());
        block(ActivityType.CLASS, at(2, 9, 0), 60, false, "ics-1");
        f.blocks.save(CalendarBlock.builder().id(UUID.randomUUID()).userId(f.user)
                .range(TimeRange.ofMinutes(at(3, 9, 0), 60)).type(ActivityType.REVIEW)
                .studyMaterialId(UUID.randomUUID()).build());
        block(ActivityType.SLEEP, at(4, 0, 0), 420, false, null);

        assertThat(plans.rewardWeek(f.user, PlannerFakes.MONDAY)).isZero();
        assertThat(f.plans.store).isEmpty();
    }

    @Test
    void onlyThisWeekAndTheNextOneGiveThePlanningExperience() {
        for (int week : new int[] {1, 2}) {
            for (int day = 0; day < 3; day++) {
                block(ActivityType.STUDY, at(7 * week + day, 10, 0), 60, false, null);
            }
        }
        // La semana siguiente sí; la de dentro de dos, no (no se puede ganar 52 veces por adelantado).
        assertThat(plans.rewardWeek(f.user, PlannerFakes.MONDAY.plusWeeks(1))).isEqualTo(115);
        assertThat(plans.rewardWeek(f.user, PlannerFakes.MONDAY.plusWeeks(2))).isZero();
        assertThat(StudyPlan.rewardable(3, PlannerFakes.MONDAY.minusWeeks(1), PlannerFakes.MONDAY)).isFalse();
    }

    @Test
    void weeklyLoadGrantsStudyExperienceOnceAt80PercentOfTheGoal() {
        f.directory.academic.put(f.user, new PlannerProfile.Academic(5, null, null));
        block(ActivityType.STUDY, at(1, 10, 0), 120, true, null);
        block(ActivityType.REVIEW, at(2, 10, 0), 60, true, null);
        block(ActivityType.STUDY, at(3, 10, 0), 120, false, null);
        block(ActivityType.SPORT, at(3, 18, 0), 120, true, null);

        var first = loads.syncWeek(f.user, PlannerFakes.MONDAY);
        assertThat(first.load().plannedHours()).isEqualTo(5);
        assertThat(first.load().actualHours()).isEqualTo(3);
        assertThat(first.xpAwarded()).isZero();

        block(ActivityType.STUDY, at(4, 10, 0), 60, true, null);
        var second = loads.syncWeek(f.user, PlannerFakes.MONDAY);
        assertThat(second.xpAwarded()).isEqualTo(WeeklyAcademicLoad.STUDY_EXPERIENCE);
        assertThat(loads.syncWeek(f.user, PlannerFakes.MONDAY).xpAwarded()).isZero();
        assertThat(f.xp.of(f.user)).isEqualTo(150);
    }

    @Test
    void wellbeingIsStoredAndValidated() {
        WeeklyAcademicLoad load = loads.updateWellbeing(
                new UpdateWeeklyWellbeingUseCase.Command(f.user, PlannerFakes.MONDAY.plusDays(4), 8, 6.5, "Exámenes"));
        assertThat(load.stressLevel()).isEqualTo(8);
        assertThat(load.sleepHours()).isEqualTo(6.5);
        assertThat(load.weekStart()).isEqualTo(PlannerFakes.MONDAY);
        assertThatThrownBy(() -> loads.updateWellbeing(
                new UpdateWeeklyWellbeingUseCase.Command(f.user, PlannerFakes.MONDAY, 11, null, null)))
                .extracting("code").isEqualTo("VALIDATION_ERROR");
    }

    @Test
    void balanceUsesTheBlocksOfTheWeek() {
        block(ActivityType.STUDY, at(1, 10, 0), 180, true, null);
        block(ActivityType.SPORT, at(2, 18, 0), 120, false, null);
        WeekBalance balance = loads.getBalance(f.user, PlannerFakes.MONDAY);
        assertThat(balance.plannedStudyHours()).isEqualTo(3.0);
        assertThat(balance.actualStudyHours()).isEqualTo(3.0);
        assertThat(balance.plannedSportHours()).isEqualTo(2.0);
        assertThat(balance.state()).isEqualTo(WeekBalance.State.BALANCED);
    }
}
