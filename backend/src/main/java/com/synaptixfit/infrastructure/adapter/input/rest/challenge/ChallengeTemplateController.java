package com.synaptixfit.infrastructure.adapter.input.rest.challenge;

import com.synaptixfit.application.port.input.challenge.ListChallengeTemplatesUseCase;
import com.synaptixfit.application.port.input.challenge.StartChallengeTemplateUseCase;
import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ChallengeResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ChallengeRuleResponse;
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

    /**
     * Plantilla de reto: cuántos días dura, la regla con la que se cuenta solo y {@code running} si ya hay un reto
     * suyo sin terminar (entonces no se puede empezar otro).
     */
    public record ChallengeTemplateResponse(UUID id, String code, String title, String goal, ChallengeType type,
                                            Difficulty difficulty, int xpReward, int days, ChallengeRuleResponse rule,
                                            boolean running) {
        static ChallengeTemplateResponse from(ChallengeTemplate t, boolean running) {
            return new ChallengeTemplateResponse(t.id(), t.code(), t.title(), t.goal(), t.type(), t.difficulty(),
                    t.difficulty().xp(), t.days(), ChallengeRuleResponse.of(t.rule(), 0), running);
        }
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
