package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.GetHealthConsentUseCase;
import com.synaptixfit.application.port.input.training.GiveHealthConsentUseCase;
import com.synaptixfit.application.port.input.training.WithdrawHealthConsentUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.HealthConsentResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Consentimiento expreso para el registro diario (ADR 0034): consultarlo, darlo y retirarlo. Es aparte de aceptar
 * la política porque son datos de salud.
 */
@Tag(name = "Training wellbeing")
@RestController
@RequestMapping("/api/v1/me/health-consent")
public class HealthConsentController {

    private final GetHealthConsentUseCase getConsent;
    private final GiveHealthConsentUseCase giveConsent;
    private final WithdrawHealthConsentUseCase withdrawConsent;

    public HealthConsentController(GetHealthConsentUseCase getConsent, GiveHealthConsentUseCase giveConsent,
                                   WithdrawHealthConsentUseCase withdrawConsent) {
        this.getConsent = getConsent;
        this.giveConsent = giveConsent;
        this.withdrawConsent = withdrawConsent;
    }

    @GetMapping
    public HealthConsentResponse consent(@CurrentUserId UUID userId) {
        return HealthConsentResponse.from(getConsent.getHealthConsent(userId));
    }

    @PutMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void give(@CurrentUserId UUID userId) {
        giveConsent.giveHealthConsent(userId);
    }

    /** Retira el consentimiento; con {@code deleteRecords=true} borra además todos los registros diarios. */
    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void withdraw(@CurrentUserId UUID userId,
                         @RequestParam(defaultValue = "false") boolean deleteRecords) {
        withdrawConsent.withdrawHealthConsent(userId, deleteRecords);
    }
}
