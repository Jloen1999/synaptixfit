package com.synaptixfit.application.service.badge;

import com.synaptixfit.application.port.input.badge.BadgeEvaluation;
import com.synaptixfit.application.port.input.badge.ChangeBadgeVisibilityUseCase;
import com.synaptixfit.application.port.input.badge.EvaluateBadgesUseCase;
import com.synaptixfit.application.port.input.badge.GetStreakUseCase;
import com.synaptixfit.application.port.input.badge.GetBadgeCatalogUseCase;
import com.synaptixfit.application.port.input.badge.ListMyBadgesUseCase;
import com.synaptixfit.application.port.input.badge.ListUnnotifiedBadgesUseCase;
import com.synaptixfit.application.port.input.badge.MarkBadgesNotifiedUseCase;
import com.synaptixfit.domain.event.badge.BadgeEarned;
import com.synaptixfit.domain.exception.badge.BadgeNotFoundException;
import com.synaptixfit.domain.model.badge.Badge;
import com.synaptixfit.domain.model.badge.BadgeActivitySnapshot;
import com.synaptixfit.domain.model.badge.BadgeCategory;
import com.synaptixfit.domain.model.badge.BadgeCriterion;
import com.synaptixfit.domain.model.badge.BadgeMetrics;
import com.synaptixfit.domain.model.badge.BadgeView;
import com.synaptixfit.domain.model.badge.StreakStatus;
import com.synaptixfit.domain.model.badge.UserBadge;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.port.output.user.UsageFocusPort;
import com.synaptixfit.domain.port.output.badge.BadgeCatalogPort;
import com.synaptixfit.domain.port.output.badge.UserActivityPort;
import com.synaptixfit.domain.port.output.badge.UserBadgeRepositoryPort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Catálogo de insignias, insignias del usuario y motor de evaluación. Las insignias no otorgan XP
 * (tampoco lo hacían en la app antigua). La racha llega por el contrato {@link GetStreakUseCase}.
 */
