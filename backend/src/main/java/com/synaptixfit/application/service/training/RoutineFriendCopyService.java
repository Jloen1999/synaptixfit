package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.CopyRoutineForFriendUseCase;
import com.synaptixfit.domain.exception.training.RoutineDayNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineOrigin;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.util.List;
import java.util.UUID;

/**
 * Implementa {@link CopyRoutineForFriendUseCase} para «Entrenamos juntos» (ADR 0044): la copia se guarda siempre en
 * pausa (no cambia la rutina en curso de nadie ni crea eventos en su calendario), marcada «Copiada de» su dueño, y
 * conserva el orden de semanas, días y ejercicios para encontrar el mismo día por su posición. Si la persona ya
 * tiene una copia de esa rutina, se reutiliza.
 */
public class RoutineFriendCopyService implements CopyRoutineForFriendUseCase {

    private final RoutineRepositoryPort routines;
    private final UserRepositoryPort users;
    private final Clock clock;

    public RoutineFriendCopyService(RoutineRepositoryPort routines, UserRepositoryPort users, Clock clock) {
        this.routines = routines;
        this.users = users;
        this.clock = clock;
    }

    @Override
    public Copy copyForFriend(UUID routineId, UUID dayId, UUID targetUserId) {
        Routine source = routines.findById(routineId).filter(r -> !r.isDeleted())
                .orElseThrow(() -> new RoutineNotFoundException(routineId));
        int[] position = positionOf(source, dayId);
        if (source.isOwnedBy(targetUserId)) {
            return new Copy(source.id(), dayId);
        }
        Routine copy = routines.findAllByOwner(targetUserId).stream()
                .filter(r -> !r.isDeleted() && r.origin() != null && routineId.equals(r.origin().routineId()))
                .filter(r -> dayAt(r, position) != null)
                .findFirst()
                .orElseGet(() -> routines.save(newCopy(source, targetUserId)));
        return new Copy(copy.id(), dayAt(copy, position).id());
    }

    private Routine newCopy(Routine source, UUID targetUserId) {
        String ownerName = users.findById(source.ownerId()).map(User::fullName).orElse(null);
        RoutineOrigin origin = new RoutineOrigin(source.id(), source.ownerId(), ownerName);
        String name = source.name().length() > 108 ? source.name().substring(0, 108) : source.name();
        Routine copy = source.copyFor(targetUserId, name + " (copiada)", origin, clock.instant());
        copy.pause();
        return copy;
    }

    private static int[] positionOf(Routine routine, UUID dayId) {
        List<RoutineWeek> weeks = routine.weeks();
        for (int w = 0; w < weeks.size(); w++) {
            List<RoutineDay> days = weeks.get(w).days();
            for (int d = 0; d < days.size(); d++) {
                if (days.get(d).id().equals(dayId)) {
                    return new int[] {w, d};
                }
            }
        }
        throw new RoutineDayNotFoundException(dayId);
    }

    private static RoutineDay dayAt(Routine routine, int[] position) {
        List<RoutineWeek> weeks = routine.weeks();
        if (position[0] >= weeks.size() || position[1] >= weeks.get(position[0]).days().size()) {
            return null;
        }
        return weeks.get(position[0]).days().get(position[1]);
    }
}
