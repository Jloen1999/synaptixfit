package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.CreateRoutineFromTemplateUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.ListRoutineTemplatesUseCase;
import com.synaptixfit.application.port.input.training.RoutineStructureInput;
import com.synaptixfit.domain.exception.training.RoutineTemplateNotFoundException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.port.output.training.RoutineTemplateRepositoryPort;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Plantillas de rutina (ADR 0032): las lista con {@link RoutineTemplateRepositoryPort} y convierte una en
 * rutina propia delegando el alta en {@link CreateRoutineUseCase} (mismas reglas que crear a mano). Cada
 * semana repite los días de la plantilla con el tipo que le toca por posición; la suave quita una serie
 * ({@link RoutineTemplate#parametersFor}).
 */
public class RoutineTemplateService implements ListRoutineTemplatesUseCase, CreateRoutineFromTemplateUseCase {

    private final RoutineTemplateRepositoryPort templates;
    private final CreateRoutineUseCase createRoutine;

    public RoutineTemplateService(RoutineTemplateRepositoryPort templates, CreateRoutineUseCase createRoutine) {
        this.templates = templates;
        this.createRoutine = createRoutine;
    }

    @Override
    public List<RoutineTemplate> list(String language) {
        return templates.findAll(language).stream().filter(t -> !t.days().isEmpty()).toList();
    }

    @Override
    public Routine createFromTemplate(UUID userId, UUID templateId, String language) {
        RoutineTemplate template = templates.findById(templateId, language)
                .filter(t -> !t.days().isEmpty())
                .orElseThrow(() -> new RoutineTemplateNotFoundException(templateId));
        List<RoutineStructureInput.Week> weeks = new ArrayList<>();
        for (int number = 1; number <= template.weeks(); number++) {
            WeekType type = WeekType.forPosition(number, template.weeks());
            List<RoutineStructureInput.Day> days = template.days().stream()
                    .map(d -> new RoutineStructureInput.Day(d.dayNumber(), null, d.exercises().stream()
                            .map(e -> new RoutineStructureInput.Exercise(e.exerciseId(),
                                    RoutineTemplate.parametersFor(e, type)))
                            .toList()))
                    .toList();
            weeks.add(new RoutineStructureInput.Week(null, type, days));
        }
        return createRoutine.create(new CreateRoutineUseCase.Command(userId, template.name(), template.description(),
                Visibility.PRIVATE, template.goal(), null, weeks));
    }
}
