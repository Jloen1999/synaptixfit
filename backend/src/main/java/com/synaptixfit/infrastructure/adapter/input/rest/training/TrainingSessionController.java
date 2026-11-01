package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.CorrectTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.DeleteSessionSetUseCase;
import com.synaptixfit.application.port.input.training.DeleteTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.FinishTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.GetPendingTrainingDayUseCase;
import com.synaptixfit.application.port.input.training.GetSessionAdaptationUseCase;
import com.synaptixfit.application.port.input.training.GetTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.ListOpenSessionsUseCase;
import com.synaptixfit.application.port.input.training.ListTrainingSessionsUseCase;
import com.synaptixfit.application.port.input.training.LogPastRoutineSessionUseCase;
import com.synaptixfit.application.port.input.training.RecordSessionSetUseCase;
import com.synaptixfit.application.port.input.training.StartTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.UnmarkTrainingSessionUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RecommendationDtos.RecommendationResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.PendingDayResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.CorrectSessionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.ExperienceResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.FinishSessionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.FinishSessionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.OpenSessionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.PastSessionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.SessionDtos.PastSessionResponse;
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
import org.springframework.web.bind.annotation.PatchMapping;
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
    private final DeleteTrainingSessionUseCase delete;
    private final CorrectTrainingSessionUseCase correct;
    private final LogPastRoutineSessionUseCase logPast;
    private final ListOpenSessionsUseCase listOpen;
    private final ListTrainingSessionsUseCase list;
    private final GetTrainingSessionUseCase get;
    private final GetPendingTrainingDayUseCase pendingDay;
    private final GetSessionAdaptationUseCase adaptation;

    public TrainingSessionController(StartTrainingSessionUseCase start, RecordSessionSetUseCase recordSet,
                                     DeleteSessionSetUseCase deleteSet, FinishTrainingSessionUseCase finish,
                                     UnmarkTrainingSessionUseCase unmark, DeleteTrainingSessionUseCase delete,
                                     CorrectTrainingSessionUseCase correct, LogPastRoutineSessionUseCase logPast,
                                     ListOpenSessionsUseCase listOpen,
                                     ListTrainingSessionsUseCase list, GetTrainingSessionUseCase get,
                                     GetPendingTrainingDayUseCase pendingDay,
                                     GetSessionAdaptationUseCase adaptation) {
        this.start = start;
        this.recordSet = recordSet;
        this.deleteSet = deleteSet;
        this.finish = finish;
        this.unmark = unmark;
        this.delete = delete;
        this.correct = correct;
        this.logPast = logPast;
        this.listOpen = listOpen;
        this.list = list;
        this.get = get;
        this.pendingDay = pendingDay;
        this.adaptation = adaptation;
    }

    /** Próximo día de la rutina en curso, con fecha prevista y retraso; 204 si no hay. */
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

    /** Sesiones sin terminar (en curso y abandonadas), más recientes primero. */
    @GetMapping("/sessions/open")
    public List<OpenSessionResponse> listOpen(@CurrentUserId UUID userId) {
        return listOpen.listOpen(userId).stream().map(OpenSessionResponse::from).toList();
    }

    /** Registra un día de rutina entrenado sin la app (hoy o hasta 7 días antes). */
    @PostMapping("/sessions/past")
    @ResponseStatus(HttpStatus.CREATED)
    public PastSessionResponse logPast(@CurrentUserId UUID userId, @Valid @RequestBody PastSessionRequest request) {
        LogPastRoutineSessionUseCase.Result result = logPast.logPast(new LogPastRoutineSessionUseCase.Command(userId,
                request.routineId(), request.dayId(), request.date(), request.durationMinutes(), request.rpe()));
        return new PastSessionResponse(SessionResponse.from(result.session()), ExperienceResponse.from(result.experience()));
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

    /**
     * Deshace la finalización (solo el mismo día en que se terminó): el día deja de estar completado y
     * se resta la experiencia otorgada.
     */
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

    /** Corrige el RPE y la duración de una sesión terminada (recalcula calorías y carga). */
    @PatchMapping("/sessions/{sessionId}")
    public SessionResponse correct(@CurrentUserId UUID userId, @PathVariable UUID sessionId,
                                   @Valid @RequestBody CorrectSessionRequest request) {
        return SessionResponse.from(correct.correct(new CorrectTrainingSessionUseCase.Command(userId, sessionId,
                request.rpe(), request.durationMinutes())));
    }

    /**
     * Elimina una sesión: si estaba sin terminar se descarta; si estaba terminada, además se resta su XP
     * y se retiran su carga, su avance en retos y su bloque.
     */
    @DeleteMapping("/sessions/{sessionId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID sessionId) {
        delete.delete(userId, sessionId);
    }
}
