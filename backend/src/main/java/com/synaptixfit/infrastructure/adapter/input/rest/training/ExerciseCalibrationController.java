package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.CalibrateExerciseUseCase;
import com.synaptixfit.application.port.input.training.ListSessionCalibrationsUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.CalibrationDtos.CalibrateRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.CalibrationDtos.CalibrationTargetResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Calibración del peso en la sesión en vivo (ADR 0054): qué ejercicios de la sesión se calibran y la respuesta a
 * «¿Cuántas más podrías haber hecho?» tras su primera serie, que devuelve el peso de la serie siguiente.
 */
@Tag(name = "Training sessions")
@RestController
@RequestMapping("/api/v1/training/sessions/{sessionId}/calibrations")
public class ExerciseCalibrationController {

    private final ListSessionCalibrationsUseCase list;
    private final CalibrateExerciseUseCase calibrate;

    public ExerciseCalibrationController(ListSessionCalibrationsUseCase list, CalibrateExerciseUseCase calibrate) {
        this.list = list;
        this.calibrate = calibrate;
    }

    @GetMapping
    public List<CalibrationTargetResponse> list(@CurrentUserId UUID userId, @PathVariable UUID sessionId) {
        return list.calibrations(userId, sessionId).stream().map(CalibrationTargetResponse::from).toList();
    }

    @PostMapping
    public CalibrationTargetResponse calibrate(@CurrentUserId UUID userId, @PathVariable UUID sessionId,
                                               @Valid @RequestBody CalibrateRequest request) {
        return CalibrationTargetResponse.from(calibrate.calibrate(new CalibrateExerciseUseCase.Command(userId,
                sessionId, request.plannedExerciseId(), request.setNumber(), request.answer())));
    }
}
