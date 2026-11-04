package com.synaptixfit.infrastructure.adapter.input.rest.training;

import java.time.LocalDate;
import com.synaptixfit.domain.model.training.ExerciseProgress;
import com.synaptixfit.application.port.input.training.GetExerciseProgressUseCase;
import com.synaptixfit.application.port.input.training.GetSessionHighlightsUseCase;
import com.synaptixfit.application.port.input.training.ListLastPerformanceUseCase;
import com.synaptixfit.application.port.input.training.ListPersonalRecordsUseCase;
import com.synaptixfit.application.port.input.training.ListSessionHistoryUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.HistoryDtos.PersonalRecordResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.HistoryDtos.SessionHighlightsResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.HistoryDtos.SessionHistoryResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Historial de entrenamiento con nombres y récords ({@link ListSessionHistoryUseCase}, {@link ListPersonalRecordsUseCase})
 * y lo destacado de una sesión terminada ({@link GetSessionHighlightsUseCase}).
 */
@Tag(name = "Training history")
@RestController
@RequestMapping("/api/v1/training")
public class TrainingHistoryController {

    private final ListSessionHistoryUseCase history;
    private final ListPersonalRecordsUseCase records;
    private final ListLastPerformanceUseCase last;
    private final GetSessionHighlightsUseCase highlights;

    private final GetExerciseProgressUseCase progress;

    public TrainingHistoryController(ListSessionHistoryUseCase history, ListPersonalRecordsUseCase records,
                                     ListLastPerformanceUseCase last, GetSessionHighlightsUseCase highlights,
                                     GetExerciseProgressUseCase progress) {
        this.progress = progress;
        this.history = history;
        this.records = records;
        this.last = last;
        this.highlights = highlights;
    }

    /** Resumen de una sesión terminada: volumen, récords batidos y comparación con la anterior comparable. */
    @GetMapping("/sessions/{sessionId}/highlights")
    public SessionHighlightsResponse highlights(@CurrentUserId UUID userId, @PathVariable UUID sessionId) {
        return SessionHighlightsResponse.from(highlights.highlights(userId, sessionId));
    }

    @GetMapping("/history")
    public PageResponse<SessionHistoryResponse> history(@CurrentUserId UUID userId,
                                                        @RequestParam(defaultValue = "0") int page,
                                                        @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(history.listHistory(userId, new PageRequest(page, size)),
                SessionHistoryResponse::from);
    }

    /**
     * Evolución de un ejercicio para la gráfica: por día, el peso máximo estimado («lo máximo que podrías
     * levantar una vez», {@link ExerciseProgress}) y la serie que lo dio. Vacía si nunca se hizo con peso.
     */
    @GetMapping("/exercises/{exerciseId}/progress")
    public List<ExerciseProgressPointResponse> exerciseProgress(@CurrentUserId UUID userId,
                                                                @PathVariable UUID exerciseId) {
        return progress.exerciseProgress(userId, exerciseId).stream()
                .map(p -> new ExerciseProgressPointResponse(p.date(), p.estimatedMaxKg(), p.weightKg(), p.reps()))
                .toList();
    }

    /** Punto de la gráfica de un ejercicio. */
    public record ExerciseProgressPointResponse(LocalDate date, double estimatedMaxKg, double weightKg, int reps) {
    }

    @GetMapping("/records")
    public List<PersonalRecordResponse> records(@CurrentUserId UUID userId) {
        return records.listPersonalRecords(userId).stream().map(PersonalRecordResponse::from).toList();
    }

    /** Mejor serie de la última sesión de cada ejercicio: la referencia al registrar la siguiente. */
    @GetMapping("/last-performance")
    public List<PersonalRecordResponse> lastPerformance(@CurrentUserId UUID userId) {
        return last.lastPerformance(userId).stream().map(PersonalRecordResponse::from).toList();
    }
}
