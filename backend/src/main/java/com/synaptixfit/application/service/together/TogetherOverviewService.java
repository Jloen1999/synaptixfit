package com.synaptixfit.application.service.together;

import com.synaptixfit.application.port.input.together.ListTogetherUseCase;
import com.synaptixfit.application.port.input.together.TogetherOverview;
import java.util.UUID;

/**
 * Implementa {@link ListTogetherUseCase}: junta en una sola respuesta los retos, las rachas y los entrenos de hoy con
 * amigos (ADR 0044), cada uno calculado por su servicio, con una sola caché de nombres por petición.
 */
public class TogetherOverviewService implements ListTogetherUseCase {

    private final FriendChallengeService challenges;
    private final FriendStreakService streaks;
    private final WorkoutTogetherService workouts;
    private final TogetherPeople people;

    public TogetherOverviewService(FriendChallengeService challenges, FriendStreakService streaks,
                                   WorkoutTogetherService workouts, TogetherPeople people) {
        this.challenges = challenges;
        this.streaks = streaks;
        this.workouts = workouts;
        this.people = people;
    }

    @Override
    public TogetherOverview overview(UUID userId, String language) {
        TogetherPeople.Lookup lookup = people.lookup();
        return new TogetherOverview(challenges.overview(userId, language, lookup), streaks.overview(userId, lookup),
                workouts.overview(userId, lookup));
    }
}
