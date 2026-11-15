package com.synaptixfit.application.service.together;

import com.synaptixfit.application.port.input.together.GetTogetherLimitsUseCase;
import com.synaptixfit.application.port.input.together.TogetherLimits;
import com.synaptixfit.domain.model.together.FriendChallenge;
import com.synaptixfit.domain.model.together.FriendStreak;
import com.synaptixfit.domain.model.together.StudyRoom;
import com.synaptixfit.domain.model.together.StudyRoomTimes;
import com.synaptixfit.domain.model.together.WorkoutTogether;

/** Implementa {@link GetTogetherLimitsUseCase} con los topes que fija cada modelo del dominio (ADR 0044, 0045 y 0053). */
public class TogetherLimitsService implements GetTogetherLimitsUseCase {

    private static final TogetherLimits LIMITS = new TogetherLimits(FriendChallenge.MAX_FRIENDS,
            WorkoutTogether.MAX_FRIENDS, StudyRoom.MAX_FRIENDS, FriendStreak.MAX_PER_PERSON, StudyRoom.MAX_ROUNDS,
            new TogetherLimits.Range(StudyRoomTimes.MIN_FOCUS_MINUTES, StudyRoomTimes.MAX_FOCUS_MINUTES),
            new TogetherLimits.Range(StudyRoomTimes.MIN_BREAK_MINUTES, StudyRoomTimes.MAX_BREAK_MINUTES),
            StudyRoomTimes.PRESETS.stream()
                    .map(t -> new TogetherLimits.TimesOption(t.focusMinutes(), t.breakMinutes()))
                    .toList());

    @Override
    public TogetherLimits limits() {
        return LIMITS;
    }
}
