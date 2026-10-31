package com.synaptixfit.domain.model.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Reglas de dominio del planificador: duración, bloqueos, conflictos, experiencia y patrón semanal. */
class PlannerDomainTest {

    private static final PlannerZone ZONE = PlannerZone.of("Europe/Madrid");
    private static final Instant NOW = Instant.parse("2026-10-19T08:00:00Z");

    private static CalendarBlock block(Instant start, Instant end, boolean fixed, boolean immovable) {
        return CalendarBlock.builder().id(UUID.randomUUID()).userId(UUID.randomUUID())
                .range(new TimeRange(start, end)).fixed(fixed).immovable(immovable).build();
    }

    @Test
    void experienceIsCeilOfHalfHoursTimesTen() {
        assertThat(CalendarBlock.experienceFor(30)).isEqualTo(10);
        assertThat(CalendarBlock.experienceFor(31)).isEqualTo(20);
        assertThat(CalendarBlock.experienceFor(90)).isEqualTo(30);
        assertThat(CalendarBlock.experienceFor(240)).isEqualTo(80);
        // Contra el farmeo: un bloque puntúa como mucho 4 h (uno de 24 h daba 480 XP) y hay tope diario.
        assertThat(CalendarBlock.experienceFor(24 * 60)).isEqualTo(80);
        assertThat(CalendarBlock.fitsDailyXp(120, 80)).isTrue();
        assertThat(CalendarBlock.fitsDailyXp(130, 80)).isFalse();
    }

