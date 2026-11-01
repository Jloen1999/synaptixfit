package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.badge.GetStreakUseCase;
import com.synaptixfit.application.port.input.challenge.ListMyChallengesUseCase;
import com.synaptixfit.application.port.input.dashboard.GetDashboardUseCase;
import com.synaptixfit.application.port.input.insights.GetCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.insights.GetPhysicalLoadUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyActivityUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyCaloriesTodayUseCase;
import com.synaptixfit.application.port.input.insights.GetWellbeingUseCase;
import com.synaptixfit.application.port.input.training.GetPendingTrainingDayUseCase;
import com.synaptixfit.application.service.dashboard.DashboardService;
import com.synaptixfit.domain.port.output.dashboard.DashboardReadPort;
import com.synaptixfit.domain.port.output.insights.InsightsSourcePort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición del resumen del inicio (reutiliza los casos de uso de indicadores y de retos). */
@Configuration
public class DashboardBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final UserRepositoryPort users;
    private final DashboardReadPort reads;
    private final InsightsSourcePort insightSources;
    private final Clock clock;
    private final ZoneId zone;

    public DashboardBeanConfiguration(TransactionalUseCaseFactory tx, UserRepositoryPort users,
                                      DashboardReadPort reads, InsightsSourcePort insightSources, Clock clock,
                                      @Value("${synaptixfit.insights.default-zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.users = users;
        this.reads = reads;
        this.insightSources = insightSources;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    @Bean
    GetDashboardUseCase getDashboardUseCase(GetCognitiveStateUseCase cognitiveStates,
                                            GetCrossRegulationUseCase crossRegulation,
                                            GetStudyCaloriesTodayUseCase studyCalories,
                                            GetStudyActivityUseCase studyActivity,
                                            GetPhysicalLoadUseCase physicalLoad, GetWellbeingUseCase wellbeing,
                                            ListMyChallengesUseCase challenges, GetStreakUseCase streaks,
                                            GetPendingTrainingDayUseCase pendingDays) {
        DashboardService service = new DashboardService(users, reads, insightSources, cognitiveStates,
                crossRegulation, studyCalories, studyActivity, physicalLoad, wellbeing, challenges, pendingDays,
                streaks, clock, zone);
        return tx.wrap(GetDashboardUseCase.class, service);
    }
}
