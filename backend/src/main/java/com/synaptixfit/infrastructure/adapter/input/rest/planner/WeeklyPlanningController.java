package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import com.synaptixfit.application.port.input.planner.DeleteStudyPlanUseCase;
import com.synaptixfit.application.port.input.planner.GetStudyPlansUseCase;
import com.synaptixfit.application.port.input.planner.GetWeekBalanceUseCase;
import com.synaptixfit.application.port.input.planner.GetWeekPlanStatusUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.WeekPlanStatusResponse;
import com.synaptixfit.application.port.input.planner.GetWeeklyLoadsUseCase;
import com.synaptixfit.application.port.input.planner.SaveWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.planner.SyncWeeklyLoadUseCase;
import com.synaptixfit.application.port.input.planner.UpdateWeeklyWellbeingUseCase;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.SavePlanRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.SavePlanResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.StudyPlanResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.WeekBalanceResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.WeeklyLoadResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.WeeklyLoadSyncResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.WellbeingRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Plan semanal, carga académica semanal y balance estudio/deporte. Cualquier fecha de la semana sirve
 * como {@code weekStart}: se normaliza al lunes.
 */
@Tag(name = "Planner - Weekly planning")
@RestController
@RequestMapping("/api/v1/planner")
public class WeeklyPlanningController {

    private final SaveWeeklyPlanUseCase savePlan;
    private final GetStudyPlansUseCase getPlans;
    private final DeleteStudyPlanUseCase deletePlan;
    private final SyncWeeklyLoadUseCase syncLoad;
    private final UpdateWeeklyWellbeingUseCase updateWellbeing;
    private final GetWeeklyLoadsUseCase getLoads;
    private final GetWeekBalanceUseCase getBalance;
    private final GetWeekPlanStatusUseCase planStatus;

    public WeeklyPlanningController(SaveWeeklyPlanUseCase savePlan, GetStudyPlansUseCase getPlans,
                                    DeleteStudyPlanUseCase deletePlan, SyncWeeklyLoadUseCase syncLoad,
                                    UpdateWeeklyWellbeingUseCase updateWellbeing, GetWeeklyLoadsUseCase getLoads,
                                    GetWeekBalanceUseCase getBalance, GetWeekPlanStatusUseCase planStatus) {
        this.savePlan = savePlan;
        this.getPlans = getPlans;
        this.deletePlan = deletePlan;
        this.syncLoad = syncLoad;
        this.updateWellbeing = updateWellbeing;
        this.getLoads = getLoads;
        this.getBalance = getBalance;
        this.planStatus = planStatus;
    }

    // ---------------------------------------------------------------- plan semanal

    /** Guarda (crea o reutiliza) el plan de la semana. */
    @PutMapping("/plans/{weekStart}")
    public SavePlanResponse savePlan(@CurrentUserId UUID userId,
                                     @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart,
                                     @Valid @RequestBody(required = false) SavePlanRequest r) {
        SaveWeeklyPlanUseCase.Result result = savePlan.savePlan(new SaveWeeklyPlanUseCase.Command(userId, weekStart,
                r == null ? null : r.name(), r == null ? null : r.visibility()));
        return new SavePlanResponse(StudyPlanResponse.from(result.plan()), result.blockCount(), result.deadlineCount(),
                result.xpAwarded());
    }

    /** ¿Se cerró ya esta semana? («Cerrar semana» se hace una vez; después se enseña «Semana cerrada»). */
    @GetMapping("/plans/{weekStart}")
    public WeekPlanStatusResponse planStatus(@CurrentUserId UUID userId,
                                             @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
                                             LocalDate weekStart) {
        return WeekPlanStatusResponse.from(planStatus.status(userId, weekStart));
    }

    @GetMapping("/plans")
    public PageResponse<StudyPlanResponse> plans(@CurrentUserId UUID userId,
                                                 @RequestParam(defaultValue = "0") int page,
                                                 @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getPlans.getPlans(userId, new PageRequest(page, size)), StudyPlanResponse::from);
    }

    @DeleteMapping("/plans/{planId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deletePlan(@CurrentUserId UUID userId, @PathVariable UUID planId) {
        deletePlan.deletePlan(userId, planId);
    }

    // ---------------------------------------------------------------- carga semanal

    /** Cargas guardadas de las semanas cuyo lunes está entre {@code from} y {@code to}. */
    @GetMapping("/weekly-loads")
    public List<WeeklyLoadResponse> weeklyLoads(@CurrentUserId UUID userId,
                                                @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                                @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return getLoads.getWeeklyLoads(userId, from, to).stream().map(WeeklyLoadResponse::from).toList();
    }

    /** Recalcula la carga de la semana (y concede la experiencia semanal de estudio si procede). */
    @PostMapping("/weekly-loads/{weekStart}/sync")
    public WeeklyLoadSyncResponse syncWeek(@CurrentUserId UUID userId,
                                           @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart) {
        SyncWeeklyLoadUseCase.Result result = syncLoad.syncWeek(userId, weekStart);
        return new WeeklyLoadSyncResponse(WeeklyLoadResponse.from(result.load()), result.xpAwarded());
    }

    @PatchMapping("/weekly-loads/{weekStart}")
    public WeeklyLoadResponse wellbeing(@CurrentUserId UUID userId,
                                        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart,
                                        @Valid @RequestBody WellbeingRequest r) {
        return WeeklyLoadResponse.from(updateWellbeing.updateWellbeing(new UpdateWeeklyWellbeingUseCase.Command(
                userId, weekStart, r.stressLevel(), r.sleepHours(), r.notes())));
    }

    // ---------------------------------------------------------------- balance

    @GetMapping("/balance")
    public WeekBalanceResponse balance(@CurrentUserId UUID userId,
                                       @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart) {
        return WeekBalanceResponse.from(PlannerZone.mondayOf(weekStart), getBalance.getBalance(userId, weekStart));
    }
}
