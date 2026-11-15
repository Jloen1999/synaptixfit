package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.NotFoundException;
import java.util.UUID;

/** La denuncia de una persona ya no está en la cola de moderación. */
public class UserReportNotFoundException extends NotFoundException {

    public UserReportNotFoundException(UUID id) {
        super("USER_REPORT_NOT_FOUND", "User report " + id + " not found");
    }
}
