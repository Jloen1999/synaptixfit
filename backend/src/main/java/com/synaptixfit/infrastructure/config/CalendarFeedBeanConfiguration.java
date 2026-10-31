package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.planner.CreateCalendarFeedUseCase;
import com.synaptixfit.application.port.input.planner.ExportIcsUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarFeedUseCase;
import com.synaptixfit.application.port.input.planner.ReadCalendarFeedUseCase;
import com.synaptixfit.application.port.input.planner.RevokeCalendarFeedUseCase;
import com.synaptixfit.application.service.planner.CalendarFeedService;
import com.synaptixfit.domain.port.output.planner.CalendarFeedRepositoryPort;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de la suscripción al calendario (enlace privado .ics). */
@Configuration
public class CalendarFeedBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final CalendarFeedRepositoryPort feeds;
    private final ExportIcsUseCase exportIcs;
    private final Clock clock;

    public CalendarFeedBeanConfiguration(TransactionalUseCaseFactory tx, CalendarFeedRepositoryPort feeds,
                                         ExportIcsUseCase exportIcs, Clock clock) {
        this.tx = tx;
        this.feeds = feeds;
        this.exportIcs = exportIcs;
        this.clock = clock;
    }

    @Bean(autowireCandidate = false)
    CalendarFeedService calendarFeedService() {
        return new CalendarFeedService(feeds, exportIcs, clock);
    }

    @Bean
    CreateCalendarFeedUseCase createCalendarFeedUseCase() {
        return tx.wrap(CreateCalendarFeedUseCase.class, calendarFeedService());
    }

    @Bean
    RevokeCalendarFeedUseCase revokeCalendarFeedUseCase() {
        return tx.wrap(RevokeCalendarFeedUseCase.class, calendarFeedService());
    }

    @Bean
    GetCalendarFeedUseCase getCalendarFeedUseCase() {
        return tx.wrap(GetCalendarFeedUseCase.class, calendarFeedService());
    }

    @Bean
    ReadCalendarFeedUseCase readCalendarFeedUseCase() {
        return tx.wrap(ReadCalendarFeedUseCase.class, calendarFeedService());
    }
}
