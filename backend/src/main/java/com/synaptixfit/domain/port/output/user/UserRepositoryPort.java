package com.synaptixfit.domain.port.output.user;

import com.synaptixfit.domain.model.user.User;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de usuarios. */
public interface UserRepositoryPort {

    Optional<User> findById(UUID id);

    Optional<User> findByEmail(String normalizedEmail);

    Optional<User> findByGoogleSubject(String subject);

    boolean existsByEmail(String normalizedEmail);

    User save(User user);
}
