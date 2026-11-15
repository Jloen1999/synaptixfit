package com.synaptixfit.application.service.together;

import com.synaptixfit.application.port.input.together.LeaveSharedWithUserUseCase;
import com.synaptixfit.domain.model.together.FriendChallenge;
import com.synaptixfit.domain.model.together.WorkoutTogether;
import com.synaptixfit.domain.port.output.together.FriendChallengeRepositoryPort;
import com.synaptixfit.domain.port.output.together.FriendStreakRepositoryPort;
import com.synaptixfit.domain.port.output.together.WorkoutTogetherRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;

/**
 * Implementa {@link LeaveSharedWithUserUseCase} (ADR 0044). Al bloquear o dejar de ser amigos la racha entre los dos
 * se termina y, en cada reto, entreno o sala de estudio que comparten, sale quien diga
 * {@link com.synaptixfit.domain.model.together.TogetherMembers#leavingWhenSeparated}. Es idempotente: lo que ya no es
 * compartido no cambia.
 */
public class TogetherCleanupService implements LeaveSharedWithUserUseCase {

    private final FriendStreakRepositoryPort streaks;
    private final FriendChallengeRepositoryPort challenges;
    private final WorkoutTogetherRepositoryPort workouts;
    private final StudyRoomService studyRooms;
    private final Clock clock;
    private final ZoneId zone;

    public TogetherCleanupService(FriendStreakRepositoryPort streaks, FriendChallengeRepositoryPort challenges,
                                  WorkoutTogetherRepositoryPort workouts, StudyRoomService studyRooms, Clock clock,
                                  ZoneId zone) {
        this.streaks = streaks;
        this.challenges = challenges;
        this.workouts = workouts;
        this.studyRooms = studyRooms;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public void leaveShared(UUID userId, UUID otherUserId, boolean blocked) {
        Instant now = clock.instant();
        streaks.findBetween(userId, otherUserId).ifPresent(s -> streaks.delete(s.id()));
        // Cada reto y entreno se vuelve a leer bloqueado antes de sacar a nadie (ADR 0045).
        for (FriendChallenge found : challenges.findVisibleTo(userId, now)) {
            FriendChallenge c = challenges.findByIdForUpdate(found.id()).orElse(null);
            if (c == null) {
                continue;
            }
            c.members().leavingWhenSeparated(c.creatorId(), userId, otherUserId, blocked)
                    .filter(leaving -> c.leave(leaving, now))
                    .ifPresent(leaving -> challenges.save(c));
        }
        for (WorkoutTogether found : workouts.findVisibleTo(userId, LocalDate.ofInstant(now, zone))) {
            WorkoutTogether w = workouts.findByIdForUpdate(found.id()).orElse(null);
            if (w == null) {
                continue;
            }
            w.members().leavingWhenSeparated(w.hostId(), userId, otherUserId, blocked)
                    .filter(leaving -> w.leave(leaving, now))
                    .ifPresent(leaving -> workouts.save(w));
        }
        studyRooms.separate(userId, otherUserId, blocked);
    }
}
