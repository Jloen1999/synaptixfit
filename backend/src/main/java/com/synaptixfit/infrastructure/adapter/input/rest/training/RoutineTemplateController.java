package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.CreateRoutineFromTemplateUseCase;
import com.synaptixfit.application.port.input.training.ListRoutineTemplatesUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.RoutineResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineTemplateDtos.RoutineTemplateResponse;
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

    @GetMapping
    public List<RoutineTemplateResponse> list() {
        return list.list(RequestLanguage.code()).stream().map(RoutineTemplateResponse::from).toList();
    }

    /** Crea una rutina propia y privada a partir de la plantilla (y sus entrenos de carrera, si lleva). */
    @PostMapping("/{templateId}/use")
    @ResponseStatus(HttpStatus.CREATED)
    public RoutineResponse use(@CurrentUserId UUID userId, @PathVariable UUID templateId) {
        return RoutineResponse.from(create.createFromTemplate(userId, templateId, RequestLanguage.code()), null,
                userId);
    }
}
