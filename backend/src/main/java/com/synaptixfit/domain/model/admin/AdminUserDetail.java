package com.synaptixfit.domain.model.admin;

import com.synaptixfit.domain.model.user.User;

/** Ficha de un usuario en el panel: cuenta y perfiles (nulos si no los ha completado). */
public record AdminUserDetail(User user, WellbeingProfileSnapshot wellbeing, AcademicProfileSnapshot academic) {
}
