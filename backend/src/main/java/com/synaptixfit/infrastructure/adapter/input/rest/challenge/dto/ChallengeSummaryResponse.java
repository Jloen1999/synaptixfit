package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.ChallengeSummary;

/** Recuento de retos del usuario por estado. */
public record ChallengeSummaryResponse(long active, long completed, long expired, long total) {

    public static ChallengeSummaryResponse from(ChallengeSummary s) {
        return new ChallengeSummaryResponse(s.active(), s.completed(), s.expired(), s.total());
    }
}
