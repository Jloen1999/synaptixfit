package com.synaptixfit.application.port.input.user;

import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Actualiza los datos básicos de la cuenta. Los campos nulos no cambian; la fecha de nacimiento se quita con
 * {@code removeBirthDate} (ADR 0036).
 */
public interface UpdateAccountUseCase {

    record Command(UUID userId, String fullName, String avatarUrl, Visibility privacy, UsageFocus usageFocus,
                   LocalDate birthDate, boolean removeBirthDate) {

        public Command(UUID userId, String fullName, String avatarUrl, Visibility privacy, UsageFocus usageFocus) {
            this(userId, fullName, avatarUrl, privacy, usageFocus, null, false);
        }

        public Command(UUID userId, String fullName, String avatarUrl, Visibility privacy) {
            this(userId, fullName, avatarUrl, privacy, null);
        }
    }

    User updateAccount(Command command);
}
