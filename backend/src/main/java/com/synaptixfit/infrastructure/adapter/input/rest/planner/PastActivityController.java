package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import com.synaptixfit.application.port.input.planner.ListSportActivitiesUseCase;
import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.domain.model.planner.ActivityKind;
import com.synaptixfit.domain.model.planner.ActivityPace;
import com.synaptixfit.domain.model.planner.ActivitySource;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.LoggedSportActivity;
import com.synaptixfit.domain.model.planner.MatchResult;
import com.synaptixfit.domain.model.planner.Sport;
import com.synaptixfit.domain.model.planner.SportCategory;
import com.synaptixfit.domain.model.planner.SportDetails;
import com.synaptixfit.domain.model.planner.SportMode;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.BlockCompletionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.CalendarBlockResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Apuntar una actividad que ya pasó: deporte (con su esfuerzo y, si se quiere, su clase y distancia) o estudio
 * (con su asignatura), como bloque hecho. También lista el deporte hecho fuera de las rutinas para el historial.
 */
@Tag(name = "Planner - Blocks")
@RestController
@RequestMapping("/api/v1/planner/past-activities")
public class PastActivityController {

    /**
     * Actividad pasada: inicio, duración (deporte 10-300 min; estudio 30-300), qué fue, tipo ({@code SPORT} por
     * defecto o {@code STUDY}), esfuerzo (1-10, obligatorio en deporte), asignatura (estudio, opcional), clase de
     * deporte y distancia en metros (solo correr, andar, bici o nadar). Deportes (ADR 0068): {@code sport} (si no
     * llega, se deduce de {@code kind} y el título, como en las apps anteriores), {@code sportName} (solo
     * {@code OTHER}), {@code mode} (deportes de partido; por defecto {@code MATCH}) y, solo de un partido,
     * {@code result} y {@code scoreText} (marcador libre, 20 letras como mucho).
     */
    public record PastActivityRequest(@NotNull Instant start, @Min(10) @Max(300) int minutes,
                                      @Size(max = 200) String title, @Min(1) @Max(10) Integer effort,
                                      ActivityType type, UUID subjectId, ActivityKind kind,
                                      @Min(100) @Max(300000) Integer distanceMeters, Sport sport,
                                      @Size(max = 80) String sportName, SportMode mode, MatchResult result,
                                      @Size(max = 20) String scoreText) {

        SportDetails sportDetails() {
            return sport == null ? null : new SportDetails(sport, sportName, mode, result, scoreText);
        }
    }

    /**
     * Deporte hecho: minutos reales (si se apuntó a mano) o los del bloque, distancia, esfuerzo y, con distancia,
     * ritmo en segundos por km, por 100 m (natación) y velocidad en km/h (los calcula el servidor). {@code source}: {@code MANUAL}
     * (apuntada a mano), {@code GPS} (grabada con la app, tiene ruta y detalle) o nulo (marcada en el calendario).
     * {@code sport}, {@code sportCategory}, {@code sportName}, {@code mode}, {@code result} y {@code scoreText} (ADR
     * 0068) son nulos si se marcó en el calendario sin apuntarla; {@code kind} se sigue devolviendo.
     */
    public record SportActivityResponse(UUID blockId, Instant start, int minutes, String title, ActivityKind kind,
                                        Integer distanceMeters, Integer effort, Integer paceSecondsPerKm,
                                        Double speedKmh, ActivitySource source, Integer elevationGainMeters,
                                        Integer paceSecondsPer100m, Sport sport, SportCategory sportCategory,
                                        String sportName, SportMode mode, MatchResult result, String scoreText) {
        static SportActivityResponse from(LoggedSportActivity a) {
            ActivityPace pace = a.pace();
            SportDetails s = a.sport();
            return new SportActivityResponse(a.blockId(), a.start(), a.minutes(), a.title(), a.kind(),
                    a.distanceMeters(), a.effort(), pace == null ? null : pace.secondsPerKm(),
                    pace == null ? null : pace.kmPerHour(), a.source(), a.elevationGainMeters(),
                    pace == null ? null : pace.secondsPer100m(), s == null ? null : s.sport(),
                    s == null ? null : s.sport().category(), s == null ? null : s.name(),
                    s == null ? null : s.mode(), s == null ? null : s.result(), s == null ? null : s.scoreText());
        }
    }

    private final LogPastActivityUseCase logPastActivity;
    private final ListSportActivitiesUseCase listActivities;

    public PastActivityController(LogPastActivityUseCase logPastActivity, ListSportActivitiesUseCase listActivities) {
        this.logPastActivity = logPastActivity;
        this.listActivities = listActivities;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BlockCompletionResponse log(@CurrentUserId UUID userId, @Valid @RequestBody PastActivityRequest r) {
        SetBlockCompletionUseCase.Result result = logPastActivity.logPastActivity(
                new LogPastActivityUseCase.Command(userId, r.start(), r.minutes(), r.title(), r.effort(), r.type(),
                        r.subjectId(), r.kind(), r.distanceMeters(), ActivitySource.MANUAL, null, null,
                        r.sportDetails()));
        return new BlockCompletionResponse(CalendarBlockResponse.from(result.block()), result.xpDelta());
    }

    /** Partidos y actividades hechos fuera de las rutinas, del más reciente al más antiguo. */
    @GetMapping
    public PageResponse<SportActivityResponse> list(@CurrentUserId UUID userId,
                                                    @RequestParam(defaultValue = "0") int page,
                                                    @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listActivities.list(userId, new PageRequest(page, size)),
                SportActivityResponse::from);
    }
}
