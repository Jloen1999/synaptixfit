package com.synaptixfit.infrastructure.adapter.input.rest.privacy;

import com.synaptixfit.application.port.input.privacy.DeleteMyAccountUseCase;
import com.synaptixfit.application.port.input.privacy.ExportMyDataUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.ExportResponses;
import com.synaptixfit.infrastructure.adapter.input.rest.privacy.dto.DeleteAccountRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Autoservicio RGPD del usuario autenticado: descarga de sus datos y baja voluntaria. */
@Tag(name = "Privacy")
@RestController
@RequestMapping("/api/v1/me")
public class PrivacyController {

    private final ExportMyDataUseCase exportMyData;
    private final DeleteMyAccountUseCase deleteMyAccount;

    public PrivacyController(ExportMyDataUseCase exportMyData, DeleteMyAccountUseCase deleteMyAccount) {
        this.exportMyData = exportMyData;
        this.deleteMyAccount = deleteMyAccount;
    }

    @GetMapping("/export")
    public ResponseEntity<String> export(@CurrentUserId UUID userId) {
        return ExportResponses.attachment(exportMyData.exportMyData(userId));
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAccount(@CurrentUserId UUID userId,
                              @Valid @RequestBody(required = false) DeleteAccountRequest request) {
        String password = request == null ? null : request.password();
        boolean confirmed = request != null && Boolean.TRUE.equals(request.confirm());
        deleteMyAccount.deleteMyAccount(new DeleteMyAccountUseCase.Command(userId, password, confirmed));
    }
}
