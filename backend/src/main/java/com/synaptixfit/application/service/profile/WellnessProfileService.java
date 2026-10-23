package com.synaptixfit.application.service.profile;

import com.synaptixfit.application.port.input.profile.GetGoalHistoryUseCase;
import com.synaptixfit.application.port.input.profile.GetWeightHistoryUseCase;
import com.synaptixfit.application.port.input.profile.GetWellnessProfileUseCase;
import com.synaptixfit.application.port.input.profile.SaveWellnessProfileUseCase;
import com.synaptixfit.application.port.input.profile.SuggestGoalsUseCase;
import com.synaptixfit.application.port.input.profile.UpdateWellnessProfileUseCase;
import com.synaptixfit.domain.exception.ExternalServiceException;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.profile.WellnessProfileNotFoundException;
import com.synaptixfit.domain.model.profile.BodyMeasurement;
import com.synaptixfit.domain.model.profile.GoalHistoryEntry;
import com.synaptixfit.domain.model.profile.GoalSuggestion;
import com.synaptixfit.domain.model.profile.GoalSuggestionContext;
import com.synaptixfit.domain.model.profile.GoalSuggestionRules;
import com.synaptixfit.domain.model.profile.GoalSuggestionSource;
import com.synaptixfit.domain.model.profile.GoalSuggestions;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import com.synaptixfit.domain.model.profile.WeightRecord;
import com.synaptixfit.domain.model.profile.WellnessProfile;
import com.synaptixfit.domain.port.output.profile.GoalHistoryRepositoryPort;
import com.synaptixfit.domain.port.output.profile.GoalSuggestionPort;
import com.synaptixfit.domain.port.output.profile.WeightHistoryRepositoryPort;
import com.synaptixfit.domain.port.output.profile.WellnessProfileRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Perfil de bienestar: alta y edición (con sus historiales de peso y de objetivos), consultas de
 * historial y recomendación de objetivo principal.
 */
