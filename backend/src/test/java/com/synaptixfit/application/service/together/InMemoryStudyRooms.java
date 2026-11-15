package com.synaptixfit.application.service.together;

import com.synaptixfit.domain.model.together.StudyRoom;
import com.synaptixfit.domain.model.together.TogetherMembers;
import com.synaptixfit.domain.port.output.together.StudyRoomRepositoryPort;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** Doble en memoria de {@link StudyRoomRepositoryPort}: las rondas contadas solo cambian al reservarlas, como en la BD. */
final class InMemoryStudyRooms implements StudyRoomRepositoryPort {

    final Map<UUID, StudyRoom> rooms = new HashMap<>();
    private final Map<UUID, Integer> credited = new HashMap<>();

    @Override
    public Optional<StudyRoom> findById(UUID id) {
        return Optional.ofNullable(rooms.get(id)).map(this::copy);
    }

    @Override
    public Optional<StudyRoom> findByIdForUpdate(UUID id) {
        return findById(id);
    }

    /** Si es falso, otra petición «ya ha reservado» las rondas: esta no debe apuntar nada. */
    boolean claimsWin = true;

    @Override
    public StudyRoom save(StudyRoom room) {
        credited.putIfAbsent(room.id(), room.creditedRounds());
        StudyRoom previous = rooms.get(room.id());
        Instant started = previous != null && previous.startedAt() != null ? previous.startedAt() : room.startedAt();
        rooms.put(room.id(), new StudyRoom(room.id(), room.creatorId(), room.length(), room.rounds(),
                room.createdAt(), started, 0, new TogetherMembers(room.members().all()), room.subjects(),
                room.reactions(), room.enteredAt()));
        return room;
    }

    @Override
    public List<StudyRoom> findVisibleTo(UUID userId, Instant createdFrom) {
        return rooms.values().stream()
                .filter(r -> r.canView(userId) && !r.createdAt().isBefore(createdFrom))
                .map(this::copy)
                .toList();
    }

    @Override
    public List<UUID> findWithRoundsToCredit(Instant createdFrom) {
        return rooms.values().stream()
                .filter(r -> r.startedAt() != null && credited.getOrDefault(r.id(), 0) < r.rounds())
                .map(StudyRoom::id)
                .toList();
    }

    @Override
    public boolean claimCredits(UUID roomId, int from, int to) {
        if (!claimsWin || credited.getOrDefault(roomId, 0) != from) {
            return false;
        }
        credited.put(roomId, to);
        return true;
    }

    /** Cada lectura devuelve una copia nueva, como la BD (así una escritura vieja no cambia lo guardado). */
    private StudyRoom copy(StudyRoom r) {
        return new StudyRoom(r.id(), r.creatorId(), r.length(), r.rounds(), r.createdAt(), r.startedAt(),
                credited.getOrDefault(r.id(), 0),
                new TogetherMembers(r.members().all()), r.subjects(),
                r.reactions(), r.enteredAt());
    }
}
