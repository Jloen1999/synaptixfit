package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.wod.CreateWodUseCase;
import com.synaptixfit.application.port.input.wod.DeleteWodUseCase;
import com.synaptixfit.application.port.input.wod.GetWodBoardUseCase;
import com.synaptixfit.application.port.input.wod.ListWodMarksUseCase;
import com.synaptixfit.application.port.input.wod.ListWodTemplatesUseCase;
import com.synaptixfit.application.port.input.wod.SaveWodResultUseCase;
import com.synaptixfit.application.port.input.wod.UpdateWodUseCase;
import com.synaptixfit.application.service.wod.WodService;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.port.output.wod.WodRepositoryPort;
import java.time.Clock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de los WOD (ADR 0069). Usan el planificador solo por su contrato de apuntar una actividad. */
@Configuration
public class WodBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final WodRepositoryPort wods;
    private final LogPastActivityUseCase logActivity;
    private final PlannerZone zone;
    private final Clock clock;

    public WodBeanConfiguration(TransactionalUseCaseFactory tx, WodRepositoryPort wods,
                                LogPastActivityUseCase logActivity,
                                @Value("${synaptixfit.planner.zone:Europe/Madrid}") String zoneId, Clock clock) {
        this.tx = tx;
        this.wods = wods;
        this.logActivity = logActivity;
        this.zone = PlannerZone.of(zoneId);
        this.clock = clock;
    }

    /** Una sola instancia para todos los contratos; cada uno se expone envuelto en su transacción. */
    @Bean(autowireCandidate = false)
    WodService wodService() {
        return new WodService(wods, logActivity, zone, clock);
    }

    @Bean
    ListWodTemplatesUseCase listWodTemplatesUseCase() {
        return tx.wrap(ListWodTemplatesUseCase.class, wodService());
    }

    @Bean
    GetWodBoardUseCase getWodBoardUseCase() {
        return tx.wrap(GetWodBoardUseCase.class, wodService());
    }

    @Bean
    CreateWodUseCase createWodUseCase() {
        return tx.wrap(CreateWodUseCase.class, wodService());
    }

    @Bean
    UpdateWodUseCase updateWodUseCase() {
        return tx.wrap(UpdateWodUseCase.class, wodService());
    }

    @Bean
    DeleteWodUseCase deleteWodUseCase() {
        return tx.wrap(DeleteWodUseCase.class, wodService());
    }

    @Bean
    SaveWodResultUseCase saveWodResultUseCase() {
        return tx.wrap(SaveWodResultUseCase.class, wodService());
    }

    @Bean
    ListWodMarksUseCase listWodMarksUseCase() {
        return tx.wrap(ListWodMarksUseCase.class, wodService());
    }
}