public class WellnessProfileService implements GetWellnessProfileUseCase, SaveWellnessProfileUseCase,
        UpdateWellnessProfileUseCase, GetWeightHistoryUseCase, GetGoalHistoryUseCase, SuggestGoalsUseCase {

    /** Límite superior cuando no se indica fecha final en el historial de peso. */
    private static final Instant FAR_FUTURE = Instant.parse("9999-12-31T00:00:00Z");

    private final WellnessProfileRepositoryPort profiles;
    private final WeightHistoryRepositoryPort weights;
    private final GoalHistoryRepositoryPort goalHistory;
    private final GoalSuggestionPort goalSuggestions;
    private final Clock clock;

    public WellnessProfileService(WellnessProfileRepositoryPort profiles, WeightHistoryRepositoryPort weights,
                                  GoalHistoryRepositoryPort goalHistory, GoalSuggestionPort goalSuggestions,
                                  Clock clock) {
        this.profiles = profiles;
        this.weights = weights;
        this.goalHistory = goalHistory;
        this.goalSuggestions = goalSuggestions;
        this.clock = clock;
    }

    @Override
    public WellnessProfile getWellnessProfile(UUID userId) {
        return profiles.findByUserId(userId).orElseThrow(() -> new WellnessProfileNotFoundException(userId));
    }

    @Override
    public WellnessProfile saveWellnessProfile(SaveWellnessProfileUseCase.Command c) {
        Instant now = clock.instant();
        BodyMeasurement measurement = new BodyMeasurement(c.weightKg(), c.heightCm());
        Optional<WellnessProfile> existing = profiles.findByUserId(c.userId());
        if (existing.isEmpty()) {
            WellnessProfile created = WellnessProfile.builder()
                    .id(UUID.randomUUID())
                    .userId(c.userId())
                    .age(c.age())
                    .sex(c.sex())
                    .city(c.city())
                    .measurement(measurement)
                    .activityLevel(c.activityLevel() == null ? WellnessProfile.DEFAULT_ACTIVITY_LEVEL
                            : c.activityLevel())
                    .primaryGoal(c.primaryGoal())
                    .goals(c.goals())
                    .equipment(c.equipment())
                    .availableDays(c.availableDays() == null || c.availableDays().isEmpty()
                            ? WellnessProfile.DEFAULT_AVAILABLE_DAYS : c.availableDays())
                    .minutesPerSession(c.minutesPerSession() == null ? WellnessProfile.DEFAULT_MINUTES
                            : c.minutesPerSession())
                    .createdAt(now)
                    .build();
            WellnessProfile saved = profiles.save(created);
            weights.append(WeightRecord.of(c.userId(), measurement, now));
            recordGoalChange(c.userId(), null, saved.primaryGoal(), now);
            return saved;
        }
        WellnessProfile profile = existing.get();
        TrainingGoal previousGoal = profile.primaryGoal();
        profile.changeAge(c.age());
        profile.changeSex(c.sex());
        profile.changeCity(c.city());
        boolean measurementChanged = profile.changeMeasurement(measurement);
        if (c.activityLevel() != null) {
            profile.changeActivityLevel(c.activityLevel());
        }
        boolean goalChanged = profile.changePrimaryGoal(c.primaryGoal());
        profile.replaceGoals(c.goals());
        profile.replaceEquipment(c.equipment());
        if (c.availableDays() != null && !c.availableDays().isEmpty()) {
            profile.changeAvailableDays(c.availableDays());
        }
        if (c.minutesPerSession() != null) {
            profile.changeMinutesPerSession(c.minutesPerSession());
        }
        return persistChanges(profile, measurementChanged, goalChanged ? previousGoal : null, now);
    }

    @Override
    public WellnessProfile updateWellnessProfile(UpdateWellnessProfileUseCase.Command c) {
        WellnessProfile profile = getWellnessProfile(c.userId());
        Instant now = clock.instant();
        TrainingGoal previousGoal = profile.primaryGoal();
        if (c.age() != null) {
            profile.changeAge(c.age());
        }
        if (c.sex() != null) {
            profile.changeSex(c.sex());
        }
        if (c.city() != null) {
            profile.changeCity(c.city());
        }
        boolean measurementChanged = false;
        if (c.weightKg() != null || c.heightCm() != null) {
            measurementChanged = profile.changeMeasurement(new BodyMeasurement(
                    c.weightKg() != null ? c.weightKg() : profile.weightKg(),
                    c.heightCm() != null ? c.heightCm() : profile.heightCm()));
        }
        if (c.activityLevel() != null) {
            profile.changeActivityLevel(c.activityLevel());
        }
        boolean goalChanged = c.primaryGoal() != null && profile.changePrimaryGoal(c.primaryGoal());
        if (c.goals() != null) {
            profile.replaceGoals(c.goals());
        }
        if (c.equipment() != null) {
            profile.replaceEquipment(c.equipment());
        }
        if (c.availableDays() != null) {
            profile.changeAvailableDays(c.availableDays());
        }
        if (c.minutesPerSession() != null) {
            profile.changeMinutesPerSession(c.minutesPerSession());
        }
        return persistChanges(profile, measurementChanged, goalChanged ? previousGoal : null, now);
    }

    @Override
    public List<WeightRecord> getWeightHistory(UUID userId, LocalDate from, LocalDate to) {
        if (from != null && to != null && to.isBefore(from)) {
            throw new FieldValidationException("to", "INVALID_RANGE", "to must not be before from");
        }
        Instant fromInstant = from == null ? Instant.EPOCH : from.atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant toInstant = to == null ? FAR_FUTURE : to.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        return weights.findByUser(userId, fromInstant, toInstant);
    }

    @Override
    public List<GoalHistoryEntry> getGoalHistory(UUID userId) {
        return goalHistory.findByUser(userId);
    }

    @Override
    public GoalSuggestions suggestGoals(SuggestGoalsUseCase.Command c) {
        Optional<WellnessProfile> profile = profiles.findByUserId(c.userId());
        GoalSuggestionContext context = new GoalSuggestionContext(
                c.age() != null ? c.age() : profile.map(WellnessProfile::age).orElse(null),
                c.sex() != null ? c.sex() : profile.map(WellnessProfile::sex).orElse(null),
                c.activityLevel() != null ? c.activityLevel() : profile.map(WellnessProfile::activityLevel).orElse(null),
                c.city() != null && !c.city().isBlank() ? c.city().strip() : profile.map(WellnessProfile::city).orElse(null));
        try {
            List<GoalSuggestion> suggestions = goalSuggestions.suggest(context);
            if (suggestions != null && !suggestions.isEmpty()) {
                return new GoalSuggestions(GoalSuggestionSource.AI, suggestions.stream()
                        .limit(GoalSuggestionRules.MAX_SUGGESTIONS).toList());
            }
        } catch (ExternalServiceException e) {
            // La IA es opcional: si no responde (o se agota la cuota) se usan las reglas deterministas.
        }
        return GoalSuggestionRules.suggest(context);
    }

    private WellnessProfile persistChanges(WellnessProfile profile, boolean measurementChanged,
                                           TrainingGoal previousGoalIfChanged, Instant now) {
        profile.touch(now);
        WellnessProfile saved = profiles.save(profile);
        if (measurementChanged) {
            weights.append(WeightRecord.of(saved.userId(), saved.measurement(), now));
        }
        if (previousGoalIfChanged != null) {
            recordGoalChange(saved.userId(), previousGoalIfChanged, saved.primaryGoal(), now);
        }
        return saved;
    }

    /**
     * Cierra el periodo abierto del historial de objetivos (hoy) y abre uno nuevo. Si no se conoce
     * el objetivo anterior (alta del perfil), se toma el del periodo abierto, si lo hay.
     */
    private void recordGoalChange(UUID userId, TrainingGoal previousGoal, TrainingGoal newGoal, Instant now) {
        LocalDate today = LocalDate.ofInstant(now, clock.getZone());
        Optional<GoalHistoryEntry> open = goalHistory.findOpen(userId);
        if (open.isPresent() && open.get().goal() == newGoal) {
            return;
        }
        TrainingGoal previous = previousGoal;
        if (open.isPresent()) {
            GoalHistoryEntry current = open.get();
            if (previous == null) {
                previous = current.goal();
            }
            current.close(today);
            goalHistory.save(current);
        }
        goalHistory.save(GoalHistoryEntry.open(userId, newGoal, previous, today, now));
    }
}
