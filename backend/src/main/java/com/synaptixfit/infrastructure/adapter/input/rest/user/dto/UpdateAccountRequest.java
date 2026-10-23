package com.synaptixfit.infrastructure.adapter.input.rest.user.dto;

import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.UsageFocus;
import jakarta.validation.constraints.Size;

/** Edición parcial de la cuenta: los campos nulos no cambian. */
public record UpdateAccountRequest(@Size(min = 2, max = 120) String fullName,
                                   @Size(max = 2048) String avatarUrl,
                                   Visibility privacy,
                                   UsageFocus usageFocus) {
}
