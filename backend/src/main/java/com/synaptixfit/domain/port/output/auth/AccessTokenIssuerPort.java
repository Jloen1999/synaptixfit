package com.synaptixfit.domain.port.output.auth;

import com.synaptixfit.domain.model.auth.AccessToken;
import com.synaptixfit.domain.model.user.User;

/** Emite tokens de acceso para un usuario. */
public interface AccessTokenIssuerPort {

    AccessToken issue(User user);
}
