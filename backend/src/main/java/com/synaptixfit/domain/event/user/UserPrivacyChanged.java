package com.synaptixfit.domain.event.user;

import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.util.UUID;

/** El usuario ha cambiado su privacidad. Al pasar a PRIVATE, sus rutinas y retos públicos deben ocultarse. */
public record UserPrivacyChanged(UUID userId, Visibility newPrivacy, Instant occurredAt) implements DomainEvent {
}
