package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.training.GetSessionHighlightsUseCase;
import com.synaptixfit.application.port.input.training.ListLastPerformanceUseCase;
import com.synaptixfit.application.port.input.training.ListPersonalRecordsUseCase;
import com.synaptixfit.application.port.input.training.ListSessionHistoryUseCase;
import com.synaptixfit.application.service.training.SessionHistoryService;
import com.synaptixfit.domain.port.output.training.SessionLabelQueryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición del historial de entrenamiento y los récords personales. */
@Configuration
public class TrainingHistoryBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final TrainingSessionRepositoryPort sessions;
    private final SessionLabelQueryPort labels;

    public TrainingHistoryBeanConfiguration(TransactionalUseCaseFactory tx, TrainingSessionRepositoryPort sessions,
                                            SessionLabelQueryPort labels) {
        this.tx = tx;
        this.sessions = sessions;
        this.labels = labels;
    }

    @Bean(autowireCandidate = false)
    SessionHistoryService sessionHistoryService() {
        return new SessionHistoryService(sessions, labels);
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
    ListPersonalRecordsUseCase listPersonalRecordsUseCase() {
        return tx.wrap(ListPersonalRecordsUseCase.class, sessionHistoryService());
    }
}
