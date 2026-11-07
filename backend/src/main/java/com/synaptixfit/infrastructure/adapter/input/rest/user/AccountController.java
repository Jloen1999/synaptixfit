package com.synaptixfit.infrastructure.adapter.input.rest.user;

import com.synaptixfit.application.port.input.auth.ChangePasswordUseCase;
import com.synaptixfit.application.port.input.user.GetCurrentUserUseCase;
import com.synaptixfit.application.port.input.user.UpdateAccountUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.ChangePasswordRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.user.dto.AccountResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.user.dto.UpdateAccountRequest;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.Clock;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Cuenta del usuario autenticado. */
@Tag(name = "Account")
@RestController
@RequestMapping("/api/v1/me")
public class AccountController {

    private final GetCurrentUserUseCase getCurrentUser;
    private final UpdateAccountUseCase updateAccount;
    private final ChangePasswordUseCase changePassword;
    private final Clock clock;

    public AccountController(GetCurrentUserUseCase getCurrentUser, UpdateAccountUseCase updateAccount,
                             ChangePasswordUseCase changePassword, Clock clock) {
        this.getCurrentUser = getCurrentUser;
        this.updateAccount = updateAccount;
        this.changePassword = changePassword;
        this.clock = clock;
    }

    @GetMapping
    public AccountResponse me(@CurrentUserId UUID userId) {
        return AccountResponse.from(getCurrentUser.getCurrentUser(userId), clock);
    }

    @PatchMapping
    public AccountResponse update(@CurrentUserId UUID userId, @Valid @RequestBody UpdateAccountRequest request) {
        return AccountResponse.from(updateAccount.updateAccount(new UpdateAccountUseCase.Command(
                userId, request.fullName(), request.avatarUrl(), request.privacy(), request.usageFocus(),
                request.birthDate(), Boolean.TRUE.equals(request.removeBirthDate()))), clock);
    }

    @PutMapping("/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void changePassword(@CurrentUserId UUID userId, @Valid @RequestBody ChangePasswordRequest request) {
        changePassword.changePassword(new ChangePasswordUseCase.Command(
                userId, request.currentPassword(), request.newPassword()));
    }
}