public class BadgeService implements GetBadgeCatalogUseCase, ListMyBadgesUseCase, EvaluateBadgesUseCase,
        ListUnnotifiedBadgesUseCase, MarkBadgesNotifiedUseCase, ChangeBadgeVisibilityUseCase {

    private final BadgeCatalogPort catalog;
    private final UserBadgeRepositoryPort userBadges;
    private final UserActivityPort activity;
    private final GetStreakUseCase streaks;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final ZoneId defaultZone;
    private final UsageFocusPort focus;

    public BadgeService(BadgeCatalogPort catalog, UserBadgeRepositoryPort userBadges, UserActivityPort activity,
                        GetStreakUseCase streaks, DomainEventPublisherPort events, Clock clock, ZoneId defaultZone) {
        this(catalog, userBadges, activity, streaks, events, clock, defaultZone, userId -> UsageFocus.BOTH);
    }

    /** @param focus enfoque de uso: el catálogo no muestra insignias del ámbito que la persona no usa */
    public BadgeService(BadgeCatalogPort catalog, UserBadgeRepositoryPort userBadges, UserActivityPort activity,
                        GetStreakUseCase streaks, DomainEventPublisherPort events, Clock clock, ZoneId defaultZone,
                        UsageFocusPort focus) {
        this.focus = focus;
        this.catalog = catalog;
        this.userBadges = userBadges;
        this.activity = activity;
        this.streaks = streaks;
        this.events = events;
        this.clock = clock;
        this.defaultZone = defaultZone;
    }

    @Override
    public List<BadgeView> getBadgeCatalog(UUID userId, BadgeCategory category, String zone) {
        ZoneId z = UserZones.resolve(zone, defaultZone);
        Map<UUID, UserBadge> earned = earnedByBadge(userId);
        // El catálogo es una lectura: la racha se calcula sin guardarla (la guarda la evaluación).
        StreakStatus streak = StreakStatus.compute(activity.activeDays(userId, z),
                LocalDateTime.ofInstant(clock.instant(), z));
        Map<BadgeCriterion, Integer> metrics = metrics(userId, z, streak, earned.size());
        UsageFocus usage = focus.focusOf(userId);
        return catalog.findAll().stream()
                .filter(b -> category == null || b.category() == category)
                .filter(b -> b.category().visibleFor(usage))
                .map(b -> new BadgeView(b, earned.get(b.id()), b.currentValue(metrics)))
                .toList();
    }

    @Override
    public List<BadgeView> listMyBadges(UUID userId, boolean includeHidden) {
        return earnedViews(userId).stream()
                .filter(v -> includeHidden || v.earned().visible())
                .toList();
    }

    @Override
    public List<BadgeView> listUnnotifiedBadges(UUID userId) {
        return earnedViews(userId).stream().filter(v -> !v.earned().notified()).toList();
    }

    @Override
    public BadgeEvaluation evaluateBadges(UUID userId, String zone) {
        ZoneId z = UserZones.resolve(zone, defaultZone);
        StreakStatus streak = streaks.getStreak(userId, z.getId());
        BadgeActivitySnapshot snapshot = activity.snapshot(userId, z);
        LocalDate today = LocalDate.ofInstant(clock.instant(), z);
        List<Badge> all = catalog.findAll();
        Set<UUID> earned = new HashSet<>(earnedByBadge(userId).keySet());
        List<BadgeView> newly = new ArrayList<>();
        // Se repite hasta un punto fijo: obtener insignias puede cumplir «insignias_obtenidas».
        while (true) {
            Map<BadgeCriterion, Integer> metrics =
                    BadgeMetrics.compute(snapshot, streak.currentDays(), earned.size(), today);
            List<Badge> met = all.stream().filter(b -> !earned.contains(b.id()) && b.isMetBy(metrics)).toList();
            if (met.isEmpty()) {
                break;
            }
            for (Badge badge : met) {
                earned.add(badge.id());
                UserBadge userBadge = UserBadge.earn(userId, badge.id(), clock.instant());
                if (userBadges.awardIfAbsent(userBadge)) {
                    newly.add(new BadgeView(badge, userBadge, badge.currentValue(metrics)));
                    events.publish(new BadgeEarned(userId, badge.id(), badge.name(), clock.instant()));
                }
            }
        }
        return new BadgeEvaluation(newly, streak);
    }

    @Override
    public void markBadgesNotified(UUID userId, List<UUID> badgeIds) {
        for (UUID badgeId : badgeIds) {
            UserBadge badge = userBadges.find(userId, badgeId).orElseThrow(() -> new BadgeNotFoundException(badgeId));
            if (!badge.notified()) {
                badge.markNotified();
                userBadges.save(badge);
            }
        }
    }

    @Override
    public BadgeView changeBadgeVisibility(UUID userId, UUID badgeId, boolean visible) {
        UserBadge earned = userBadges.find(userId, badgeId).orElseThrow(() -> new BadgeNotFoundException(badgeId));
        Badge badge = catalog.findById(badgeId).orElseThrow(() -> new BadgeNotFoundException(badgeId));
        earned.changeVisibility(visible);
        UserBadge saved = userBadges.save(earned);
        return new BadgeView(badge, saved, badge.criterionValue());
    }

    private Map<BadgeCriterion, Integer> metrics(UUID userId, ZoneId zone, StreakStatus streak, int earnedCount) {
        return BadgeMetrics.compute(activity.snapshot(userId, zone), streak.currentDays(), earnedCount,
                LocalDate.ofInstant(clock.instant(), zone));
    }

    private Map<UUID, UserBadge> earnedByBadge(UUID userId) {
        return userBadges.findByUser(userId).stream()
                .collect(Collectors.toMap(UserBadge::badgeId, Function.identity(), (a, b) -> a));
    }

    private List<BadgeView> earnedViews(UUID userId) {
        Map<UUID, Badge> badges = catalog.findAll().stream()
                .collect(Collectors.toMap(Badge::id, Function.identity()));
        return userBadges.findByUser(userId).stream()
                .filter(ub -> badges.containsKey(ub.badgeId()))
                .sorted(Comparator.comparing(UserBadge::earnedAt).reversed())
                .map(ub -> {
                    Badge b = badges.get(ub.badgeId());
                    return new BadgeView(b, ub, b.criterionValue());
                })
                .toList();
    }
}
