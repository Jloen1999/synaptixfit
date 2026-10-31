package com.synaptixfit.domain.model.profile;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.profile.SetupChecklist.SetupTask;
import com.synaptixfit.domain.model.user.UsageFocus;
import org.junit.jupiter.api.Test;

class SetupChecklistTest {

    private static OnboardingStatus status(UsageFocus focus, boolean wellness, boolean academic, boolean subjects) {
        return new OnboardingStatus(true, focus, wellness, academic, subjects, true);
    }

    @Test
    void aNewUserWithBothFocusesSeesEverythingInOrderOfImportance() {
        SetupChecklist c = SetupChecklist.of(status(UsageFocus.BOTH, false, false, false), false, false);
        assertThat(c.pending()).containsExactly(SetupTask.SUBJECTS, SetupTask.WELLNESS_PROFILE, SetupTask.ROUTINE,
                SetupTask.WEEK_PLAN, SetupTask.ACADEMIC_PROFILE);
        assertThat(c.total()).isEqualTo(5);
    }

    @Test
    void onlyTheTasksOfTheChosenFocusApply() {
        SetupChecklist academic = SetupChecklist.of(status(UsageFocus.ACADEMIC, false, true, false), false, true);
        assertThat(academic.pending()).containsExactly(SetupTask.SUBJECTS);
        assertThat(academic.total()).isEqualTo(3);

        SetupChecklist fitness = SetupChecklist.of(status(UsageFocus.FITNESS, true, false, false), false, false);
        assertThat(fitness.pending()).containsExactly(SetupTask.ROUTINE, SetupTask.WEEK_PLAN);
        assertThat(fitness.total()).isEqualTo(3);
    }

    @Test
    void nothingPendingWhenAllIsDone() {
        assertThat(SetupChecklist.of(status(UsageFocus.BOTH, true, true, true), true, true).pending()).isEmpty();
    }
}
