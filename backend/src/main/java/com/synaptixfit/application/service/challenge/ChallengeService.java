package com.synaptixfit.application.service.challenge;

import com.synaptixfit.application.port.input.challenge.ChallengeView;
import com.synaptixfit.application.port.input.challenge.CloneChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.CreateChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.DeleteChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.GetChallengeSummaryUseCase;
import com.synaptixfit.application.port.input.challenge.GetChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.ListChallengeProgressUseCase;
import com.synaptixfit.application.port.input.challenge.ListCommunityChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.ListMyChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.ListPendingMilestonesUseCase;
import com.synaptixfit.application.port.input.challenge.UpdateChallengeUseCase;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.challenge.ChallengeNotFoundException;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeChanges;
import com.synaptixfit.domain.model.challenge.ChallengeDetails;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.ChallengeQuery;
import com.synaptixfit.domain.model.challenge.ChallengeStatus;
import com.synaptixfit.domain.model.challenge.ChallengeSummary;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.exception.challenge.ChallengeTypeOutsideFocusException;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.challenge.CommunityChallenge;
import com.synaptixfit.domain.model.challenge.MilestoneDraft;
import com.synaptixfit.domain.model.challenge.MilestoneStatus;
import com.synaptixfit.domain.model.challenge.PendingMilestone;
import com.synaptixfit.domain.model.challenge.ProgressEntry;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.challenge.ChallengeAudiencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Alta, edición, consulta, borrado y clonado de retos. */
public class ChallengeService implements CreateChallengeUseCase, GetChallengeUseCase, ListMyChallengesUseCase,
        GetChallengeSummaryUseCase, ListCommunityChallengesUseCase, ListPendingMilestonesUseCase,
        UpdateChallengeUseCase, DeleteChallengeUseCase, CloneChallengeUseCase, ListChallengeProgressUseCase {

    private final ChallengeRepositoryPort challenges;
    private final ChallengeAudiencePort audience;
    private final UserRepositoryPort users;
    private final ChallengeReferenceValidator references;
    private final ChallengeEffects effects;
    private final TrainingSessionTracker trainingSessions;
    private final LinkedSourcesSync linkedSources;
    private final Clock clock;
    private final ZoneId zone;

    /**
     * @param referencePort lecturas de otros módulos (recuento de entrenamientos de los retos por sesiones)
     * @param zone          zona con la que se decide el «día» de la racha de cada reto
     */
    public ChallengeService(ChallengeRepositoryPort challenges, ChallengeAudiencePort audience,
                            UserRepositoryPort users, ChallengeReferenceValidator references,
                            ChallengeReferencePort referencePort, ChallengeEffects effects, Clock clock, ZoneId zone) {
        this.challenges = challenges;
        this.audience = audience;
        this.users = users;
        this.references = references;
        this.effects = effects;
        this.trainingSessions = new TrainingSessionTracker(referencePort);
        this.linkedSources = new LinkedSourcesSync(challenges, zone);
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public Challenge createChallenge(CreateChallengeUseCase.Command command) {
        ChallengeDetails details = command.details();
        // Sin tipo, la validación del propio reto da el error de campo.
        if (details.type() != null && !details.type().allowedFor(focusOf(command.userId()))) {
            throw new ChallengeTypeOutsideFocusException();
        }
        references.checkSubject(command.userId(), details.subjectId());
        references.checkLink(command.userId(), details.link());
        List<MilestoneDraft> drafts =
                command.milestones() == null ? List.of() : command.milestones();
        references.checkDrafts(command.userId(), drafts, java.util.Set.of());
        Challenge challenge = Challenge.create(UUID.randomUUID(), command.userId(), details, drafts, clock.instant());
        return saveSynced(challenge, challenge.allLinks().stream().map(ChallengeLink::entityId).toList());
    }

    @Override
    public ChallengeView getChallenge(UUID userId, UUID challengeId) {
        Challenge challenge = challenges.findById(challengeId)
                .orElseThrow(() -> new ChallengeNotFoundException(challengeId));
        if (challenge.isOwnedBy(userId)) {
            return new ChallengeView(challenge, true, null);
        }
        if (!challenge.isVisibleTo(audience.audienceOf(userId, challenge.ownerId()))) {
            throw new ChallengeNotFoundException(challengeId);
        }
        return new ChallengeView(challenge, false, ownerName(challenge.ownerId()));
    }

    @Override
    public PageResult<Challenge> listMyChallenges(UUID userId, ChallengeQuery query, PageRequest page) {
        // Con un solo enfoque solo se listan los retos de ese ámbito (aunque queden otros de antes);
        // pedir explícitamente el otro ámbito devuelve una página vacía.
        ChallengeType only = ChallengeType.onlyFor(focusOf(userId));
        if (only != null && query.type() != null && query.type() != only) {
            return new PageResult<>(List.of(), page.page(), page.size(), 0);
        }
        ChallengeQuery effective = only == null ? query
                : new ChallengeQuery(query.status(), only, query.withTasks(), query.text());
        return challenges.findByOwner(userId, effective, page, clock.instant());
    }

    @Override
    public ChallengeSummary getChallengeSummary(UUID userId) {
        return challenges.summarize(userId, clock.instant());
    }

    @Override
    public PageResult<CommunityChallenge> listCommunityChallenges(UUID viewerId, ChallengeType type, String text,
                                                                  PageRequest page) {
        ChallengeType only = ChallengeType.onlyFor(focusOf(viewerId));
        PageResult<ChallengeAudiencePort.CommunityEntry> entries =
                audience.findCommunity(viewerId, only == null ? type : only, text == null || text.isBlank() ? null : text.strip(), page,
                        clock.instant());
        Map<UUID, Challenge> loaded = entries.items().stream()
                .map(e -> challenges.findById(e.challengeId()))
                .flatMap(Optional::stream)
                .collect(Collectors.toMap(Challenge::id, Function.identity()));
        List<CommunityChallenge> items = entries.items().stream()
                .filter(e -> loaded.containsKey(e.challengeId()))
                .map(e -> new CommunityChallenge(loaded.get(e.challengeId()), e.ownerName()))
                .toList();
        return new PageResult<>(items, entries.page(), entries.size(), entries.totalItems());
    }

    @Override
    public List<PendingMilestone> listPendingMilestones(UUID userId) {
        Instant now = clock.instant();
        // Solo retos en curso: las tareas de uno por empezar aún no se pueden hacer.
        return challenges.findActiveByOwner(userId, now).stream()
                .filter(c -> c.status(now) == ChallengeStatus.ACTIVE)
                .flatMap(c -> c.milestones().stream()
                        .filter(m -> m.status() == MilestoneStatus.AVAILABLE || m.status() == MilestoneStatus.IN_PROGRESS)
                        .map(m -> new PendingMilestone(c, m)))
                .toList();
    }

    @Override
    public Challenge updateChallenge(UpdateChallengeUseCase.Command c) {
        Challenge challenge = owned(c.userId(), c.challengeId());
        UUID subjectId = challenge.subjectId();
        if (c.clearSubject()) {
            subjectId = null;
        } else if (c.subjectId() != null) {
            references.checkSubject(c.userId(), c.subjectId());
            subjectId = c.subjectId();
        }
        ChallengeLink link = challenge.link();
        if (c.clearLink()) {
            link = null;
        } else if (c.linkType() != null || c.linkId() != null) {
            if (c.linkType() == null || c.linkId() == null) {
                throw new FieldValidationException(c.linkType() == null ? "linkedEntityType" : "linkedEntityId",
                        "REQUIRED", "linkedEntityType and linkedEntityId go together");
            }
            link = new ChallengeLink(c.linkType(), c.linkId());
            // El mismo vínculo que ya tenía no se revalida (su entrega pudo borrarse).
            if (!link.equals(challenge.link())) {
                references.checkLink(c.userId(), link);
            }
        }
        if (c.type() != null && c.type() != challenge.type() && !c.type().allowedFor(focusOf(c.userId()))) {
            throw new ChallengeTypeOutsideFocusException();
        }
        Instant previousStart = challenge.startAt();
        Instant previousEnd = challenge.endAt();
        ChallengeLink previousLink = challenge.link();
        challenge.updateDetails(new ChallengeDetails(
                c.title() != null ? c.title() : challenge.title(),
                c.type() != null ? c.type() : challenge.type(),
                c.goal() != null ? c.goal() : challenge.goal(),
                c.visibility() != null ? c.visibility() : challenge.visibility(),
                c.difficulty() != null ? c.difficulty() : challenge.difficulty(),
                c.startAt() != null ? c.startAt() : challenge.startAt(),
                c.endAt() != null ? c.endAt() : challenge.endAt(),
                subjectId, link,
                c.clearSessionTarget() ? null : c.sessionTarget() != null ? c.sessionTarget() : challenge.sessionTarget()));
        challenge.touch(clock.instant());
        // Con fechas nuevas se revisan todos los vínculos; si no, solo el del reto si ha cambiado.
        List<UUID> linksToCheck;
        if (!challenge.startAt().equals(previousStart) || !challenge.endAt().equals(previousEnd)) {
            linksToCheck = challenge.allLinks().stream().map(ChallengeLink::entityId).toList();
        } else if (link != null && !link.equals(previousLink)) {
            linksToCheck = List.of(link.entityId());
        } else {
            linksToCheck = List.of();
        }
        return saveSynced(challenge, linksToCheck);
    }

    /**
     * Guarda el reto con lo que lo hace avanzar desde fuera ya aplicado: el recuento de entrenamientos de su
     * periodo (un reto con inicio pasado, o con un objetivo rebajado, puede quedar completado) y el estado
     * actual de sus entregas y bloques (vincular una entrega ya hecha deja la tarea completada; ampliar un
     * reto vencido recupera lo ocurrido). Antes comprueba que {@code linksToCheck} vencen en su periodo.
     */
    private Challenge saveSynced(Challenge challenge, List<UUID> linksToCheck) {
        Instant now = clock.instant();
        ChallengeChanges changes = trainingSessions.apply(challenge, LocalDate.ofInstant(now, zone));
        Challenge saved = linkedSources.apply(challenges.save(challenge), linksToCheck, changes, now);
        effects.apply(saved, changes);
        return saved;
    }

    @Override
    public void deleteChallenge(UUID userId, UUID challengeId) {
        Challenge challenge = owned(userId, challengeId);
        int xp = challenge.totalXpAwarded();
        challenges.delete(challengeId);
        effects.applyXp(userId, -xp);
    }

    @Override
    public Challenge cloneChallenge(UUID userId, UUID challengeId) {
        ChallengeView source = getChallenge(userId, challengeId);
        Challenge original = source.challenge();
        if (!original.type().allowedFor(focusOf(userId))) {
            throw new ChallengeTypeOutsideFocusException();
        }
        String originOwnerName = source.owned() ? null : source.ownerName();
        if (originOwnerName == null) {
            originOwnerName = ownerName(original.ownerId());
        }
        Instant now = clock.instant();
        Challenge copy = original.cloneFor(UUID.randomUUID(), userId, originOwnerName, now);
        return challenges.save(copy);
    }

    @Override
    public List<ProgressEntry> listProgress(UUID userId, UUID challengeId) {
        owned(userId, challengeId);
        return challenges.findProgress(challengeId);
    }

    private Challenge owned(UUID userId, UUID challengeId) {
        return challenges.findById(challengeId)
                .filter(c -> c.isOwnedBy(userId))
                .orElseThrow(() -> new ChallengeNotFoundException(challengeId));
    }

    private String ownerName(UUID ownerId) {
        return users.findById(ownerId).map(User::fullName).orElse(null);
    }

    /** Enfoque de uso de la persona; si no existe (no debería), se tratan los dos ámbitos. */
    private UsageFocus focusOf(UUID userId) {
        return users.findById(userId).map(User::effectiveFocus).orElse(UsageFocus.BOTH);
    }
}
