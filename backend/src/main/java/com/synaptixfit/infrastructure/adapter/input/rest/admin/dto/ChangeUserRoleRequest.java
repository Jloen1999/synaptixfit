package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.user.Role;
import jakarta.validation.constraints.NotNull;

/** Rol nuevo. */
public record ChangeUserRoleRequest(@NotNull Role role) {
}
