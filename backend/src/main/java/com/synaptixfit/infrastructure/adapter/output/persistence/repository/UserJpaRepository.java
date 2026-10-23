package com.synaptixfit.infrastructure.adapter.output.persistence.repository;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.UserEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code usuarios}. */
public interface UserJpaRepository extends JpaRepository<UserEntity, UUID> {

    Optional<UserEntity> findByEmail(String email);

    Optional<UserEntity> findByGoogleSub(String googleSub);

    boolean existsByEmail(String email);
}
