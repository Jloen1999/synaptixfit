package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.insights.GetCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.insights.GetPhysicalLoadUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyActivityUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyCaloriesTodayUseCase;
import com.synaptixfit.application.port.input.insights.GetWellbeingUseCase;
import com.synaptixfit.application.port.input.insights.InitializeCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.SyncSportBlockLoadUseCase;
import com.synaptixfit.application.port.input.insights.RecordTrainingLoadUseCase;
import com.synaptixfit.application.port.input.insights.RefreshCognitiveStateUseCase;
import com.synaptixfit.application.service.insights.CognitiveStateService;
import com.synaptixfit.application.service.insights.TrainingLoadService;
import com.synaptixfit.application.service.insights.WellbeingService;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.insights.CognitiveStateRepositoryPort;
import com.synaptixfit.domain.port.output.insights.CrossRegulationRepositoryPort;
import com.synaptixfit.domain.port.output.insights.InsightsSourcePort;
import com.synaptixfit.domain.port.output.insights.PhysicalLoadRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición de los indicadores neurofisiológicos (carga física/ACWR, estado cognitivo, bienestar).
 *
 * <p>La zona horaria por defecto ({@code synaptixfit.insights.default-zone}, Europe/Madrid si no se
 * configura) define "hoy" para los oyentes de eventos y para las peticiones sin {@code tz}.
 */
@Configuration
public class InsightsBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final PhysicalLoadRepositoryPort loads;
    private final CrossRegulationRepositoryPort regulation;
    private final CognitiveStateRepositoryPort cognitiveStates;
    private final InsightsSourcePort sources;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final ZoneId defaultZone;

    public InsightsBeanConfiguration(TransactionalUseCaseFactory tx, PhysicalLoadRepositoryPort loads,
                                     CrossRegulationRepositoryPort regulation,
                                     CognitiveStateRepositoryPort cognitiveStates, InsightsSourcePort sources,
                                     DomainEventPublisherPort events, Clock clock,
                                     @Value("${synaptixfit.insights.default-zone:Europe/Madrid}") String defaultZone) {
        this.tx = tx;
        this.loads = loads;
        this.regulation = regulation;
        this.cognitiveStates = cognitiveStates;
        this.sources = sources;
        this.events = events;
        this.clock = clock;
        this.defaultZone = ZoneId.of(defaultZone);
    }

    // ---------------------------------------------------------------- carga física y ACWR

    @Bean(autowireCandidate = false)
    TrainingLoadService trainingLoadService() {
        return new TrainingLoadService(loads, regulation, cognitiveStateService(), sources, events, clock,
                defaultZone);
    }

    @Bean
    RecordTrainingLoadUseCase recordTrainingLoadUseCase() {
        return tx.wrap(RecordTrainingLoadUseCase.class, trainingLoadService());
    }

    @Bean
    SyncSportBlockLoadUseCase syncSportBlockLoadUseCase() {
        return tx.wrap(SyncSportBlockLoadUseCase.class, trainingLoadService());
    }

    @Bean
    GetCrossRegulationUseCase getCrossRegulationUseCase() {
        return tx.wrap(GetCrossRegulationUseCase.class, trainingLoadService());
    }

    @Bean
    GetPhysicalLoadUseCase getPhysicalLoadUseCase() {
        return tx.wrap(GetPhysicalLoadUseCase.class, trainingLoadService());
    }

    // ---------------------------------------------------------------- estado cognitivo

    @Bean(autowireCandidate = false)
    CognitiveStateService cognitiveStateService() {
        return new CognitiveStateService(cognitiveStates, sources, clock, defaultZone);
    }

    @Bean
    InitializeCognitiveStateUseCase initializeCognitiveStateUseCase() {
        return tx.wrap(InitializeCognitiveStateUseCase.class, cognitiveStateService());
    }

    @Bean
    RefreshCognitiveStateUseCase refreshCognitiveStateUseCase() {
        return tx.wrap(RefreshCognitiveStateUseCase.class, cognitiveStateService());
    }

    @Bean
    GetCognitiveStateUseCase getCognitiveStateUseCase() {
        return tx.wrap(GetCognitiveStateUseCase.class, cognitiveStateService());
    }

    @Bean
    GetStudyCaloriesTodayUseCase getStudyCaloriesTodayUseCase() {
        return tx.wrap(GetStudyCaloriesTodayUseCase.class, cognitiveStateService());
    }

    @Bean
    GetStudyActivityUseCase getStudyActivityUseCase() {
        return tx.wrap(GetStudyActivityUseCase.class, cognitiveStateService());
    }

    // ---------------------------------------------------------------- bienestar

    @Bean(autowireCandidate = false)
    WellbeingService wellbeingService() {
        return new WellbeingService(sources, clock, defaultZone);
    }

    @Bean
    GetWellbeingUseCase getWellbeingUseCase() {
        return tx.wrap(GetWellbeingUseCase.class, wellbeingService());
    }
}
