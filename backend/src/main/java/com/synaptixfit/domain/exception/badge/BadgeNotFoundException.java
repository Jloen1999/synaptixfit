package com.synaptixfit.domain.exception.badge;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** La insignia no existe o el usuario no la ha obtenido. */
public class BadgeNotFoundException extends ResourceNotFoundException {

    public BadgeNotFoundException(UUID id) {
        super("BADGE_NOT_FOUND", "Badge", id);
    }
}
