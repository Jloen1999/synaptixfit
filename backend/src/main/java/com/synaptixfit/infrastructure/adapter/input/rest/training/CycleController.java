package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.ChangeCycleTrackingUseCase;
import com.synaptixfit.application.port.input.training.DeleteCycleDayUseCase;
import com.synaptixfit.application.port.input.training.DeleteCycleHistoryUseCase;
import com.synaptixfit.application.port.input.training.GetCycleOverviewUseCase;
import com.synaptixfit.application.port.input.training.ListCycleDaysUseCase;
import com.synaptixfit.application.port.input.training.LogCycleDayUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.CycleDtos.CycleDayRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.CycleDtos.CycleDayResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.CycleDtos.CycleDaysResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.CycleDtos.CycleOverviewResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.CycleDtos.CycleSettingsRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Seguimiento del ciclo, opcional (ADR 0033), y la adaptación de hoy explicada. Todo es del usuario del token: no
 * hay forma de leer el de otra persona.
 */
@Tag(name = "Training wellbeing")
@RestController
@RequestMapping("/api/v1/training")
public class CycleController {

    private final GetCycleOverviewUseCase overview;
    private final ChangeCycleTrackingUseCase change;
    private final LogCycleDayUseCase log;
    private final ListCycleDaysUseCase list;
    private final DeleteCycleDayUseCase deleteDay;
    private final DeleteCycleHistoryUseCase deleteHistory;

    public CycleController(GetCycleOverviewUseCase overview, ChangeCycleTrackingUseCase change,
                           LogCycleDayUseCase log, ListCycleDaysUseCase list, DeleteCycleDayUseCase deleteDay,
                           DeleteCycleHistoryUseCase deleteHistory) {
        this.overview = overview;
        this.change = change;
        this.log = log;
        this.list = list;
        this.deleteDay = deleteDay;
        this.deleteHistory = deleteHistory;
    }

    @GetMapping("/cycle")
    public CycleOverviewResponse overview(@CurrentUserId UUID userId) {
        return CycleOverviewResponse.from(overview.overview(userId));
    }

    /** Activa (con {@code consent: true}) o desactiva; al desactivar, {@code deleteHistory} borra lo apuntado. */
    @PutMapping("/cycle/settings")
    public CycleOverviewResponse settings(@CurrentUserId UUID userId, @Valid @RequestBody CycleSettingsRequest r) {
        return CycleOverviewResponse.from(change.change(userId, r.enabled(), Boolean.TRUE.equals(r.consent()),
                Boolean.TRUE.equals(r.deleteHistory())));
    }

    @GetMapping("/cycle/days")
    public CycleDaysResponse days(@CurrentUserId UUID userId,
                                  @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                  @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return new CycleDaysResponse(list.list(userId, from, to).stream().map(CycleDayResponse::from).toList());
    }

    /** Apunta o corrige un día (hoy o del último año). */
    @PutMapping("/cycle/days/{date}")
    public CycleOverviewResponse logDay(@CurrentUserId UUID userId,
                                        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
                                        @Valid @RequestBody CycleDayRequest r) {
        return CycleOverviewResponse.from(log.log(new LogCycleDayUseCase.Command(userId, date, r.period(),
                r.energy(), r.symptoms(), r.note())));
    }

    @DeleteMapping("/cycle/days/{date}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteDay(@CurrentUserId UUID userId,
                          @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        deleteDay.delete(userId, date);
    }

    /** Borra todo lo apuntado del ciclo. */
    @DeleteMapping("/cycle/days")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteHistory(@CurrentUserId UUID userId) {
        deleteHistory.deleteAll(userId);
    }

}
