package com.synaptixfit.infrastructure.adapter.input.rest.profile;

import com.synaptixfit.application.port.input.profile.GetGoalHistoryUseCase;
import com.synaptixfit.application.port.input.profile.GetWeightHistoryUseCase;
import com.synaptixfit.application.port.input.profile.GetWellnessProfileUseCase;
import com.synaptixfit.application.port.input.profile.SaveWellnessProfileUseCase;
import com.synaptixfit.application.port.input.profile.SuggestGoalsUseCase;
import com.synaptixfit.application.port.input.profile.UpdateWellnessProfileUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.GoalHistoryResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.GoalSuggestionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.GoalSuggestionsResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.WeightRecordResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.WellnessProfilePatchRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.WellnessProfileRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.WellnessProfileResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Perfil de bienestar (onboarding físico), historiales y recomendación de objetivo. */
@Tag(name = "Wellness profile")
@RestController
@RequestMapping("/api/v1/profile/wellness")
public class WellnessProfileController {

    private final GetWellnessProfileUseCase getProfile;
    private final SaveWellnessProfileUseCase saveProfile;
    private final UpdateWellnessProfileUseCase updateProfile;
    private final GetWeightHistoryUseCase weightHistory;
    private final GetGoalHistoryUseCase goalHistory;
    private final SuggestGoalsUseCase suggestGoals;

    public WellnessProfileController(GetWellnessProfileUseCase getProfile, SaveWellnessProfileUseCase saveProfile,
                                     UpdateWellnessProfileUseCase updateProfile, GetWeightHistoryUseCase weightHistory,
                                     GetGoalHistoryUseCase goalHistory, SuggestGoalsUseCase suggestGoals) {
        this.getProfile = getProfile;
        this.saveProfile = saveProfile;
        this.updateProfile = updateProfile;
        this.weightHistory = weightHistory;
        this.goalHistory = goalHistory;
        this.suggestGoals = suggestGoals;
    }

    @GetMapping
    public WellnessProfileResponse get(@CurrentUserId UUID userId) {
        return WellnessProfileResponse.from(getProfile.getWellnessProfile(userId));
    }

    /** Crea o reemplaza el perfil completo (idempotente). */
    @PutMapping
    public WellnessProfileResponse save(@CurrentUserId UUID userId, @Valid @RequestBody WellnessProfileRequest r) {
        return WellnessProfileResponse.from(saveProfile.saveWellnessProfile(new SaveWellnessProfileUseCase.Command(
                userId, r.age(), r.sex(), r.city(), r.weightKg(), r.heightCm(), r.activityLevel(), r.primaryGoal(),
                r.goals(), r.equipment(), r.availableDays(), r.minutesPerSession())));
    }

    @PatchMapping
    public WellnessProfileResponse update(@CurrentUserId UUID userId,
                                          @Valid @RequestBody WellnessProfilePatchRequest r) {
        return WellnessProfileResponse.from(updateProfile.updateWellnessProfile(
                new UpdateWellnessProfileUseCase.Command(userId, r.age(), r.sex(), r.city(), r.weightKg(),
                        r.heightCm(), r.activityLevel(), r.primaryGoal(), r.goals(), r.equipment(),
                        r.availableDays(), r.minutesPerSession())));
    }

    @GetMapping("/weight-history")
    public List<WeightRecordResponse> weightHistory(
            @CurrentUserId UUID userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return weightHistory.getWeightHistory(userId, from, to).stream().map(WeightRecordResponse::from).toList();
    }

    @GetMapping("/goal-history")
    public List<GoalHistoryResponse> goalHistory(@CurrentUserId UUID userId) {
        return goalHistory.getGoalHistory(userId).stream().map(GoalHistoryResponse::from).toList();
    }

    @PostMapping("/goal-suggestions")
    public GoalSuggestionsResponse suggestGoals(@CurrentUserId UUID userId,
                                                @Valid @RequestBody(required = false) GoalSuggestionRequest r) {
        GoalSuggestionRequest body = r == null ? new GoalSuggestionRequest(null, null, null, null) : r;
        return GoalSuggestionsResponse.from(suggestGoals.suggestGoals(new SuggestGoalsUseCase.Command(
                userId, body.age(), body.sex(), body.activityLevel(), body.city())));
    }
}
