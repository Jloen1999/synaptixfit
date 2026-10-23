package com.synaptixfit.domain.port.output.user;

import com.synaptixfit.domain.model.user.UsageFocus;
import java.util.UUID;

/** Enfoque de uso efectivo de una persona (sin elegir o inexistente = {@link UsageFocus#BOTH}). */
@FunctionalInterface
public interface UsageFocusPort {

    UsageFocus focusOf(UUID userId);
}
