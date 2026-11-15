package com.synaptixfit.application.service.together;

import com.synaptixfit.application.port.input.together.GetTogetherLimitsUseCase;
import com.synaptixfit.application.port.input.together.TogetherLimits;
import com.synaptixfit.domain.model.together.FriendChallenge;
import com.synaptixfit.domain.model.together.FriendStreak;
import com.synaptixfit.domain.model.together.StudyRoom;
import com.synaptixfit.domain.model.together.StudyRoomLength;
import com.synaptixfit.domain.model.together.WorkoutTogether;
import java.util.Arrays;

/** Implementa {@link GetTogetherLimitsUseCase} con los topes que fija cada modelo del dominio (ADR 0044 y 0045). */
public class TogetherLimitsService implements GetTogetherLimitsUseCase {

    private static final TogetherLimits LIMITS = new TogetherLimits(FriendChallenge.MAX_FRIENDS,
            WorkoutTogether.MAX_FRIENDS, StudyRoom.MAX_FRIENDS, FriendStreak.MAX_PER_PERSON, StudyRoom.MAX_ROUNDS,
            Arrays.stream(StudyRoomLength.values())
                    .map(l -> new TogetherLimits.LengthOption(l, l.focusMinutes(), l.breakMinutes()))
                    .toList());

    @Override
    public TogetherLimits limits() {
        return LIMITS;
    }
}
