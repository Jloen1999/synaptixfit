package com.synaptixfit.application.service.challenge;

import com.synaptixfit.application.port.input.challenge.ListChallengeTemplatesUseCase;
import com.synaptixfit.application.port.input.challenge.StartChallengeTemplateUseCase;
import com.synaptixfit.domain.exception.challenge.ChallengeTemplateAlreadyActiveException;
import com.synaptixfit.domain.exception.challenge.ChallengeTemplateNotFoundException;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeChanges;
import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeRepositoryPort;
import com.synaptixfit.domain.port.output.challenge.ChallengeTemplateRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Plantillas de reto productivo (ADR 0043): las lista según el modo de uso ({@link ChallengeTemplate#availableFor}) y
 * crea un reto privado desde una con {@link Challenge#fromTemplate}. Ya creado se cuenta con su regla
 * ({@link RuleTracker}), igual que tras cada evento. No se permiten dos retos sin terminar de la misma plantilla: se
 * contarían con lo mismo y darían el XP dos veces.
 */
public class ChallengeTemplateService implements ListChallengeTemplatesUseCase, StartChallengeTemplateUseCase {

    private final ChallengeTemplateRepositoryPort templates;
    private final ChallengeRepositoryPort challenges;
    private final UserRepositoryPort users;
    private final ChallengeEffects effects;
    private final RuleTracker rules;
    private final Clock clock;
    private final ZoneId zone;

    public ChallengeTemplateService(ChallengeTemplateRepositoryPort templates, ChallengeRepositoryPort challenges,
                                    UserRepositoryPort users, ChallengeReferencePort references,
                                    ChallengeEffects effects, Clock clock, ZoneId zone) {
        this.templates = templates;
        this.challenges = challenges;
        this.users = users;
        this.effects = effects;
        this.rules = new RuleTracker(references, zone);
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public Gallery listTemplates(UUID userId, String language) {
        UsageFocus focus = focusOf(userId);
        List<ChallengeTemplate> available = templates.findAll(language).stream()
                .filter(t -> t.availableFor(focus))
                .toList();
        return new Gallery(available, running(userId, clock.instant()));
    }

    @Override
    public Challenge startTemplate(UUID userId, UUID templateId, String language) {
        ChallengeTemplate template = templates.findById(templateId, language)
                .filter(t -> t.availableFor(focusOf(userId)))
                .orElseThrow(() -> new ChallengeTemplateNotFoundException(templateId));
        Instant now = clock.instant();
        if (running(userId, now).contains(template.code())) {
            throw new ChallengeTemplateAlreadyActiveException(template.code());
        }
        Challenge challenge = Challenge.fromTemplate(UUID.randomUUID(), userId, template.detailsFrom(now, zone),
                template.rule(), template.code(), now);
        ChallengeChanges changes = rules.apply(challenge, LocalDate.ofInstant(now, zone));
        Challenge saved = challenges.save(challenge);
        effects.apply(saved, changes);
        return saved;
    }

    /** Códigos de las plantillas con un reto sin completar ni vencer. */
    private Set<String> running(UUID userId, Instant now) {
        return challenges.findActiveByOwner(userId, now).stream()
                .map(Challenge::templateCode)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
    }

    private UsageFocus focusOf(UUID userId) {
        return users.findById(userId).map(User::effectiveFocus).orElse(UsageFocus.BOTH);
    }
}
