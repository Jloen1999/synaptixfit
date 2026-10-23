package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

/** Edición del nombre y/o email de un usuario: los campos nulos no cambian. */
public record UpdateUserIdentityRequest(@Size(min = 2, max = 120) String fullName,
                                        @Email @Size(max = 254) String email) {
}
