package com.synaptixfit.domain.model.run;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.run.RunStep.Type;
import com.synaptixfit.domain.model.run.RunWorkout.Group;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Entrenos de carrera por pasos: validación, duración prevista y plantillas. */
class RunWorkoutTest {

    private static final Instant NOW = Instant.parse("2026-11-07T10:00:00Z");

    private static RunWorkout workout(List<Group> groups) {
        return new RunWorkout(UUID.randomUUID(), UUID.randomUUID(), " Series ", null, groups, NOW, NOW);
    }

    @Test
    void intervalsEstimateTheirDurationAtTheReferencePace() {
        // 10 min + 6 × (800 m a 6:00 = 288 s + 2 min) + 10 min = 1200 + 2448 = 3648 s.
        RunWorkout w = workout(List.of(
                Group.once(RunStep.time(Type.WARMUP, 600)),
                new Group(6, List.of(RunStep.distance(Type.RUN, 800), RunStep.time(Type.RECOVER, 120))),
                Group.once(RunStep.time(Type.COOLDOWN, 600))));

        assertThat(w.name()).isEqualTo("Series");
        assertThat(w.estimatedSeconds()).isEqualTo(3648);
    }

    @Test
    void stepsAndGroupsHaveLimits() {
        assertThatThrownBy(() -> RunStep.time(Type.RUN, 5)).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> RunStep.distance(Type.RUN, 10)).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> new Group(0, List.of(RunStep.time(Type.RUN, 60))))
                .isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> new Group(1, List.of())).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> workout(List.of())).isInstanceOf(FieldValidationException.class);
        // 30 × 6 pasos = 180, más otros 30 × 1 = 210 > 200.
        List<RunStep> six = List.of(RunStep.time(Type.RUN, 60), RunStep.time(Type.RECOVER, 60),
                RunStep.time(Type.RUN, 60), RunStep.time(Type.RECOVER, 60), RunStep.time(Type.RUN, 60),
                RunStep.time(Type.RECOVER, 60));
        assertThatThrownBy(() -> workout(List.of(new Group(30, six),
                new Group(30, List.of(RunStep.time(Type.RUN, 60))))))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void templatesAreValidAndHaveUniqueCodes() {
        assertThat(RunWorkoutTemplates.ALL).hasSizeBetween(5, 6);
        assertThat(RunWorkoutTemplates.ALL.stream().map(RunWorkoutTemplates.Template::code).distinct().count())
                .isEqualTo(RunWorkoutTemplates.ALL.size());
        RunWorkoutTemplates.ALL.forEach(t -> assertThat(workout(t.groups()).estimatedSeconds()).isPositive());
    }
}
