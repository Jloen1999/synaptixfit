package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.training.RoutineTemplateNotFoundException;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.RoutineTemplateDetail;
import com.synaptixfit.domain.model.training.TemplateLevel;
import com.synaptixfit.domain.model.training.TemplatePlace;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.port.output.training.RoutineTemplateRepositoryPort;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** El detalle de una plantilla trae sus ejercicios con nombre y solo se enseña si se ofrece. */
class RoutineTemplateDetailServiceTest {

    private final TrainingFakes.Exercises exercises = new TrainingFakes.Exercises();
    private final Exercise squat = exercises.add(TrainingFakes.strength("Sentadilla", "Cuádriceps"));
    private final UUID gone = UUID.randomUUID();

    private final RoutineTemplate offered = template(true, List.of(new RoutineTemplate.Day(1, "Piernas",
            List.of(new RoutineTemplate.Item(squat.id(), 3, 8, 90, null, 8, 12, 2),
                    new RoutineTemplate.Item(gone, 2, 10, 60, null)))));
    private final RoutineTemplate retired = template(false, offered.days());
    private final RoutineTemplate empty = template(true, List.of());

    private final RoutineTemplateDetailService service = new RoutineTemplateDetailService(
            new RoutineTemplateRepositoryPort() {
                @Override
                public List<RoutineTemplate> findAll(String language) {
                    return List.of(offered, retired, empty);
                }

                @Override
                public Optional<RoutineTemplate> findById(UUID id, String language) {
                    return findAll(language).stream().filter(t -> t.id().equals(id)).findFirst();
                }
            }, exercises);

    @Test
    void returnsTheDaysWithTheNameOfEachExercise() {
        RoutineTemplateDetail detail = service.getTemplate(offered.id(), "es");

        assertThat(detail.template()).isEqualTo(offered);
        assertThat(detail.exercises()).containsOnlyKeys(squat.id());
        assertThat(detail.exercises().get(squat.id()).name()).isEqualTo("Sentadilla");
    }

    @Test
    void aRetiredOrEmptyTemplateIsNotFound() {
        assertThatThrownBy(() -> service.getTemplate(retired.id(), "es"))
                .isInstanceOf(RoutineTemplateNotFoundException.class);
        assertThatThrownBy(() -> service.getTemplate(empty.id(), "es"))
                .isInstanceOf(RoutineTemplateNotFoundException.class);
        assertThatThrownBy(() -> service.getTemplate(UUID.randomUUID(), "es"))
                .isInstanceOf(RoutineTemplateNotFoundException.class);
    }

    private static RoutineTemplate template(boolean active, List<RoutineTemplate.Day> days) {
        return new RoutineTemplate(UUID.randomUUID(), "piernas", "Piernas", "", TrainingGoal.HYPERTROPHY,
                TemplatePlace.GYM, TemplateLevel.BEGINNER, false, 45, 4, days, List.of(), active);
    }
}
