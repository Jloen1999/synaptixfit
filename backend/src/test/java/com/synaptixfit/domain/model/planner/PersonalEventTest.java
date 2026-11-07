package com.synaptixfit.domain.model.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Reglas del tipo de evento «Personal» (ADR 0035): el día a día, sin XP ni carga de estudio. */
class PersonalEventTest {

    private static final Instant START = Instant.parse("2026-10-22T08:00:00Z");

    private static CalendarBlock personal(String name) {
        return CalendarBlock.builder().id(UUID.randomUUID()).userId(UUID.randomUUID())
                .range(TimeRange.ofMinutes(START, 90)).type(ActivityType.PERSONAL)
                .details(new CalendarBlock.Details(null, name, null, Priority.MEDIUM, false, null, null, null, null,
                        null, null, null))
                .build();
    }

    @Test
    void givesNoExperienceNorStudyLoad() {
        assertThat(ActivityType.PERSONAL.grantsExperience()).isFalse();
        assertThat(ActivityType.PERSONAL.isCognitive()).isFalse();
        assertThat(ActivityType.PERSONAL.countsAsStudy()).isFalse();
        assertThat(personal("Dentista").experienceReward()).isZero();
        assertThat(personal("Dentista").countsAsPhysicalActivity()).isFalse();
        assertThat(ActivityType.codesWhere(ActivityType::isCognitive)).doesNotContain("personal");
    }

    @Test
    void isAlwaysVisibleAndCountsInTheWeekPlan() {
        for (UsageFocus focus : UsageFocus.values()) {
            assertThat(ActivityType.PERSONAL.visibleFor(focus)).isTrue();
        }
        assertThat(ActivityType.PERSONAL.countsInWeekPlan()).isTrue();
        assertThat(ActivityType.REST.countsInWeekPlan()).isFalse();
        assertThat(ActivityType.PERSONAL.canRepeatWeekly()).isTrue();
    }

    @Test
    void canBeMarkedAndIsLeftUndoneIfItPassesUnmarked() {
        CalendarBlock dentist = personal("Dentista");

        assertThat(dentist.timeStatus(START.plusSeconds(4 * 3600))).isEqualTo(ItemTimeStatus.MISSED);
        assertThat(dentist.complete(START.plusSeconds(60), null, null, null)).isTrue();
        assertThat(dentist.timeStatus(START.plusSeconds(4 * 3600))).isEqualTo(ItemTimeStatus.DONE);
    }

    @Test
    void needsAName() {
        assertThatThrownBy(() -> personal("  ")).isInstanceOf(FieldValidationException.class)
                .extracting("field").isEqualTo("topics");
        CalendarBlock study = CalendarBlock.builder().id(UUID.randomUUID()).userId(UUID.randomUUID())
                .range(TimeRange.ofMinutes(START, 60)).type(ActivityType.STUDY).build();
        assertThatThrownBy(() -> study.revise(ActivityType.PERSONAL, CalendarBlock.Details.empty()))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void theCodeIsStoredAsPersonal() {
        assertThat(ActivityType.fromCode("personal")).isEqualTo(ActivityType.PERSONAL);
    }
}
