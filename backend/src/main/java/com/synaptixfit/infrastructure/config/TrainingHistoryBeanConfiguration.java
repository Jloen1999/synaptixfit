package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.training.GetExerciseProgressUseCase;
import com.synaptixfit.application.port.input.training.GetSessionHighlightsUseCase;
import com.synaptixfit.application.port.input.training.ListLastPerformanceUseCase;
import com.synaptixfit.application.port.input.training.ListOpenSessionsUseCase;
import com.synaptixfit.application.port.input.training.ListPersonalRecordsUseCase;
import com.synaptixfit.application.port.input.training.ListSessionHistoryUseCase;
import com.synaptixfit.application.service.training.SessionHistoryService;
import com.synaptixfit.domain.port.output.training.SessionLabelQueryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición del historial de entrenamiento, las sesiones sin terminar y los récords personales. */
@Configuration
public class TrainingHistoryBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final TrainingSessionRepositoryPort sessions;
    private final SessionLabelQueryPort labels;
    private final Clock clock;
    private final ZoneId zone;

    /** @param zone «día» de una sesión: la zona de los indicadores, como en {@link TrainingBeanConfiguration} */
    public TrainingHistoryBeanConfiguration(TransactionalUseCaseFactory tx, TrainingSessionRepositoryPort sessions,
                                            SessionLabelQueryPort labels, Clock clock,
                                            @Value("${synaptixfit.insights.default-zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.sessions = sessions;
        this.labels = labels;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    @Bean(autowireCandidate = false)
    SessionHistoryService sessionHistoryService() {
        return new SessionHistoryService(sessions, labels, clock, zone);
    }

    @Bean
    ListOpenSessionsUseCase listOpenSessionsUseCase() {
        return tx.wrap(ListOpenSessionsUseCase.class, sessionHistoryService());
    }

    @Bean
    ListSessionHistoryUseCase listSessionHistoryUseCase() {
        return tx.wrap(ListSessionHistoryUseCase.class, sessionHistoryService());
    }

    @Bean
    GetSessionHighlightsUseCase getSessionHighlightsUseCase() {
        return tx.wrap(GetSessionHighlightsUseCase.class, sessionHistoryService());
    }

    @Bean
    ListLastPerformanceUseCase listLastPerformanceUseCase() {
        return tx.wrap(ListLastPerformanceUseCase.class, sessionHistoryService());
    }

    @Bean
    GetExerciseProgressUseCase getExerciseProgressUseCase() {
        return tx.wrap(GetExerciseProgressUseCase.class, sessionHistoryService());
    }

    @Bean
    ListPersonalRecordsUseCase listPersonalRecordsUseCase() {
        return tx.wrap(ListPersonalRecordsUseCase.class, sessionHistoryService());
    }
}
