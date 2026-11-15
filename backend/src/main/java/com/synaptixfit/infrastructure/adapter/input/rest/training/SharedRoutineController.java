package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.CopySharedRoutineUseCase;
import com.synaptixfit.application.port.input.training.PreviewSharedRoutineUseCase;
import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.RoutineResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;
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

    /** Token del enlace tal como llega en la dirección. */
    public record SharedRoutineRequest(@NotBlank @Size(max = 128) String token) {
    }

    /** Ejercicio del resumen: nombre, foto y series de la primera semana. */
    public record SharedExerciseResponse(UUID exerciseId, String name, String imageUrl, int sets) {
    }

    /** Día de la primera semana con sus ejercicios. */
    public record SharedDayResponse(int dayNumber, String name, int estimatedMinutes,
                                    List<SharedExerciseResponse> exercises) {
    }

    /** Resumen de la rutina compartida: nombre, objetivo, semanas, días por semana y la primera semana. */
    public record SharedRoutineResponse(String name, String description, TrainingGoal goal, int durationWeeks,
                                        int daysPerWeek, int exerciseCount, List<SharedDayResponse> firstWeek) {
        static SharedRoutineResponse from(Routine r) {
            List<RoutineDay> days = r.weeks().stream().findFirst().map(RoutineWeek::days).orElse(List.of());
            return new SharedRoutineResponse(r.name(), r.description(), r.goal(), r.durationWeeks(), days.size(),
                    r.exerciseCount(), days.stream().map(d -> new SharedDayResponse(d.number(), d.name(),
                            d.estimatedMinutes(), d.exercises().stream().map(SharedRoutineResponse::exercise)
                            .toList())).toList());
        }

        private static SharedExerciseResponse exercise(PlannedExercise e) {
            ExerciseRef ref = e.exercise();
            return new SharedExerciseResponse(ref.id(), ref.name(), ref.stillImageUrl(), e.parameters().sets());
        }
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
