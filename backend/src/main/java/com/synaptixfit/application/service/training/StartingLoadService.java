package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.GetStartingLoadsUseCase;
import com.synaptixfit.domain.model.training.HealthConsent;
import com.synaptixfit.domain.model.training.TemplateLevel;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.load.LoadProfile;
import com.synaptixfit.domain.model.training.load.StartingLoad;
import com.synaptixfit.domain.port.output.training.ExerciseLoadProfileRepositoryPort;
import com.synaptixfit.domain.port.output.training.HealthConsentRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Implementa {@link GetStartingLoadsUseCase} con {@link StartingLoad}: lee el perfil de carga de cada ejercicio
 * ({@link ExerciseLoadProfileRepositoryPort}), el historial reciente ({@link TrainingSessionRepositoryPort}) y el peso
 * del perfil ({@link TrainingContextPort}). El peso corporal es un dato de salud: solo se usa si la persona tiene el
 * consentimiento de salud vigente con el texto que lo incluye ({@link HealthConsent#coversBodyWeight}, ADR 0054); si
 * no, el peso fijo por defecto.
 */
public class StartingLoadService implements GetStartingLoadsUseCase {

    /** Sesiones que se miran: de sobra para cubrir {@value StartingLoad#HISTORY_DAYS} días. */
    static final int HISTORY_SESSIONS = 60;

    private final ExerciseLoadProfileRepositoryPort profiles;
    private final TrainingSessionRepositoryPort sessions;
    private final TrainingContextPort context;
    private final HealthConsentRepositoryPort consents;
    private final Clock clock;

    public StartingLoadService(ExerciseLoadProfileRepositoryPort profiles, TrainingSessionRepositoryPort sessions,
                               TrainingContextPort context, HealthConsentRepositoryPort consents, Clock clock) {
        this.profiles = profiles;
        this.sessions = sessions;
        this.context = context;
        this.consents = consents;
        this.clock = clock;
    }

    @Override
    public Map<UUID, Double> startingLoads(UUID userId, Collection<UUID> exerciseIds, TemplateLevel level) {
        Map<UUID, Double> result = new LinkedHashMap<>();
        if (exerciseIds == null || exerciseIds.isEmpty()) {
            return result;
        }
        Instant now = clock.instant();
        Map<UUID, LoadProfile> byExercise = profiles.findByExerciseIds(exerciseIds);
        List<CompletedSessionSummary> recent = sessions.recentCompleted(userId, HISTORY_SESSIONS);
        // Solo un consentimiento vigente con el texto que incluye el peso (ADR 0054).
        boolean consented = consents.find(userId).map(HealthConsent::coversBodyWeight).orElse(false);
        Double bodyWeight = consented ? context.bodyWeightKg(userId).orElse(null) : null;
        for (UUID id : exerciseIds) {
            Double kg = StartingLoad.forExercise(byExercise.get(id), StartingLoad.historyKg(recent, id, now),
                    bodyWeight, level);
            if (kg != null) {
                result.put(id, kg);
            }
        }
        return result;
    }
}
