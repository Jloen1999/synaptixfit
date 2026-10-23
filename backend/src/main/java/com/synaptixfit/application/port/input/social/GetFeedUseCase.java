package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.FeedPeriod;
import com.synaptixfit.domain.model.social.PostView;
import java.time.Instant;
import java.util.UUID;

/** Página del muro visible para el usuario (filtro temporal, autor y sondeo de novedades con {@code since}). */
public interface GetFeedUseCase {

    /** {@code authorId} y {@code since} son opcionales; {@code period} nulo equivale a ALL. */
    record Query(UUID viewerId, FeedPeriod period, Instant since, UUID authorId, PageRequest page) {}

    PageResult<PostView> getFeed(Query query);
}
