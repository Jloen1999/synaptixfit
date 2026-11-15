package com.synaptixfit.infrastructure.adapter.input.rest.user;

import com.synaptixfit.application.port.input.auth.ChangePasswordUseCase;
import com.synaptixfit.application.port.input.user.GetAgeTodayUseCase;
import com.synaptixfit.application.port.input.user.GetCurrentUserUseCase;
import com.synaptixfit.application.port.input.user.RemoveAvatarUseCase;
import com.synaptixfit.application.port.input.user.UpdateAccountUseCase;
import com.synaptixfit.application.port.input.user.UploadAvatarUseCase;
import com.synaptixfit.domain.exception.user.AvatarInvalidImageException;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.infrastructure.adapter.input.rest.auth.dto.ChangePasswordRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.user.dto.AccountResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.user.dto.UpdateAccountRequest;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.io.IOException;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/** Cuenta del usuario autenticado. */
@Tag(name = "Account")
@RestController
@RequestMapping("/api/v1/me")
public class AccountController {

    private final GetCurrentUserUseCase getCurrentUser;
    private final UpdateAccountUseCase updateAccount;
    private final ChangePasswordUseCase changePassword;
    private final GetAgeTodayUseCase ageToday;
    private final UploadAvatarUseCase uploadAvatar;
    private final RemoveAvatarUseCase removeAvatar;

    public AccountController(GetCurrentUserUseCase getCurrentUser, UpdateAccountUseCase updateAccount,
                             ChangePasswordUseCase changePassword, GetAgeTodayUseCase ageToday,
                             UploadAvatarUseCase uploadAvatar, RemoveAvatarUseCase removeAvatar) {
        this.getCurrentUser = getCurrentUser;
        this.updateAccount = updateAccount;
        this.changePassword = changePassword;
        this.ageToday = ageToday;
        this.uploadAvatar = uploadAvatar;
        this.removeAvatar = removeAvatar;
    }

    /** {@code zone}: la del móvil, opcional, para la edad (ADR 0036). */
    private AccountResponse respond(User user, String zone) {
        return AccountResponse.from(user, ageToday.ageToday(user, zone));
    }

    @GetMapping
    public AccountResponse me(@CurrentUserId UUID userId, @RequestParam(required = false) String zone) {
        return respond(getCurrentUser.getCurrentUser(userId), zone);
    }

    @PatchMapping
    public AccountResponse update(@CurrentUserId UUID userId, @RequestParam(required = false) String zone,
                                  @Valid @RequestBody UpdateAccountRequest request) {
        return respond(updateAccount.updateAccount(new UpdateAccountUseCase.Command(
                userId, request.fullName(), request.avatarUrl(), request.privacy(), request.usageFocus(),
                request.birthDate(), Boolean.TRUE.equals(request.removeBirthDate()))), zone);
    }

    /** Foto de perfil desde el móvil (campo {@code file}, una imagen JPG, PNG o WEBP). Devuelve la cuenta (ADR 0052). */
    @PostMapping(value = "/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public AccountResponse uploadAvatar(@CurrentUserId UUID userId, @RequestParam(required = false) String zone,
                                        @RequestPart("file") MultipartFile file) {
        byte[] content;
        try {
            content = file.getBytes();
        } catch (IOException e) {
            throw new AvatarInvalidImageException();
        }
        return respond(uploadAvatar.uploadAvatar(new UploadAvatarUseCase.Command(userId, content)), zone);
    }

    /** Quita la foto de perfil (también la de Google). Devuelve la cuenta. */
    @DeleteMapping("/avatar")
    public AccountResponse removeAvatar(@CurrentUserId UUID userId, @RequestParam(required = false) String zone) {
        return respond(removeAvatar.removeAvatar(userId), zone);
    }

    @PutMapping("/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void changePassword(@CurrentUserId UUID userId, @Valid @RequestBody ChangePasswordRequest request) {
        changePassword.changePassword(new ChangePasswordUseCase.Command(
                userId, request.currentPassword(), request.newPassword()));
    }
}
