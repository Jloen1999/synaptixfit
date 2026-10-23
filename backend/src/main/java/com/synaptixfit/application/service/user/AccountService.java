package com.synaptixfit.application.service.user;

import com.synaptixfit.application.port.input.user.GetCurrentUserUseCase;
import com.synaptixfit.application.port.input.user.UpdateAccountUseCase;
import com.synaptixfit.domain.event.user.UserPrivacyChanged;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.util.UUID;

/** Consulta y edición de la cuenta propia. */
public class AccountService implements GetCurrentUserUseCase, UpdateAccountUseCase {

    private final UserRepositoryPort users;
    private final DomainEventPublisherPort events;
    private final Clock clock;

    public AccountService(UserRepositoryPort users, DomainEventPublisherPort events, Clock clock) {
        this.users = users;
        this.events = events;
        this.clock = clock;
    }

    @Override
    public User getCurrentUser(UUID userId) {
        return users.findById(userId)
                .filter(User::isActive)
                .orElseThrow(() -> new UserNotFoundException(userId));
    }

    @Override
    public User updateAccount(Command command) {
        User user = getCurrentUser(command.userId());
        if (command.fullName() != null) {
            user.rename(command.fullName());
        }
        if (command.avatarUrl() != null) {
            user.changeAvatar(command.avatarUrl().isBlank() ? null : command.avatarUrl());
        }
        boolean privacyChanged = command.privacy() != null && command.privacy() != user.privacy();
        if (command.privacy() != null) {
            user.changePrivacy(command.privacy());
        }
        if (command.usageFocus() != null) {
            user.chooseFocus(command.usageFocus());
        }
        User saved = users.save(user);
        if (privacyChanged) {
            events.publish(new UserPrivacyChanged(saved.id(), saved.privacy(), clock.instant()));
        }
        return saved;
    }
}
