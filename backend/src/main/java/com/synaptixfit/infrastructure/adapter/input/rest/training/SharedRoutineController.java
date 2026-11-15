package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.CopySharedRoutineUseCase;
import com.synaptixfit.application.port.input.training.PreviewSharedRoutineUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.RoutineResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineShareDtos.SharedRoutineRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineShareDtos.SharedRoutineResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Abrir un enlace de rutina (ADR 0043): resumen ({@link PreviewSharedRoutineUseCase}) y «Copiar a mis rutinas»
 * ({@link CopySharedRoutineUseCase}). El token va en el cuerpo, no en la ruta, para que no quede en los registros de
 * acceso; nginx limita las peticiones por IP. El resumen no lleva nada del dueño.
 */
@Tag(name = "Routines")
@RestController
@RequestMapping("/api/v1/shared-routines")
public class SharedRoutineController {

    private final PreviewSharedRoutineUseCase preview;
    private final CopySharedRoutineUseCase copy;

    public SharedRoutineController(PreviewSharedRoutineUseCase preview, CopySharedRoutineUseCase copy) {
        this.preview = preview;
        this.copy = copy;
    }

    @PostMapping("/preview")
    public SharedRoutineResponse preview(@CurrentUserId UUID userId,
                                         @Valid @RequestBody SharedRoutineRequest request) {
        return SharedRoutineResponse.from(preview.previewSharedRoutine(userId, request.token()));
    }

    /** Copia privada en «Mis rutinas», sin progreso ni datos del dueño. */
    @PostMapping("/copy")
    @ResponseStatus(HttpStatus.CREATED)
    public RoutineResponse copy(@CurrentUserId UUID userId, @Valid @RequestBody SharedRoutineRequest request) {
        return RoutineResponse.from(copy.copySharedRoutine(userId, request.token()), null, userId);
    }
}
