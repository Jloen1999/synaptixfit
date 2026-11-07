package com.synaptixfit.infrastructure.adapter.output.persistence.adapter;

import com.synaptixfit.domain.model.notification.ReminderPlanner;
import com.synaptixfit.domain.model.user.BirthDate;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.user.BirthdayPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Component;

/** Implementa {@link BirthdayPort} leyendo la cuenta con {@link UserRepositoryPort}; felicita por el nombre de pila. */
@Component
public class BirthdayAdapter implements BirthdayPort {

    private final UserRepositoryPort users;

    public BirthdayAdapter(UserRepositoryPort users) {
        this.users = users;
    }

    @Override
    public Optional<ReminderPlanner.Birthday> birthdayOf(UUID userId) {
        return users.findById(userId)
                .filter(User::isActive)
                .filter(u -> u.birthDate() != null)
                .map(u -> new ReminderPlanner.Birthday(new BirthDate(u.birthDate()), firstName(u.fullName())));
    }

    private static String firstName(String fullName) {
        String trimmed = fullName == null ? "" : fullName.strip();
        int space = trimmed.indexOf(' ');
        return space < 0 ? trimmed : trimmed.substring(0, space);
    }
}
