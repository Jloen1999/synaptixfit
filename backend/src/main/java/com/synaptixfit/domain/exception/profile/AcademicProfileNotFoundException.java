package com.synaptixfit.domain.exception.profile;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** El usuario todavía no tiene perfil académico. */
public class AcademicProfileNotFoundException extends ResourceNotFoundException {

    public AcademicProfileNotFoundException(UUID userId) {
        super("PROFILE_ACADEMIC_NOT_FOUND", "Academic profile of user", userId);
    }
}
