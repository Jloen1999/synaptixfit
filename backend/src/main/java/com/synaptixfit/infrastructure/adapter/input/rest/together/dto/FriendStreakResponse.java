package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.application.port.input.together.FriendStreakView;
import com.synaptixfit.domain.model.together.FriendStreak;
import java.util.UUID;

/** Racha con un amigo (ADR 0044): días, si cada uno ha hecho hoy su parte y si se le puede recordar. */
public record FriendStreakResponse(UUID id, FriendStreak.Status status, PersonResponse friend, boolean requestedByMe,
                                   int days, boolean meDone, boolean friendDone, boolean paused, boolean canNudge) {

    public static FriendStreakResponse from(FriendStreakView v) {
        return new FriendStreakResponse(v.id(), v.status(), PersonResponse.from(v.friend()), v.requestedByMe(),
                v.days(), v.meDone(), v.friendDone(), v.paused(), v.canNudge());
    }
}