    @Test
    void focusCanOnlyBeRecordedForTodayOrYesterday() {
        LocalDate today = LocalDate.of(2026, 10, 18);
        assertThat(FocusSession.recordedDay(null, today)).isEqualTo(today);
        assertThat(FocusSession.recordedDay(today.plusDays(3), today)).isEqualTo(today);
        assertThat(FocusSession.recordedDay(today.minusDays(1), today)).isEqualTo(today.minusDays(1));
        // Antes se aceptaba cualquier fecha pasada y se podía inventar una racha de un año.
        assertThatThrownBy(() -> FocusSession.recordedDay(today.minusDays(2), today))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void timeRangeRequiresAtLeastThirtyMinutes() {
        assertThatThrownBy(() -> new TimeRange(NOW, NOW)).extracting("code").isEqualTo("BLOCK_INVALID_TIME_RANGE");
        assertThatThrownBy(() -> TimeRange.ofMinutes(NOW, 29)).extracting("code").isEqualTo("BLOCK_INVALID_TIME_RANGE");
        assertThat(TimeRange.ofMinutes(NOW, 30).minutes()).isEqualTo(30);
    }

    @Test
    void lockedAndCompletedBlocksKeepTheirSchedule() {
        Instant start = NOW.plusSeconds(3600);
        TimeRange later = TimeRange.ofMinutes(NOW.plusSeconds(7200), 60);
        assertThatThrownBy(() -> block(start, start.plusSeconds(3600), true, false).moveTo(later, 1, NOW))
                .extracting("code").isEqualTo("BLOCK_LOCKED");
        assertThatThrownBy(() -> block(start, start.plusSeconds(3600), false, true).resize(start.plusSeconds(7200), NOW))
                .extracting("code").isEqualTo("BLOCK_LOCKED");

        CalendarBlock done = block(start, start.plusSeconds(3600), false, false);
        done.complete(NOW, null, null, null);
        assertThatThrownBy(() -> done.moveTo(later, 1, NOW)).extracting("code").isEqualTo("BLOCK_COMPLETED_LOCKED");

        // Un bloque de deporte hecho no puede pasar a reflejar una rutina (ni dejar de hacerlo): con vincular,
        // desmarcar (restaba 0), desvincular y volver a completar se ganaba XP sin límite.
        CalendarBlock sport = CalendarBlock.builder().id(UUID.randomUUID()).userId(UUID.randomUUID())
                .range(new TimeRange(start, start.plusSeconds(3600))).type(ActivityType.SPORT).build();
        sport.complete(NOW, null, null, null);
        CalendarBlock.Details linked = new CalendarBlock.Details(null, "Pierna", null, null, false, null,
                UUID.randomUUID(), null, UUID.randomUUID(), null, null, null);
        assertThatThrownBy(() -> sport.revise(ActivityType.SPORT, linked))
                .extracting("code").isEqualTo("BLOCK_COMPLETED_LOCKED");
        sport.revise(ActivityType.SPORT, CalendarBlock.Details.empty()); // otros cambios sí se permiten
        // Un bloque inamovible sí se actualiza desde su origen (ICS/escaneo).
        CalendarBlock imported = block(start, start.plusSeconds(3600), false, true);
        imported.syncFromSource(later, 1, ActivityType.CLASS, CalendarBlock.Details.empty());
        assertThat(imported.range()).isEqualTo(later);
    }

    @Test
    void resizeCannotLeaveTheBlockInThePast() {
        CalendarBlock running = block(NOW.minusSeconds(1800), NOW.plusSeconds(1800), false, false);
        running.resize(NOW.plusSeconds(3600), NOW);
        assertThat(running.range().minutes()).isEqualTo(90);
        CalendarBlock old = block(NOW.minusSeconds(7200), NOW.minusSeconds(3600), false, false);
        assertThatThrownBy(() -> old.resize(NOW.minusSeconds(1200), NOW)).extracting("code").isEqualTo("BLOCK_IN_PAST");
    }

    @Test
    void conflictsAreStrictOverlapsAndFreeSlotsAreFound() {
        CalendarBlock a = block(NOW, NOW.plusSeconds(3600), false, false);
        CalendarBlock b = block(NOW.plusSeconds(1800), NOW.plusSeconds(5400), false, false);
        CalendarBlock c = block(NOW.plusSeconds(4800), NOW.plusSeconds(9000), false, false);
        List<CalendarBlock> all = List.of(a, b, c);

        assertThat(ScheduleConflicts.pairs(all)).hasSize(2);
        assertThat(ScheduleConflicts.refreshFlags(all)).containsExactlyInAnyOrder(a, b, c);
        assertThat(a.hasConflict() && b.hasConflict() && c.hasConflict()).isTrue();

        Optional<TimeRange> slot = ScheduleConflicts.firstFreeSlot(30, NOW, NOW.plusSeconds(4 * 3600), all);
        assertThat(slot).hasValueSatisfying(s -> assertThat(s.start()).isEqualTo(NOW.plusSeconds(9000)));
        assertThat(ScheduleConflicts.firstFreeSlot(60, NOW, NOW.plusSeconds(9000), all)).isEmpty();
        assertThat(ScheduleConflicts.alignToHalfHour(Instant.parse("2026-10-19T08:07:30Z")))
                .isEqualTo(Instant.parse("2026-10-19T08:30:00Z"));
        assertThat(ScheduleConflicts.alignToHalfHour(NOW)).isEqualTo(NOW);
    }

    @Test
    void weeklyPatternIsMaterializedInLocalTimeAcrossDaylightSavingChanges() {
        UUID user = UUID.randomUUID();
        SubjectRef algebra = new SubjectRef(UUID.randomUUID(), "Álgebra", "ALG", 3, 6, null);
        List<ScheduleEntry> entries = List.of(
                new ScheduleEntry("alg", "Algebra", ClassKind.PRACTICE, 1, LocalTime.of(9, 0), LocalTime.of(11, 0), "B2"),
                new ScheduleEntry(null, "Inventada", null, 8, LocalTime.of(9, 0), LocalTime.of(10, 0), null),
                new ScheduleEntry(null, "Corta", null, 2, LocalTime.of(9, 0), LocalTime.of(9, 15), null));

        // 19/10 (horario de verano) → 02/11 (horario de invierno desde el 25/10).
        WeeklyPatternMaterializer.Result result = WeeklyPatternMaterializer.materialize(user, entries, List.of(algebra),
                LocalDate.of(2026, 10, 19), LocalDate.of(2026, 11, 2), ZONE, UUID::randomUUID, NOW);

        assertThat(result.blocks()).hasSize(3);
        assertThat(result.blocks()).extracting(b -> ZONE.localTime(b.start())).containsOnly(LocalTime.of(9, 0));
        assertThat(result.blocks().get(0).start()).isEqualTo(Instant.parse("2026-10-19T07:00:00Z"));
        assertThat(result.blocks().get(2).start()).isEqualTo(Instant.parse("2026-11-02T08:00:00Z"));
        assertThat(result.blocks()).allSatisfy(b -> {
            assertThat(b.icsUid()).startsWith("ai-alg-2026");
            assertThat(b.subjectId()).isEqualTo(algebra.id());
            assertThat(b.details().topics()).isEqualTo("Algebra (Práctica)");
            assertThat(b.details().location()).isEqualTo("B2");
        });
        assertThat(result.blocks().get(0).icsUid()).isEqualTo("ai-alg-20261019-0900");
        assertThat(result.unmatchedSubjects()).containsExactly("Corta");
    }

    @Test
    void weeklyLoadClampsAndQualifiesOnce() {
        WeeklyAcademicLoad load = WeeklyAcademicLoad.empty(UUID.randomUUID(), UUID.randomUUID(), LocalDate.of(2026, 10, 21));
        assertThat(load.weekStart()).isEqualTo(LocalDate.of(2026, 10, 19));
        load.refresh(200 * 60, 12 * 60, 30, 2);
        assertThat(load.plannedHours()).isEqualTo(120);
        assertThat(load.exams()).isEqualTo(20);
        assertThat(load.qualifiesForStudyExperience(14)).isTrue();
        load.markExperienceAwarded();
        assertThat(load.qualifiesForStudyExperience(14)).isFalse();
        assertThat(WeeklyAcademicLoad.empty(UUID.randomUUID(), UUID.randomUUID(), LocalDate.of(2026, 10, 19))
                .qualifiesForStudyExperience(0)).isFalse();
    }

    @Test
    void balanceStates() {
        assertThat(WeekBalance.stateFor(0, 0)).isEqualTo(WeekBalance.State.INACTIVE);
        assertThat(WeekBalance.stateFor(10, 1)).isEqualTo(WeekBalance.State.STUDY_HEAVY);
        assertThat(WeekBalance.stateFor(6, 4)).isEqualTo(WeekBalance.State.BALANCED);
        assertThat(WeekBalance.stateFor(2, 8)).isEqualTo(WeekBalance.State.SPORT_HEAVY);
    }

    @Test
    void subjectMatcherIgnoresCaseAndAccents() {
        assertThat(SubjectMatcher.mentions("EXAMEN de algebra LINEAL", "Álgebra Lineal", null)).isTrue();
        assertThat(SubjectMatcher.mentions("Tema 2 [ALG-01]", "Otra cosa", "alg-01")).isTrue();
        assertThat(SubjectMatcher.mentions("Programación avanzada", "Programación Orientada a Objetos", null)).isFalse();
        assertThat(ZoneId.of("Europe/Madrid")).isEqualTo(ZONE.zone());
    }

    @Test
    void blocksMirroringATrackedActivityGiveNoExperience() {
        Instant start = Instant.parse("2026-10-20T16:00:00Z");
        CalendarBlock routineSport = CalendarBlock.builder().id(UUID.randomUUID()).userId(UUID.randomUUID())
                .range(TimeRange.ofMinutes(start, 60)).type(ActivityType.SPORT)
                .details(new CalendarBlock.Details(null, null, null, Priority.MEDIUM, false, null, UUID.randomUUID(),
                        null, UUID.randomUUID(), null, null, null)).build();
        CalendarBlock materialReview = CalendarBlock.builder().id(UUID.randomUUID()).userId(UUID.randomUUID())
                .range(TimeRange.ofMinutes(start, 30)).type(ActivityType.REVIEW).studyMaterialId(UUID.randomUUID())
                .build();
        CalendarBlock freeSport = CalendarBlock.builder().id(UUID.randomUUID()).userId(UUID.randomUUID())
                .range(TimeRange.ofMinutes(start, 60)).type(ActivityType.SPORT).build();

        assertThat(routineSport.experienceReward()).isZero();
        assertThat(materialReview.experienceReward()).isZero();
        assertThat(freeSport.experienceReward()).isEqualTo(20);
    }

    @Test
    void activityDefinitionsAreTheSingleSourceForOtherModules() {
        assertThat(ActivityType.codesWhere(ActivityType::isCognitive))
                .containsExactlyInAnyOrder("estudio", "clase", "repaso", "examen", "entrega");
        assertThat(ActivityType.codesWhere(ActivityType::countsAsStudy)).containsExactlyInAnyOrder("estudio", "repaso");
        assertThat(ActivityType.isCognitiveCode("deporte")).isFalse();
        assertThat(ActivityType.isCognitiveCode("desconocido")).isFalse();
        assertThat(ActivityType.countsAsStudyCode("repaso")).isTrue();
    }

    @Test
    void weeklyStudyBonusIsLostOnlyWhileAwardedAndBelowTheGoal() {
        WeeklyAcademicLoad load = WeeklyAcademicLoad.empty(UUID.randomUUID(), UUID.randomUUID(),
                LocalDate.parse("2026-10-19"));
        load.refresh(600, 600, 0, 0);
        assertThat(load.qualifiesForStudyExperience(10)).isTrue();
        assertThat(load.losesStudyExperience(10)).isFalse();
        load.markExperienceAwarded();

        load.refresh(600, 300, 0, 0);
        assertThat(load.losesStudyExperience(10)).isTrue();
        load.markExperienceRevoked();
        assertThat(load.losesStudyExperience(10)).isFalse();
    }

    @Test
    void focusRewardsAreCappedPerDayAndOnlyForTodaysFocus() {
        LocalDate today = LocalDate.parse("2026-10-19");
        FocusSession focus = new FocusSession(UUID.randomUUID(), UUID.randomUUID(), FocusSession.FocusPhase.FOCUS, 50,
                4, true, today, null, null, 0, Instant.parse("2026-10-19T10:00:00Z"));

        // 50 minutos solo justifican 5 ciclos de 10 min; se piden 4: 20 XP, recortados por el tope restante.
        assertThat(FocusRewards.xpFor(focus, today, 0)).isEqualTo(20);
        assertThat(FocusRewards.xpFor(focus, today, 15)).isEqualTo(5);
        assertThat(FocusRewards.xpFor(focus, today, FocusRewards.DAILY_CAP)).isZero();
        assertThat(FocusRewards.xpFor(focus, today.plusDays(1), 0)).isZero();
        FocusSession pause = new FocusSession(UUID.randomUUID(), UUID.randomUUID(),
                FocusSession.FocusPhase.SHORT_BREAK, 5, 1, true, today, null, null, 0, Instant.parse("2026-10-19T10:00:00Z"));
        assertThat(FocusRewards.xpFor(pause, today, 0)).isZero();
    }

    @Test
    void focusRewardStatusExplainsWhyThereIsNoExperience() {
        LocalDate today = LocalDate.parse("2026-10-19");
        Instant at = Instant.parse("2026-10-19T10:00:00Z");
        FocusSession focus = new FocusSession(UUID.randomUUID(), UUID.randomUUID(), FocusSession.FocusPhase.FOCUS, 25,
                1, true, today, null, null, 0, at);

        assertThat(FocusRewards.evaluate(focus, today, 0))
                .isEqualTo(new FocusRewards.Reward(5, FocusXpStatus.AWARDED));
        assertThat(FocusRewards.evaluate(focus, today, FocusRewards.DAILY_CAP - 2))
                .isEqualTo(new FocusRewards.Reward(2, FocusXpStatus.AWARDED));
        assertThat(FocusRewards.evaluate(focus, today, FocusRewards.DAILY_CAP))
                .isEqualTo(new FocusRewards.Reward(0, FocusXpStatus.DAILY_CAP_REACHED));
        assertThat(FocusRewards.evaluate(focus, today.plusDays(1), 0).status()).isEqualTo(FocusXpStatus.NOT_ELIGIBLE);
        FocusSession tooShort = new FocusSession(UUID.randomUUID(), UUID.randomUUID(), FocusSession.FocusPhase.FOCUS,
                FocusRewards.MIN_CYCLE_MINUTES - 1, 1, true, today, null, null, 0, at);
        // Aunque el tope esté agotado, una fase demasiado corta no es «tope alcanzado».
        assertThat(FocusRewards.evaluate(tooShort, today, FocusRewards.DAILY_CAP).status())
                .isEqualTo(FocusXpStatus.NOT_ELIGIBLE);
        FocusSession unfinished = new FocusSession(UUID.randomUUID(), UUID.randomUUID(),
                FocusSession.FocusPhase.FOCUS, 25, 1, false, today, null, null, 0, at);
        assertThat(FocusRewards.evaluate(unfinished, today, 0).status()).isEqualTo(FocusXpStatus.NOT_ELIGIBLE);
    }
}
