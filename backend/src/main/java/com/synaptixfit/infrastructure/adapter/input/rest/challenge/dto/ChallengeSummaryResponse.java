package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.ChallengeSummary;

/** Recuento de retos del usuario por estado; {@code active} incluye los {@code upcoming} (por empezar). */
public record ChallengeSummaryResponse(long active, long completed, long expired, long upcoming, long total) {

    public static ChallengeSummaryResponse from(ChallengeSummary s) {
        return new ChallengeSummaryResponse(s.active(), s.completed(), s.expired(), s.upcoming(), s.total());
    }
}
