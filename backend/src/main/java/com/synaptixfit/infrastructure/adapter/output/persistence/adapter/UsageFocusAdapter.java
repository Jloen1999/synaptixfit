package com.synaptixfit.infrastructure.adapter.output.persistence.adapter;

import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.user.UsageFocusPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.util.UUID;
import org.springframework.stereotype.Component;

/** Implementa {@link UsageFocusPort} leyendo la cuenta con {@link UserRepositoryPort}. */
@Component
public class UsageFocusAdapter implements UsageFocusPort {

    private final UserRepositoryPort users;

    public UsageFocusAdapter(UserRepositoryPort users) {
        this.users = users;
    }

    @Override
    public UsageFocus focusOf(UUID userId) {
        return users.findById(userId).map(User::effectiveFocus).orElse(UsageFocus.BOTH);
    }
}
