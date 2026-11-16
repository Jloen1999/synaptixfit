package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.run.CreateRunWorkoutUseCase;
import com.synaptixfit.application.port.input.run.ListRunWorkoutsUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineFromTemplateUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.GetStartingLoadsUseCase;
import com.synaptixfit.application.port.input.training.ListRoutineTemplatesUseCase;
import com.synaptixfit.application.port.input.training.RoutineStructureInput;
import com.synaptixfit.domain.exception.training.RoutineTemplateNotFoundException;
import com.synaptixfit.domain.model.run.RunWorkout;
import com.synaptixfit.domain.model.run.RunWorkoutTemplates;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.port.output.training.RoutineTemplateRepositoryPort;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Plantillas de rutina (ADR 0032): las lista con {@link RoutineTemplateRepositoryPort} y convierte una en
 * rutina propia delegando el alta en {@link CreateRoutineUseCase} (mismas reglas que crear a mano). Cada
 * semana repite los días de la plantilla con el tipo que le toca por posición; la suave quita una serie
 * ({@link RoutineTemplate#parametersFor}). Los días de carrera (ADR 0043) no entran en la rutina: se crean como
 * entrenos de carrera en Entreno › Correr ({@link CreateRunWorkoutUseCase}), uno por código que la persona aún no
 * tenga, para que se graben con el GPS y cuenten como actividad.
 *
 * <p>ADR 0054: solo se ofrecen y se usan las plantillas activas; cada día lleva el nombre de su sesión y cada
 * ejercicio su rango de repeticiones y su peso de partida ({@link GetStartingLoadsUseCase}). Un plan de carrera
 * progresivo crea un entreno por semana.
 */
public class RoutineTemplateService implements ListRoutineTemplatesUseCase, CreateRoutineFromTemplateUseCase {

    private final RoutineTemplateRepositoryPort templates;
    private final CreateRoutineUseCase createRoutine;
    private final ListRunWorkoutsUseCase listRunWorkouts;
    private final CreateRunWorkoutUseCase createRunWorkout;
    private final GetStartingLoadsUseCase startingLoads;

    public RoutineTemplateService(RoutineTemplateRepositoryPort templates, CreateRoutineUseCase createRoutine,
                                  ListRunWorkoutsUseCase listRunWorkouts, CreateRunWorkoutUseCase createRunWorkout,
                                  GetStartingLoadsUseCase startingLoads) {
        this.templates = templates;
        this.createRoutine = createRoutine;
        this.listRunWorkouts = listRunWorkouts;
        this.createRunWorkout = createRunWorkout;
        this.startingLoads = startingLoads;
    }

    @Override
    public List<RoutineTemplate> list(String language) {
        return templates.findAll(language).stream().filter(t -> t.active() && !t.days().isEmpty()).toList();
    }

    @Override
    public Routine createFromTemplate(UUID userId, UUID templateId, String language) {
        RoutineTemplate template = templates.findById(templateId, language)
                .filter(t -> t.active() && !t.days().isEmpty())
                .orElseThrow(() -> new RoutineTemplateNotFoundException(templateId));
        Map<UUID, Double> weights = startingLoads.startingLoads(userId, template.exerciseIds(), template.level());
        List<RoutineStructureInput.Week> weeks = new ArrayList<>();
        for (int number = 1; number <= template.weeks(); number++) {
            WeekType type = WeekType.forPosition(number, template.weeks());
            List<RoutineStructureInput.Day> days = template.days().stream()
                    .map(d -> new RoutineStructureInput.Day(d.dayNumber(), d.name(), d.exercises().stream()
                            .map(e -> new RoutineStructureInput.Exercise(e.exerciseId(),
                                    RoutineTemplate.parametersFor(e, type, weights.get(e.exerciseId()))))
                            .toList()))
                    .toList();
            weeks.add(new RoutineStructureInput.Week(null, type, days));
        }
        Routine routine = createRoutine.create(new CreateRoutineUseCase.Command(userId, template.name(),
                template.description(), Visibility.PRIVATE, template.goal(), null, weeks));
        addRunWorkouts(userId, template);
        return routine;
    }

    /** Crea los entrenos de carrera de la plantilla que la persona aún no tiene (por código de plantilla). */
    private void addRunWorkouts(UUID userId, RoutineTemplate template) {
        if (template.runDays().isEmpty()) {
            return;
        }
        Set<String> owned = listRunWorkouts.listWorkouts(userId).stream()
                .map(RunWorkout::templateCode).filter(Objects::nonNull).collect(Collectors.toSet());
        for (RoutineTemplate.RunDay day : template.distinctRunWorkouts()) {
            if (owned.contains(day.workoutCode())) {
                continue;
            }
            RunWorkoutTemplates.find(day.workoutCode())
                    .ifPresent(t -> createRunWorkout.createWorkout(new CreateRunWorkoutUseCase.Command(userId,
                            day.workoutName() == null || day.workoutName().isBlank() ? t.code() : day.workoutName(),
                            t.code(), t.groups())));
        }
    }
}
