package com.synaptixfit.application.port.input.together;

import java.util.List;

/** Todo lo que una persona tiene «Con amigos» (ADR 0044): invitaciones y lo que está en marcha. */
public record TogetherOverview(List<FriendChallengeView> challenges, List<FriendStreakView> streaks,
                               List<WorkoutTogetherView> workouts) {
}
