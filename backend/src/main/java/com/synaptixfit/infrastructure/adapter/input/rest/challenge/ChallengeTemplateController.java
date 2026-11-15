package com.synaptixfit.infrastructure.adapter.input.rest.challenge;

import com.synaptixfit.application.port.input.challenge.ListChallengeTemplatesUseCase;
import com.synaptixfit.application.port.input.challenge.StartChallengeTemplateUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ChallengeResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ChallengeTemplateResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ResponseTime;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.i18n.RequestLanguage;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.Clock;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Plantillas de retos productivos ({@link ListChallengeTemplatesUseCase}) y «Empezar este reto»
 * ({@link StartChallengeTemplateUseCase}), ADR 0043. Los textos van en el idioma de la app.
 */
@Tag(name = "Challenges")
@RestController
@RequestMapping("/api/v1/challenges/templates")
public class ChallengeTemplateController {

    private final ListChallengeTemplatesUseCase list;
    private final StartChallengeTemplateUseCase start;
    private final Clock clock;
    private final ZoneId zone;

    public ChallengeTemplateController(ListChallengeTemplatesUseCase list, StartChallengeTemplateUseCase start,
                                       Clock clock,
                                       @Value("${synaptixfit.gamification.zone:Europe/Madrid}") String zone) {
        this.list = list;
        this.start = start;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    @GetMapping
    public List<ChallengeTemplateResponse> list(@CurrentUserId UUID userId) {
        ListChallengeTemplatesUseCase.Gallery gallery = list.listTemplates(userId, RequestLanguage.code());
        return gallery.templates().stream()
                .map(t -> ChallengeTemplateResponse.from(t, gallery.running().contains(t.code())))
                .toList();
    }

    /** Crea un reto propio y privado a partir de la plantilla; empieza ahora. */
    @PostMapping("/{templateId}/start")
    @ResponseStatus(HttpStatus.CREATED)
    public ChallengeResponse start(@CurrentUserId UUID userId, @PathVariable UUID templateId) {
        return ChallengeResponse.own(start.startTemplate(userId, templateId, RequestLanguage.code()),
                ResponseTime.of(clock, zone));
    }
}
