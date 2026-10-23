package com.synaptixfit.infrastructure.adapter.input.event.training;

import com.synaptixfit.application.port.input.training.PrivatizeUserRoutinesUseCase;
import com.synaptixfit.domain.event.user.UserPrivacyChanged;
import com.synaptixfit.domain.model.shared.Visibility;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/** Al pasar el perfil a privado, todas las rutinas del usuario pasan a privadas (idempotente). */
@Component
public class TrainingPrivacyListener {

    private final PrivatizeUserRoutinesUseCase privatizeRoutines;

    public TrainingPrivacyListener(PrivatizeUserRoutinesUseCase privatizeRoutines) {
        this.privatizeRoutines = privatizeRoutines;
    }

    @EventListener
    public void on(UserPrivacyChanged event) {
        if (event.newPrivacy() == Visibility.PRIVATE) {
            privatizeRoutines.privatizeAll(event.userId());
        }
    }
}
