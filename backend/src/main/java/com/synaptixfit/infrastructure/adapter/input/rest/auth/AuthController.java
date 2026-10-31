package com.synaptixfit.infrastructure.adapter.input.rest.auth;

import com.synaptixfit.application.port.input.auth.ChangePasswordUseCase;
import com.synaptixfit.application.port.input.auth.LoginUseCase;
import com.synaptixfit.application.port.input.auth.LoginWithGoogleUseCase;
import com.synaptixfit.application.port.input.auth.LogoutUseCase;
import com.synaptixfit.application.port.input.auth.RefreshSessionUseCase;
import com.synaptixfit.application.port.input.auth.RegisterUserUseCase;
import com.synaptixfit.application.port.input.auth.RequestPasswordResetUseCase;
import com.synaptixfit.application.port.input.auth.ResetPasswordUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.AuthResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.ChangePasswordRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.GoogleLoginRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.LoginRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.PasswordResetConfirmRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.PasswordResetRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.RefreshRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.RegisterRequest;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Registro, inicio y cierre de sesión y recuperar la contraseña por correo. */
@Tag(name = "Auth")
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final RegisterUserUseCase register;
    private final LoginUseCase login;
    private final LoginWithGoogleUseCase loginWithGoogle;
    private final RefreshSessionUseCase refresh;
    private final LogoutUseCase logout;
    private final RequestPasswordResetUseCase requestPasswordReset;
    private final ResetPasswordUseCase resetPassword;

    public AuthController(RegisterUserUseCase register, LoginUseCase login, LoginWithGoogleUseCase loginWithGoogle,
                          RefreshSessionUseCase refresh, LogoutUseCase logout,
                          RequestPasswordResetUseCase requestPasswordReset, ResetPasswordUseCase resetPassword) {
        this.register = register;
        this.login = login;
        this.loginWithGoogle = loginWithGoogle;
        this.refresh = refresh;
        this.logout = logout;
        this.requestPasswordReset = requestPasswordReset;
        this.resetPassword = resetPassword;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return AuthResponse.from(register.register(
                new RegisterUserUseCase.Command(request.email(), request.password(), request.fullName())));
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return AuthResponse.from(login.login(new LoginUseCase.Command(request.email(), request.password())));
    }

    @PostMapping("/google")
    public AuthResponse google(@Valid @RequestBody GoogleLoginRequest request) {
        return AuthResponse.from(loginWithGoogle.loginWithGoogle(request.idToken()));
    }

    @PostMapping("/refresh")
    public AuthResponse refresh(@Valid @RequestBody RefreshRequest request) {
        return AuthResponse.from(refresh.refresh(request.refreshToken()));
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody RefreshRequest request) {
        logout.logout(request.refreshToken());
    }

    /** Envía el enlace por correo. Siempre 202: no revela si el correo está registrado. */
    @PostMapping("/password-reset")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void requestPasswordReset(@Valid @RequestBody PasswordResetRequest request) {
        requestPasswordReset.requestPasswordReset(request.email());
    }

    /** Pone la contraseña nueva con el token del enlace y cierra todas las sesiones. */
    @PostMapping("/password-reset/confirm")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resetPassword(@Valid @RequestBody PasswordResetConfirmRequest request) {
        resetPassword.resetPassword(new ResetPasswordUseCase.Command(request.token(), request.newPassword()));
    }
}
