package com.synaptixfit.infrastructure.adapter.input.rest.auth;

import com.synaptixfit.application.port.input.auth.ChangePasswordUseCase;
import com.synaptixfit.application.port.input.auth.LoginUseCase;
import com.synaptixfit.application.port.input.auth.LoginWithGoogleUseCase;
import com.synaptixfit.application.port.input.auth.LogoutUseCase;
import com.synaptixfit.application.port.input.auth.RefreshSessionUseCase;
import com.synaptixfit.application.port.input.auth.RegisterUserUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.AuthResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.ChangePasswordRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.GoogleLoginRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.LoginRequest;
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

/** Registro, inicio y cierre de sesión. */
@Tag(name = "Auth")
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final RegisterUserUseCase register;
    private final LoginUseCase login;
    private final LoginWithGoogleUseCase loginWithGoogle;
    private final RefreshSessionUseCase refresh;
    private final LogoutUseCase logout;

    public AuthController(RegisterUserUseCase register, LoginUseCase login, LoginWithGoogleUseCase loginWithGoogle,
                          RefreshSessionUseCase refresh, LogoutUseCase logout) {
        this.register = register;
        this.login = login;
        this.loginWithGoogle = loginWithGoogle;
        this.refresh = refresh;
        this.logout = logout;
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
}
