package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.run.CreateRunWorkoutUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.RoutineStructureInput;
import com.synaptixfit.domain.exception.training.RoutineTemplateNotFoundException;
import com.synaptixfit.domain.model.run.RunWorkout;
import com.synaptixfit.domain.model.run.RunWorkoutTemplates;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.TemplateLevel;
import com.synaptixfit.domain.model.training.TemplatePlace;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.port.output.training.RoutineTemplateRepositoryPort;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;

/**
 * Plantillas: se listan las que tienen ejercicios y una se convierte en rutina privada con semana suave; los días de
 * carrera crean los entrenos de carrera que la persona aún no tiene (ADR 0043).
 */
class RoutineTemplateServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final UUID EXERCISE = UUID.randomUUID();

    private final RoutineTemplate template = new RoutineTemplate(UUID.randomUUID(), "casa_2", "En casa · 2 días",
            "Sin material", TrainingGoal.STRENGTH_ENDURANCE, TemplatePlace.HOME, TemplateLevel.BEGINNER, false, 35, 4,
            List.of(new RoutineTemplate.Day(2, List.of(new RoutineTemplate.Item(EXERCISE, 3, 12, 60, null))),
                    new RoutineTemplate.Day(5, List.of(new RoutineTemplate.Item(EXERCISE, 2, 10, 60, null)))),
            List.of());
    private final RoutineTemplate empty = new RoutineTemplate(UUID.randomUUID(), "vacia", "Vacía", "",
            TrainingGoal.HYPERTROPHY, TemplatePlace.GYM, TemplateLevel.BEGINNER, false, 30, 2, List.of(), List.of());
    private final RoutineTemplate running = new RoutineTemplate(UUID.randomUUID(), "cero_a_cinco_km", "De 0 a 5 km",
            "", TrainingGoal.METABOLIC_CONDITIONING, TemplatePlace.OUTDOOR, TemplateLevel.BEGINNER, false, 30, 8,
            List.of(new RoutineTemplate.Day(4, List.of(new RoutineTemplate.Item(EXERCISE, 2, 12, 60, null)))),
            List.of(new RoutineTemplate.RunDay(1, "START_WALK_RUN", "Empieza a correr"),
                    new RoutineTemplate.RunDay(3, "STEADY_20", "Ritmo constante 20 min"),
                    new RoutineTemplate.RunDay(6, "START_WALK_RUN", "Empieza a correr")));

    private final List<RunWorkout> ownedRunWorkouts = new ArrayList<>();
    private final List<CreateRunWorkoutUseCase.Command> createdRuns = new ArrayList<>();

    private final AtomicReference<CreateRoutineUseCase.Command> created = new AtomicReference<>();

    private final RoutineTemplateService service = new RoutineTemplateService(new RoutineTemplateRepositoryPort() {
        @Override
        public List<RoutineTemplate> findAll(String language) {
            return List.of(template, empty, running);
        }

        @Override
        public Optional<RoutineTemplate> findById(UUID templateId, String language) {
            return findAll(language).stream().filter(t -> t.id().equals(templateId)).findFirst();
        }
    }, command -> {
        created.set(command);
        return null;
    }, userId -> ownedRunWorkouts, command -> {
        createdRuns.add(command);
        return null;
    });

    @Test
    void listsOnlyTemplatesWithExercises() {
        assertThat(service.list("es")).extracting(RoutineTemplate::code).containsExactly("casa_2", "cero_a_cinco_km");
    }

    @Test
    void createsAPrivateRoutineRepeatingTheDaysWithAnEasyLastWeek() {
        Routine ignored = service.createFromTemplate(USER, template.id(), "es");

        CreateRoutineUseCase.Command c = created.get();
        assertThat(ignored).isNull();
        assertThat(c.userId()).isEqualTo(USER);
        assertThat(c.name()).isEqualTo("En casa · 2 días");
        assertThat(c.visibility()).isEqualTo(Visibility.PRIVATE);
        assertThat(c.goal()).isEqualTo(TrainingGoal.STRENGTH_ENDURANCE);
        assertThat(c.weeks()).hasSize(4);
        assertThat(c.weeks()).extracting(RoutineStructureInput.Week::type)
                .containsExactly(WeekType.ADAPTATION, WeekType.LOAD, WeekType.LOAD, WeekType.DELOAD);
        assertThat(c.weeks().getFirst().days()).extracting(RoutineStructureInput.Day::dayNumber).containsExactly(2, 5);
        assertThat(c.weeks().getLast().days().getFirst().exercises().getFirst().parameters().sets()).isEqualTo(2);
        assertThat(c.weeks().getFirst().days().getFirst().exercises().getFirst().parameters().sets()).isEqualTo(3);
    }

    @Test
    void runDaysCountPerWeekButOnlyStrengthDaysGoToTheRoutine() {
        assertThat(running.daysPerWeek()).isEqualTo(4);
        assertThat(running.atHome()).isFalse();

        service.createFromTemplate(USER, running.id(), "es");

        assertThat(created.get().weeks()).hasSize(8);
        assertThat(created.get().weeks().getFirst().days()).extracting(RoutineStructureInput.Day::dayNumber)
                .containsExactly(4);
    }

    @Test
    void createsEachMissingRunWorkoutOnceWithItsTemplateSteps() {
        ownedRunWorkouts.add(new RunWorkout(UUID.randomUUID(), USER, "Mío", "STEADY_20",
                RunWorkoutTemplates.ALL.get(4).groups(), Instant.EPOCH, Instant.EPOCH));

        service.createFromTemplate(USER, running.id(), "es");

        assertThat(createdRuns).extracting(CreateRunWorkoutUseCase.Command::templateCode)
                .containsExactly("START_WALK_RUN");
        assertThat(createdRuns.getFirst().name()).isEqualTo("Empieza a correr");
        assertThat(createdRuns.getFirst().groups()).isEqualTo(RunWorkoutTemplates.ALL.getFirst().groups());
    }

    @Test
    void aTemplateWithoutRunDaysCreatesNoRunWorkouts() {
        service.createFromTemplate(USER, template.id(), "es");

        assertThat(createdRuns).isEmpty();
    }

    @Test
    void unknownOrEmptyTemplateIsNotFound() {
        assertThatThrownBy(() -> service.createFromTemplate(USER, UUID.randomUUID(), "es"))
                .isInstanceOf(RoutineTemplateNotFoundException.class);
        assertThatThrownBy(() -> service.createFromTemplate(USER, empty.id(), "es"))
                .isInstanceOf(RoutineTemplateNotFoundException.class);
    }
}
