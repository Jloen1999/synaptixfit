package com.synaptixfit.infrastructure.adapter.input.event.academic;

import com.synaptixfit.application.port.input.academic.PrivatizeUserNotesUseCase;
import com.synaptixfit.domain.event.user.UserPrivacyChanged;
import com.synaptixfit.domain.model.shared.Visibility;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/** Al pasar el perfil a privado, todos los apuntes del usuario pasan a privados (idempotente). */
@Component
public class AcademicPrivacyListener {

    private final PrivatizeUserNotesUseCase privatizeNotes;

    public AcademicPrivacyListener(PrivatizeUserNotesUseCase privatizeNotes) {
        this.privatizeNotes = privatizeNotes;
    }

    @EventListener
    public void on(UserPrivacyChanged event) {
        if (event.newPrivacy() == Visibility.PRIVATE) {
            privatizeNotes.privatizeAll(event.userId());
        }
    }
}
