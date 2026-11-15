package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.application.port.input.together.TogetherOverview;
import java.util.List;

/** Pantalla «Con amigos» (ADR 0044 y 0045): invitaciones y lo que está en marcha, cada cosa con mi situación. */
public record TogetherOverviewResponse(List<FriendChallengeResponse> challenges, List<FriendStreakResponse> streaks,
                                       List<WorkoutTogetherResponse> workouts, List<StudyRoomResponse> studyRooms) {

    public static TogetherOverviewResponse from(TogetherOverview o) {
        return new TogetherOverviewResponse(o.challenges().stream().map(FriendChallengeResponse::from).toList(),
                o.streaks().stream().map(FriendStreakResponse::from).toList(),
                o.workouts().stream().map(WorkoutTogetherResponse::from).toList(),
                o.studyRooms().stream().map(StudyRoomResponse::from).toList());
    }
}
