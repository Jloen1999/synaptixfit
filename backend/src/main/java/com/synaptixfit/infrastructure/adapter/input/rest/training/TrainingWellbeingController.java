package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.ApplyRecommendationUseCase;
import com.synaptixfit.application.port.input.training.DeleteWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.training.DiscardRecommendationUseCase;
import com.synaptixfit.application.port.input.training.GetTodayCheckInUseCase;
import com.synaptixfit.application.port.input.training.GetWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.training.ListCheckInsUseCase;
import com.synaptixfit.application.port.input.training.ListRecommendationsUseCase;
import com.synaptixfit.application.port.input.training.ListWeeklyPlansUseCase;
import com.synaptixfit.application.port.input.training.SaveWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.training.SubmitDailyCheckInUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RecommendationDtos.RecommendationResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.WellbeingDtos.CheckInRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.WellbeingDtos.CheckInResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.WellbeingDtos.SubmitCheckInResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.WellbeingDtos.WeeklyPlanRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.WellbeingDtos.WeeklyPlanResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Check-in diario, plan semanal y sugerencias de entrenamiento. */
@Tag(name = "Training wellbeing")
@RestController
@RequestMapping("/api/v1/training")
public class TrainingWellbeingController {

    private final SubmitDailyCheckInUseCase submitCheckIn;
    private final GetTodayCheckInUseCase todayCheckIn;
    private final ListCheckInsUseCase listCheckIns;
    private final SaveWeeklyPlanUseCase savePlan;
    private final GetWeeklyPlanUseCase getPlan;
    private final ListWeeklyPlansUseCase listPlans;
    private final DeleteWeeklyPlanUseCase deletePlan;
    private final ListRecommendationsUseCase listRecommendations;
    private final ApplyRecommendationUseCase applyRecommendation;
    private final DiscardRecommendationUseCase discardRecommendation;

    public TrainingWellbeingController(SubmitDailyCheckInUseCase submitCheckIn, GetTodayCheckInUseCase todayCheckIn,
                                       ListCheckInsUseCase listCheckIns, SaveWeeklyPlanUseCase savePlan,
                                       GetWeeklyPlanUseCase getPlan, ListWeeklyPlansUseCase listPlans,
                                       DeleteWeeklyPlanUseCase deletePlan, ListRecommendationsUseCase listRecommendations,
                                       ApplyRecommendationUseCase applyRecommendation,
                                       DiscardRecommendationUseCase discardRecommendation) {
        this.submitCheckIn = submitCheckIn;
        this.todayCheckIn = todayCheckIn;
        this.listCheckIns = listCheckIns;
        this.savePlan = savePlan;
        this.getPlan = getPlan;
        this.listPlans = listPlans;
        this.deletePlan = deletePlan;
        this.listRecommendations = listRecommendations;
        this.applyRecommendation = applyRecommendation;
        this.discardRecommendation = discardRecommendation;
    }

    // ------------------------------------------------------------------ check-in

    /** Crea o actualiza el check-in de hoy. Solo el primero del día da experiencia. */
    @PutMapping("/check-ins/today")
    public SubmitCheckInResponse submitCheckIn(@CurrentUserId UUID userId, @Valid @RequestBody CheckInRequest request) {
        SubmitDailyCheckInUseCase.Result result = submitCheckIn.submit(userId, request.toValues());
        return new SubmitCheckInResponse(CheckInResponse.from(result.checkIn()), result.firstOfDay(), result.xpAwarded());
    }

    /** Check-in de hoy; 204 si todavía no se ha hecho. */
    @GetMapping("/check-ins/today")
    public ResponseEntity<CheckInResponse> today(@CurrentUserId UUID userId) {
        return todayCheckIn.today(userId).map(CheckInResponse::from).map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @GetMapping("/check-ins")
    public PageResponse<CheckInResponse> checkIns(@CurrentUserId UUID userId,
                                                  @RequestParam(defaultValue = "0") int page,
                                                  @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listCheckIns.list(userId, new PageRequest(page, size)), CheckInResponse::from);
    }

    // ------------------------------------------------------------------ plan semanal

    /** Crea o actualiza el plan de la semana que contiene la fecha (se normaliza al lunes). */
    @PutMapping("/weekly-plans/{weekStart}")
    public WeeklyPlanResponse savePlan(@CurrentUserId UUID userId,
                                       @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart,
                                       @Valid @RequestBody WeeklyPlanRequest request) {
        return WeeklyPlanResponse.from(savePlan.save(userId, weekStart, request.toValues()));
    }

    @GetMapping("/weekly-plans/{weekStart}")
    public WeeklyPlanResponse getPlan(@CurrentUserId UUID userId,
                                      @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart) {
        return WeeklyPlanResponse.from(getPlan.get(userId, weekStart));
    }

    @GetMapping("/weekly-plans")
    public PageResponse<WeeklyPlanResponse> listPlans(@CurrentUserId UUID userId,
                                                      @RequestParam(defaultValue = "0") int page,
                                                      @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listPlans.list(userId, new PageRequest(page, size)), WeeklyPlanResponse::from);
    }

    @DeleteMapping("/weekly-plans/{weekStart}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deletePlan(@CurrentUserId UUID userId,
                           @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart) {
        deletePlan.delete(userId, weekStart);
    }

    // ------------------------------------------------------------------ sugerencias

    @GetMapping("/recommendations")
    public PageResponse<RecommendationResponse> recommendations(@CurrentUserId UUID userId,
                                                                @RequestParam(required = false) Boolean applied,
                                                                @RequestParam(defaultValue = "0") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listRecommendations.list(userId, applied, new PageRequest(page, size)),
                RecommendationResponse::from);
    }

    /** Aplica la sugerencia: copia sus ajustes a los ejercicios de la rutina. */
    @PostMapping("/recommendations/{recommendationId}/apply")
    public RecommendationResponse apply(@CurrentUserId UUID userId, @PathVariable UUID recommendationId) {
        return RecommendationResponse.from(applyRecommendation.apply(userId, recommendationId));
    }

    @DeleteMapping("/recommendations/{recommendationId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void discard(@CurrentUserId UUID userId, @PathVariable UUID recommendationId) {
        discardRecommendation.discard(userId, recommendationId);
    }
}
