package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.CancelTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.DeleteSessionSetUseCase;
import com.synaptixfit.application.port.input.training.FinishTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.GetPendingTrainingDayUseCase;
import com.synaptixfit.application.port.input.training.GetSessionAdaptationUseCase;
import com.synaptixfit.application.port.input.training.GetTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.ListTrainingSessionsUseCase;
import com.synaptixfit.application.port.input.training.RecordSessionSetUseCase;
import com.synaptixfit.application.port.input.training.StartTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.UnmarkTrainingSessionUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RecommendationDtos.RecommendationResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.PendingDayResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.ExperienceResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.FinishSessionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.FinishSessionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.RecordSetRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.SessionAdaptationResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.SessionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.StartSessionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.UnmarkSessionResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Sesiones de entrenamiento y día pendiente. */
@Tag(name = "Training sessions")
@RestController
@RequestMapping("/api/v1/training")
public class TrainingSessionController {

    private final StartTrainingSessionUseCase start;
    private final RecordSessionSetUseCase recordSet;
    private final DeleteSessionSetUseCase deleteSet;
    private final FinishTrainingSessionUseCase finish;
    private final UnmarkTrainingSessionUseCase unmark;
    private final CancelTrainingSessionUseCase cancel;
    private final ListTrainingSessionsUseCase list;
    private final GetTrainingSessionUseCase get;
    private final GetPendingTrainingDayUseCase pendingDay;
    private final GetSessionAdaptationUseCase adaptation;

    public TrainingSessionController(StartTrainingSessionUseCase start, RecordSessionSetUseCase recordSet,
                                     DeleteSessionSetUseCase deleteSet, FinishTrainingSessionUseCase finish,
                                     UnmarkTrainingSessionUseCase unmark, CancelTrainingSessionUseCase cancel,
                                     ListTrainingSessionsUseCase list, GetTrainingSessionUseCase get,
                                     GetPendingTrainingDayUseCase pendingDay,
                                     GetSessionAdaptationUseCase adaptation) {
        this.start = start;
        this.recordSet = recordSet;
        this.deleteSet = deleteSet;
        this.finish = finish;
        this.unmark = unmark;
        this.cancel = cancel;
        this.list = list;
        this.get = get;
        this.pendingDay = pendingDay;
        this.adaptation = adaptation;
    }

    /** Próximo día pendiente de la rutina activa más reciente; 204 si no hay. */
    @GetMapping("/pending-day")
    public ResponseEntity<PendingDayResponse> pendingDay(@CurrentUserId UUID userId) {
        return pendingDay.pendingDay(userId).map(PendingDayResponse::from).map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    /** Empieza (o recupera si ya está en curso para ese día) una sesión. */
    @PostMapping("/sessions")
    @ResponseStatus(HttpStatus.CREATED)
    public SessionResponse start(@CurrentUserId UUID userId, @RequestBody(required = false) StartSessionRequest request) {
        return SessionResponse.from(start.start(userId, request == null ? null : request.routineId(),
                request == null ? null : request.dayId()));
    }

    @GetMapping("/sessions")
    public PageResponse<SessionResponse> list(@CurrentUserId UUID userId,
                                              @RequestParam(required = false) Boolean completed,
                                              @RequestParam(defaultValue = "0") int page,
                                              @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(list.list(userId, completed, new PageRequest(page, size)), SessionResponse::from);
    }

    @GetMapping("/sessions/{sessionId}")
    public SessionResponse get(@CurrentUserId UUID userId, @PathVariable UUID sessionId) {
        return SessionResponse.from(get.get(userId, sessionId));
    }

    @PostMapping("/sessions/{sessionId}/sets")
    public SessionResponse recordSet(@CurrentUserId UUID userId, @PathVariable UUID sessionId,
                                     @Valid @RequestBody RecordSetRequest request) {
        return SessionResponse.from(recordSet.recordSet(request.toCommand(userId, sessionId)));
    }

    @DeleteMapping("/sessions/{sessionId}/sets/{setId}")
    public SessionResponse deleteSet(@CurrentUserId UUID userId, @PathVariable UUID sessionId,
                                     @PathVariable UUID setId) {
        return SessionResponse.from(deleteSet.deleteSet(userId, sessionId, setId));
    }

    @PostMapping("/sessions/{sessionId}/finish")
    public FinishSessionResponse finish(@CurrentUserId UUID userId, @PathVariable UUID sessionId,
                                        @Valid @RequestBody FinishSessionRequest request) {
        FinishTrainingSessionUseCase.Result result = finish.finish(new FinishTrainingSessionUseCase.Command(userId,
                sessionId, request.durationSeconds(), request.rpe(), request.realDurations(),
                request.sets() == null ? List.of() : request.sets().stream().map(s -> s.toCommand(userId, sessionId)).toList()));
        return new FinishSessionResponse(SessionResponse.from(result.session()),
                ExperienceResponse.from(result.experience()),
                result.recommendations().stream().map(RecommendationResponse::from).toList());
    }

    /** Deshace la finalización: el día deja de estar completado y se resta la experiencia otorgada. */
    @PostMapping("/sessions/{sessionId}/unmark")
    public UnmarkSessionResponse unmark(@CurrentUserId UUID userId, @PathVariable UUID sessionId) {
        UnmarkTrainingSessionUseCase.Result result = unmark.unmark(userId, sessionId);
        return new UnmarkSessionResponse(SessionResponse.from(result.session()), ExperienceResponse.from(result.experience()));
    }

    /** Cómo se adapta hoy la sesión (examen cerca, sobreentrenamiento o fatiga) y las series de cada ejercicio. */
    @GetMapping("/sessions/{sessionId}/adaptation")
    public SessionAdaptationResponse adaptation(@CurrentUserId UUID userId, @PathVariable UUID sessionId,
                                                @RequestParam(required = false) String tz) {
        return SessionAdaptationResponse.from(adaptation.adaptation(userId, sessionId, tz));
    }

    /** Abandona una sesión en curso. */
    @DeleteMapping("/sessions/{sessionId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void cancel(@CurrentUserId UUID userId, @PathVariable UUID sessionId) {
        cancel.cancel(userId, sessionId);
    }
}
