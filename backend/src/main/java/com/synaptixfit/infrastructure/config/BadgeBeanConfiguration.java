package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.badge.ChangeBadgeVisibilityUseCase;
import com.synaptixfit.application.port.input.badge.EvaluateBadgesUseCase;
import com.synaptixfit.application.port.input.badge.GetBadgeCatalogUseCase;
import com.synaptixfit.application.port.input.badge.GetStreakUseCase;
import com.synaptixfit.application.port.input.badge.ListMyBadgesUseCase;
import com.synaptixfit.application.port.input.badge.ListUnnotifiedBadgesUseCase;
import com.synaptixfit.application.port.input.badge.MarkBadgesNotifiedUseCase;
import com.synaptixfit.application.service.badge.BadgeService;
import com.synaptixfit.application.service.badge.StreakService;
import com.synaptixfit.domain.port.output.badge.BadgeCatalogPort;
import com.synaptixfit.domain.port.output.badge.UserActivityPort;
import com.synaptixfit.domain.port.output.badge.UserBadgeRepositoryPort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.user.UsageFocusPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de insignias y racha diaria (patrón de {@link BeanConfiguration}). */
@Configuration
public class BadgeBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final BadgeCatalogPort catalog;
    private final UserBadgeRepositoryPort userBadges;
    private final UserActivityPort activity;
    private final UserRepositoryPort users;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final ZoneId zone;
    private final UsageFocusPort focus;

    public BadgeBeanConfiguration(TransactionalUseCaseFactory tx, BadgeCatalogPort catalog,
                                  UserBadgeRepositoryPort userBadges, UserActivityPort activity,
                                  UserRepositoryPort users, DomainEventPublisherPort events, Clock clock,
                                  @Value("${synaptixfit.gamification.zone:Europe/Madrid}") String zone,
                                  UsageFocusPort focus) {
        this.focus = focus;
        this.tx = tx;
        this.catalog = catalog;
        this.userBadges = userBadges;
        this.activity = activity;
        this.users = users;
        this.events = events;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    @Bean(autowireCandidate = false)
    StreakService streakService() {
        return new StreakService(activity, users, clock, zone);
    }

    @Bean(autowireCandidate = false)
    BadgeService badgeService() {
        return new BadgeService(catalog, userBadges, activity, streakService(), events, clock, zone, focus);
    }

    @Bean
    GetBadgeCatalogUseCase getBadgeCatalogUseCase() {
        return tx.wrap(GetBadgeCatalogUseCase.class, badgeService());
    }

    @Bean
    ListMyBadgesUseCase listMyBadgesUseCase() {
        return tx.wrap(ListMyBadgesUseCase.class, badgeService());
    }

    @Bean
    EvaluateBadgesUseCase evaluateBadgesUseCase() {
        return tx.wrap(EvaluateBadgesUseCase.class, badgeService());
    }

    @Bean
    ListUnnotifiedBadgesUseCase listUnnotifiedBadgesUseCase() {
        return tx.wrap(ListUnnotifiedBadgesUseCase.class, badgeService());
    }

    @Bean
    MarkBadgesNotifiedUseCase markBadgesNotifiedUseCase() {
        return tx.wrap(MarkBadgesNotifiedUseCase.class, badgeService());
    }

    @Bean
    ChangeBadgeVisibilityUseCase changeBadgeVisibilityUseCase() {
        return tx.wrap(ChangeBadgeVisibilityUseCase.class, badgeService());
    }

    @Bean
    GetStreakUseCase getStreakUseCase() {
        return tx.wrap(GetStreakUseCase.class, streakService());
    }
}
