package com.synaptixfit.application.port.input.user;

import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import java.util.UUID;

/** Actualiza los datos básicos de la cuenta. Los campos nulos no cambian. */
public interface UpdateAccountUseCase {

    record Command(UUID userId, String fullName, String avatarUrl, Visibility privacy, UsageFocus usageFocus) {

        public Command(UUID userId, String fullName, String avatarUrl, Visibility privacy) {
            this(userId, fullName, avatarUrl, privacy, null);
        }
    }

    User updateAccount(Command command);
}
