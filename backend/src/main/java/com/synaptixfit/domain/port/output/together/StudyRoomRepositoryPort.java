package com.synaptixfit.domain.port.output.together;

import com.synaptixfit.domain.model.together.StudyRoom;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Salas de «Estudiamos juntos» y sus personas (tablas {@code salas_estudio} y {@code salas_estudio_miembros}, ADR 0045). */
public interface StudyRoomRepositoryPort {

    Optional<StudyRoom> findById(UUID id);

    /**
     * La sala bloqueada hasta el final de la transacción: quien la cambia la lee así, para que dos acciones a la vez
     * (dos personas que aceptan, una que sale y otra que reacciona) no se pisen al guardar a todas las personas.
     */
    Optional<StudyRoom> findByIdForUpdate(UUID id);

    /**
     * Guarda la sala y sus personas. La hora de inicio no se pisa una vez puesta y las rondas contadas no se escriben
     * aquí (solo con {@link #claimCredits}), para que una escritura con datos viejos no las deshaga.
     */
    StudyRoom save(StudyRoom room);

    /** Las creadas desde {@code createdFrom} en las que {@code userId} está invitado o dentro. */
    List<StudyRoom> findVisibleTo(UUID userId, Instant createdFrom);

    /** Salas empezadas, creadas desde {@code createdFrom}, con rondas aún sin contar. */
    List<UUID> findWithRoundsToCredit(Instant createdFrom);

    /**
     * Reserva las rondas {@code from + 1 .. to} para contarlas: solo una escritura gana (comparar y cambiar), así dos
     * peticiones a la vez nunca apuntan dos veces el mismo Pomodoro.
     *
     * @return si esta llamada las ha reservado
     */
    boolean claimCredits(UUID roomId, int from, int to);
}
