package com.synaptixfit.infrastructure.adapter.input.rest.run;

import com.synaptixfit.application.port.input.run.DeleteRunUseCase;
import com.synaptixfit.application.port.input.run.GetRunUseCase;
import com.synaptixfit.application.port.input.run.GetRunWeekUseCase;
import com.synaptixfit.application.port.input.run.RecordRunUseCase;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.run.RunRouteTooLargeException;
import com.synaptixfit.domain.model.planner.ActivityKind;
import com.synaptixfit.domain.model.run.KmSplit;
import com.synaptixfit.domain.model.run.RunDetail;
import com.synaptixfit.domain.model.run.RunTrack;
import com.synaptixfit.domain.model.run.RunWeek;
import com.synaptixfit.domain.model.run.TrackPoint;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Carreras grabadas con el GPS (ADR 0037): subir una (idempotente con {@code clientKey}), ver su detalle, borrarla
 * y la tarjeta «Esta semana». Todas las cifras las calcula el servidor; la ruta solo la ve su dueño.
 */
@Tag(name = "Training - Runs")
@RestController
@RequestMapping("/api/v1/training/runs")
public class RunController {

    /** Tamaño máximo del cuerpo al subir una carrera (≈ 20 000 puntos compactos con holgura). */
    static final long MAX_BODY_BYTES = 2L * 1024 * 1024;

    /**
     * Carrera grabada. {@code points}: un array por punto {@code [lat, lon, altitud|null, precisión m, segundos desde
     * startedAt, segmento]}; el segmento cambia con cada pausa. Como mucho {@value RunTrack#MAX_POINTS} puntos.
     */
    public record RunRecordRequest(@NotNull UUID clientKey, @NotNull ActivityKind kind, @NotNull Instant startedAt,
                                   @Min(1) @Max(10) int effort, @NotNull List<List<Double>> points,
                                   UUID workoutId, UUID plannedBlockId) {
    }

    /** Un tramo por km: metros (1000 salvo el último), segundos en movimiento y ritmo en s/km. */
    public record RunSplitResponse(int number, int distanceMeters, int seconds, int paceSecondsPerKm) {
        static RunSplitResponse from(KmSplit s) {
            return new RunSplitResponse(s.number(), s.distanceMeters(), s.seconds(), s.paceSecondsPerKm());
        }
    }

    /** Detalle de una carrera; {@code route}: puntos {@code [lat, lon]} para dibujarla (como mucho 600). */
    public record RunDetailResponse(UUID blockId, ActivityKind kind, String title, Instant startedAt,
                                    Instant endedAt, int distanceMeters, int movingSeconds,
                                    Integer paceSecondsPerKm, int elevationGainMeters, Integer kcal, int effort,
                                    List<RunSplitResponse> splits, List<double[]> route, UUID workoutId) {
        static RunDetailResponse from(RunDetail d) {
            return new RunDetailResponse(d.blockId(), d.kind(), d.title(), d.startedAt(), d.endedAt(),
                    d.distanceMeters(), d.movingSeconds(), d.paceSecondsPerKm(), d.elevationGainMeters(), d.kcal(),
                    d.effort(), d.splits().stream().map(RunSplitResponse::from).toList(),
                    d.route().stream().map(p -> new double[] {p.latitude(), p.longitude()}).toList(),
                    d.workoutId());
        }
    }

    /** La carrera guardada y la XP que sumó. */
    public record RunRecordResponse(RunDetailResponse run, int xpDelta) {
    }

    /** «Esta semana»: totales y distancia de cada día, de lunes a domingo. */
    public record RunWeekResponse(LocalDate weekStart, int distanceMeters, int movingSeconds, int elevationGainMeters,
                                  int outings, List<Integer> dailyDistanceMeters) {
        static RunWeekResponse from(RunWeek w) {
            return new RunWeekResponse(w.weekStart(), w.distanceMeters(), w.movingSeconds(),
                    w.elevationGainMeters(), w.outings(), w.dailyDistanceMeters());
        }
    }

    private final RecordRunUseCase recordRun;
    private final GetRunUseCase getRun;
    private final DeleteRunUseCase deleteRun;
    private final GetRunWeekUseCase getWeek;

    public RunController(RecordRunUseCase recordRun, GetRunUseCase getRun, DeleteRunUseCase deleteRun,
                         GetRunWeekUseCase getWeek) {
        this.recordRun = recordRun;
        this.getRun = getRun;
        this.deleteRun = deleteRun;
        this.getWeek = getWeek;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RunRecordResponse record(@CurrentUserId UUID userId, HttpServletRequest http,
                                    @Valid @RequestBody RunRecordRequest r) {
        if (http.getContentLengthLong() > MAX_BODY_BYTES || r.points().size() > RunTrack.MAX_POINTS) {
            throw new RunRouteTooLargeException();
        }
        RecordRunUseCase.Result result = recordRun.recordRun(new RecordRunUseCase.Command(userId, r.clientKey(),
                r.kind(), r.startedAt(), r.effort(), points(r.points()), r.workoutId(), r.plannedBlockId()));
        return new RunRecordResponse(RunDetailResponse.from(result.run()), result.xpDelta());
    }

    private static List<TrackPoint> points(List<List<Double>> rows) {
        List<TrackPoint> points = new ArrayList<>(rows.size());
        for (List<Double> row : rows) {
            if (row == null || row.size() != 6 || row.get(0) == null || row.get(1) == null || row.get(3) == null
                    || row.get(4) == null || row.get(5) == null) {
                throw new FieldValidationException("points", "INVALID_FORMAT",
                        "each point is [lat, lon, altitude|null, accuracy, seconds, segment]");
            }
            points.add(new TrackPoint(row.get(0), row.get(1), row.get(2), row.get(3), row.get(4),
                    row.get(5).intValue()));
        }
        return points;
    }

    @GetMapping("/week")
    public RunWeekResponse week(@CurrentUserId UUID userId,
                                @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
                                LocalDate date) {
        return RunWeekResponse.from(getWeek.getWeek(userId, date));
    }

    @GetMapping("/{blockId}")
    public RunDetailResponse get(@CurrentUserId UUID userId, @PathVariable UUID blockId) {
        return RunDetailResponse.from(getRun.getRun(userId, blockId));
    }

    @DeleteMapping("/{blockId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID blockId) {
        deleteRun.deleteRun(userId, blockId);
    }
}
