package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.admin.AdminUserDetail;
import java.util.UUID;

/** Ficha de un usuario (cuenta y perfiles), también si está anonimizado. */
public interface GetUserDetailUseCase {

    AdminUserDetail getUserDetail(UUID userId);
}
