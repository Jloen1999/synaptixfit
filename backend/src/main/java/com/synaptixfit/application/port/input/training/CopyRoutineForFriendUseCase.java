package com.synaptixfit.application.port.input.training;

import java.util.UUID;

/**
 * Copia en pausa la rutina de otra persona para «Entrenamos juntos» (ADR 0044) y dice qué día de la copia es el
 * elegido. Si ya tiene una copia de esa rutina, la reutiliza. No comprueba permisos: solo lo llama el módulo social
 * después de comprobar que las dos personas están en el mismo entreno.
 */
public interface CopyRoutineForFriendUseCase {

    Copy copyForFriend(UUID routineId, UUID dayId, UUID targetUserId);

    record Copy(UUID routineId, UUID dayId) {
    }
}
