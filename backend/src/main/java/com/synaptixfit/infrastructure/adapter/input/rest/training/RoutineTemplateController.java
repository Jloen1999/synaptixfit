package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.CreateRoutineFromTemplateUseCase;
import com.synaptixfit.application.port.input.training.ListRoutineTemplatesUseCase;
import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.RoutineResponse;
import com.synaptixfit.infrastructure.i18n.RequestLanguage;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Plantillas de rutina listas para usar ({@link ListRoutineTemplatesUseCase}) y alta de una rutina propia a
 * partir de una ({@link CreateRoutineFromTemplateUseCase}). Los textos van en el idioma de la app.
 */
@Tag(name = "Routine templates")
@RestController
@RequestMapping("/api/v1/training/templates")
public class RoutineTemplateController {

    private final ListRoutineTemplatesUseCase list;
    private final CreateRoutineFromTemplateUseCase create;

    public RoutineTemplateController(ListRoutineTemplatesUseCase list, CreateRoutineFromTemplateUseCase create) {
        this.list = list;
        this.create = create;
    }

    /** Plantilla resumida: días por semana, objetivo, para casa o semanas de exámenes y ejercicios por día. */
    public record RoutineTemplateResponse(UUID id, String code, String name, String description, TrainingGoal goal,
                                          boolean atHome, boolean forExams, int minutes, int weeks, int daysPerWeek,
                                          List<Integer> dayNumbers, int exerciseCount) {
        static RoutineTemplateResponse from(RoutineTemplate t) {
            return new RoutineTemplateResponse(t.id(), t.code(), t.name(), t.description(), t.goal(), t.atHome(),
                    t.forExams(), t.minutes(), t.weeks(), t.daysPerWeek(),
                    t.days().stream().map(RoutineTemplate.Day::dayNumber).toList(),
                    t.days().stream().mapToInt(d -> d.exercises().size()).sum());
        }
    }

    @GetMapping
    public List<RoutineTemplateResponse> list() {
        return list.list(RequestLanguage.code()).stream().map(RoutineTemplateResponse::from).toList();
    }

    /** Crea una rutina propia y privada a partir de la plantilla. */
    @PostMapping("/{templateId}/use")
    @ResponseStatus(HttpStatus.CREATED)
    public RoutineResponse use(@CurrentUserId UUID userId, @PathVariable UUID templateId) {
        return RoutineResponse.from(create.createFromTemplate(userId, templateId, RequestLanguage.code()), null,
                userId);
    }
}
