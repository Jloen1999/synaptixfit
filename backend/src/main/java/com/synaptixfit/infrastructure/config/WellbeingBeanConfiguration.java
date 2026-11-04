package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.training.ChangeCycleTrackingUseCase;
import com.synaptixfit.application.port.input.training.DeleteCycleDayUseCase;
import com.synaptixfit.application.port.input.training.DeleteCycleHistoryUseCase;
import com.synaptixfit.application.port.input.training.GetCycleOverviewUseCase;
import com.synaptixfit.application.port.input.training.GetSessionAdaptationUseCase;
import com.synaptixfit.application.port.input.training.GetTodayAdaptationUseCase;
import com.synaptixfit.application.port.input.training.ListCycleDaysUseCase;
import com.synaptixfit.application.port.input.training.LogCycleDayUseCase;
import com.synaptixfit.application.service.training.CycleTrackingService;
import com.synaptixfit.application.service.training.SessionAdaptationService;
import com.synaptixfit.domain.port.output.training.CycleRepositoryPort;
import com.synaptixfit.domain.port.output.training.DailyCheckInRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición del bienestar del entreno: seguimiento del ciclo (ADR 0033) y adaptación de la sesión y de hoy, que
 * tiene en cuenta el registro diario, la regulación cruzada y, si está activo, el ciclo.
 */
@Configuration
public class WellbeingBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final CycleRepositoryPort cycles;
    private final TrainingSessionRepositoryPort sessions;
    private final RoutineRepositoryPort routines;
    private final DailyCheckInRepositoryPort checkIns;
    private final GetCrossRegulationUseCase crossRegulation;
    private final Clock clock;
    private final ZoneId zone;

    public WellbeingBeanConfiguration(TransactionalUseCaseFactory tx, CycleRepositoryPort cycles,
                                      TrainingSessionRepositoryPort sessions, RoutineRepositoryPort routines,
                                      DailyCheckInRepositoryPort checkIns, GetCrossRegulationUseCase crossRegulation,
                                      Clock clock,
                                      @Value("${synaptixfit.insights.default-zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.cycles = cycles;
        this.sessions = sessions;
        this.routines = routines;
        this.checkIns = checkIns;
        this.crossRegulation = crossRegulation;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    @Bean(autowireCandidate = false)
    CycleTrackingService cycleTrackingService() {
        return new CycleTrackingService(cycles, clock, zone);
    }

    @Bean
    GetCycleOverviewUseCase getCycleOverviewUseCase() {
        return tx.wrap(GetCycleOverviewUseCase.class, cycleTrackingService());
    }

    @Bean
    ChangeCycleTrackingUseCase changeCycleTrackingUseCase() {
        return tx.wrap(ChangeCycleTrackingUseCase.class, cycleTrackingService());
    }

    @Bean
    LogCycleDayUseCase logCycleDayUseCase() {
        return tx.wrap(LogCycleDayUseCase.class, cycleTrackingService());
    }

    @Bean
    ListCycleDaysUseCase listCycleDaysUseCase() {
        return tx.wrap(ListCycleDaysUseCase.class, cycleTrackingService());
    }

    @Bean
    DeleteCycleDayUseCase deleteCycleDayUseCase() {
        return tx.wrap(DeleteCycleDayUseCase.class, cycleTrackingService());
    }

    @Bean
    DeleteCycleHistoryUseCase deleteCycleHistoryUseCase() {
        return tx.wrap(DeleteCycleHistoryUseCase.class, cycleTrackingService());
    }

    @Bean(autowireCandidate = false)
    SessionAdaptationService sessionAdaptationService() {
        return new SessionAdaptationService(sessions, routines, checkIns, crossRegulation, clock, zone, cycles);
    }

    @Bean
    GetSessionAdaptationUseCase getSessionAdaptationUseCase() {
        return tx.wrap(GetSessionAdaptationUseCase.class, sessionAdaptationService());
    }

    @Bean
    GetTodayAdaptationUseCase getTodayAdaptationUseCase() {
        return tx.wrap(GetTodayAdaptationUseCase.class, sessionAdaptationService());
    }
}
