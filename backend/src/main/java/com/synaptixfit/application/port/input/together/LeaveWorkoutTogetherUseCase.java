package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Sale de un «Entrenamos juntos»; su sesión sigue siendo suya. */
public interface LeaveWorkoutTogetherUseCase {

    void leave(UUID userId, UUID workoutId);
}
