package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.CreateCalendarFeedUseCase;
import com.synaptixfit.application.port.input.planner.ExportIcsUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarFeedUseCase;
import com.synaptixfit.application.port.input.planner.ReadCalendarFeedUseCase;
import com.synaptixfit.application.port.input.planner.RevokeCalendarFeedUseCase;
import com.synaptixfit.domain.exception.planner.CalendarFeedNotFoundException;
import com.synaptixfit.domain.model.planner.CalendarFeed;
import com.synaptixfit.domain.port.output.planner.CalendarFeedRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Suscripción al calendario: crea, consulta y revoca el enlace privado ({@link CalendarFeed}) y sirve el
 * calendario con {@link ExportIcsUseCase}, el mismo contenido que la exportación manual.
 */
public class CalendarFeedService implements CreateCalendarFeedUseCase, RevokeCalendarFeedUseCase,
        GetCalendarFeedUseCase, ReadCalendarFeedUseCase {

    /** Ventana del calendario suscrito: lo reciente para consultarlo y lo próximo para planificar. */
    static final Duration PAST = Duration.ofDays(30);
    static final Duration AHEAD = Duration.ofDays(180);

    private final CalendarFeedRepositoryPort feeds;
    private final ExportIcsUseCase exportIcs;
    private final Clock clock;

    public CalendarFeedService(CalendarFeedRepositoryPort feeds, ExportIcsUseCase exportIcs, Clock clock) {
        this.feeds = feeds;
        this.exportIcs = exportIcs;
        this.clock = clock;
    }

    @Override
    public Result createFeed(UUID userId) {
        CalendarFeed.Issued issued = CalendarFeed.issue(userId, clock.instant());
        CalendarFeed saved = feeds.save(issued.feed());
        return new Result(issued.token(), saved.createdAt());
    }

    @Override
    public void revokeFeed(UUID userId) {
        feeds.deleteByUser(userId);
    }

    @Override
    public Optional<Instant> activeSince(UUID userId) {
        return feeds.findByUser(userId).map(CalendarFeed::createdAt);
    }

    @Override
    public String readFeed(String token) {
        if (token == null || token.isBlank()) {
            throw new CalendarFeedNotFoundException();
        }
        CalendarFeed feed = feeds.findByTokenHash(CalendarFeed.hash(token))
                .orElseThrow(CalendarFeedNotFoundException::new);
        Instant now = clock.instant();
        return exportIcs.exportIcs(feed.userId(), now.minus(PAST), now.plus(AHEAD));
    }
}
