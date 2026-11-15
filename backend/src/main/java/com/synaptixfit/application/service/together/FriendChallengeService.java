package com.synaptixfit.application.service.together;

import com.synaptixfit.application.port.input.together.CreateFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.DeclineFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.FriendChallengeView;
import com.synaptixfit.application.port.input.together.GetFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.JoinFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.LeaveFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.ListFriendChallengeTemplatesUseCase;
import com.synaptixfit.application.port.input.together.ReactFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.RemoveFriendChallengeReactionUseCase;
import com.synaptixfit.domain.exception.challenge.ChallengeTemplateNotFoundException;
import com.synaptixfit.domain.exception.together.FriendChallengeNotFoundException;
import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import com.synaptixfit.domain.model.challenge.ActivityFact;
import com.synaptixfit.domain.model.challenge.ChallengeRule;
import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.together.FriendChallenge;
import com.synaptixfit.domain.model.together.FriendChallengeMode;
import com.synaptixfit.domain.model.together.FriendChallengeScore;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.Reaction;
import com.synaptixfit.domain.model.together.ReactionRecord;
import com.synaptixfit.domain.model.together.TogetherMember;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeTemplateRepositoryPort;
import com.synaptixfit.domain.port.output.together.FriendChallengeReactionPort;
import com.synaptixfit.domain.port.output.together.FriendChallengeRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Retos privados entre amigos (ADR 0044): crear desde una plantilla de reto que se cuenta sola, aceptar, decir que
 * no, salir y reaccionar en el tablón. Lo que suma cada persona se calcula siempre desde cero con lo que lee
 * {@link ChallengeReferencePort#activity} (la misma definición que los retos propios) y {@link FriendChallengeScore};
 * no se guarda ningún recuento ni se da XP (el reto es para animarse, no para subir de nivel).
 */
public class FriendChallengeService implements ListFriendChallengeTemplatesUseCase, CreateFriendChallengeUseCase,
        GetFriendChallengeUseCase, JoinFriendChallengeUseCase, DeclineFriendChallengeUseCase,
        LeaveFriendChallengeUseCase, ReactFriendChallengeUseCase, RemoveFriendChallengeReactionUseCase {

    /** Un reto terminado sigue a la vista una semana (para ver cómo acabó). */
    static final Duration KEEP_AFTER_END = Duration.ofDays(7);
    /** Entradas del tablón que se enseñan como mucho (las más recientes). */
    static final int BOARD_LIMIT = 60;
    /** Margen para lo que solo tiene fecha; la regla ya filtra por día. */
    private static final Duration DAY_MARGIN = Duration.ofDays(1);

    private final FriendChallengeRepositoryPort challenges;
    private final FriendChallengeReactionPort reactions;
    private final ChallengeTemplateRepositoryPort templates;
    private final ChallengeReferencePort activity;
    private final UserRepositoryPort users;
    private final TogetherPeople people;
    private final TogetherNotifier notifier;
    private final Clock clock;
    private final ZoneId zone;

    public FriendChallengeService(FriendChallengeRepositoryPort challenges, FriendChallengeReactionPort reactions,
                                  ChallengeTemplateRepositoryPort templates, ChallengeReferencePort activity,
                                  UserRepositoryPort users, TogetherPeople people, TogetherNotifier notifier,
                                  Clock clock, ZoneId zone) {
        this.challenges = challenges;
        this.reactions = reactions;
        this.templates = templates;
        this.activity = activity;
        this.users = users;
        this.people = people;
        this.notifier = notifier;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public List<ChallengeTemplate> friendTemplates(UUID userId, String language) {
        UsageFocus focus = focusOf(userId);
        return templates.findAll(language).stream()
                .filter(t -> !t.rule().privateOnly() && t.availableFor(focus))
                .toList();
    }

    @Override
    public FriendChallengeView create(Command command, String language) {
        Guard.notNull(command, "command");
        ChallengeTemplate template = templates.findById(command.templateId(), language)
                .filter(t -> t.availableFor(focusOf(command.userId())))
                .orElseThrow(() -> new ChallengeTemplateNotFoundException(command.templateId()));
        Instant now = clock.instant();
        FriendChallenge challenge = FriendChallenge.create(command.userId(), template,
                command.friendIds() == null ? Set.of() : command.friendIds(), command.mode(),
                command.days(), now, zone);
        people.ensureFriends(command.userId(), challenge.members().invitedIds());
        FriendChallenge saved = challenges.save(challenge);
        notifier.challengeInvited(saved.members().invitedIds(), command.userId(), saved.id(), template.title());
        return view(saved, template, command.userId(), true, people.lookup());
    }

    @Override
    public FriendChallengeView get(UUID userId, UUID challengeId, String language) {
        FriendChallenge challenge = visible(userId, challengeId);
        return view(challenge, templateOf(challenge, language), userId, true, people.lookup());
    }

    @Override
    public FriendChallengeView join(UUID userId, UUID challengeId, String language) {
        // Quien salió ya no lo ve, pero puede volver («Deshacer»): basta con haber estado y seguir siendo amigo. Tras
        // un bloqueo o dejar de ser amigos no se vuelve, y se responde como si no existiera.
        FriendChallenge challenge = challenges.findByIdForUpdate(challengeId)
                .filter(c -> c.members().find(userId).isPresent())
                .filter(c -> people.canJoin(userId, c.creatorId(), c.members().joinedIds()))
                .orElseThrow(() -> new FriendChallengeNotFoundException(challengeId));
        challenge.join(userId, clock.instant());
        FriendChallenge saved = challenges.save(challenge);
        return view(saved, templateOf(saved, language), userId, true, people.lookup());
    }

    @Override
    public void decline(UUID userId, UUID challengeId) {
        FriendChallenge challenge = visibleForUpdate(userId, challengeId);
        challenge.decline(userId, clock.instant());
        challenges.save(challenge);
    }

    @Override
    public void leave(UUID userId, UUID challengeId) {
        FriendChallenge challenge = visibleForUpdate(userId, challengeId);
        if (challenge.leave(userId, clock.instant())) {
            challenges.save(challenge);
        }
    }

    @Override
    public void react(UUID userId, UUID challengeId, UUID recipientId, LocalDate day, Reaction reaction) {
        FriendChallenge challenge = boardOf(userId, challengeId, recipientId, day);
        ChallengeRule rule = templateOf(challenge, "es").rule();
        List<ActivityFact> facts = activity.activity(recipientId, rule.metric().sources(),
                challenge.startAt().minus(DAY_MARGIN), challenge.endAt().plus(DAY_MARGIN));
        if (!FriendChallengeScore.contributionDays(rule, facts, challenge.startAt(), challenge.endAt(), zone)
                .contains(day)) {
            throw new TogetherInvalidStateException("Nothing to react to that day");
        }
        reactions.put(new ReactionRecord(challenge.id(), recipientId, day, userId, Guard.notNull(reaction, "reaction"),
                clock.instant()));
    }

    @Override
    public void removeReaction(UUID userId, UUID challengeId, UUID recipientId, LocalDate day) {
        FriendChallenge challenge = visibleForUpdate(userId, challengeId);
        reactions.remove(challenge.id(), recipientId, day, userId);
    }

    /** Retos en marcha o terminados hace menos de una semana, sin tablón (para la pantalla «Con amigos»). */
    List<FriendChallengeView> overview(UUID userId, String language, TogetherPeople.Lookup lookup) {
        Instant now = clock.instant();
        return challenges.findVisibleTo(userId, now.minus(KEEP_AFTER_END)).stream()
                .filter(c -> c.canView(userId))
                .sorted(Comparator.comparing(FriendChallenge::endAt))
                .map(c -> view(c, templateOf(c, language), userId, false, lookup))
                .toList();
    }

    /** Solo quien está dentro reacciona, y a otra persona que está dentro, un día del reto que ya ha llegado. */
    private FriendChallenge boardOf(UUID userId, UUID challengeId, UUID recipientId, LocalDate day) {
        // Bloqueado: que nadie salga del reto mientras se comprueba que los dos siguen dentro.
        FriendChallenge challenge = visibleForUpdate(userId, challengeId);
        boolean bothIn = challenge.members().joinedIds().contains(userId)
                && challenge.members().joinedIds().contains(recipientId);
        LocalDate first = LocalDate.ofInstant(challenge.startAt(), zone);
        LocalDate last = LocalDate.ofInstant(challenge.endAt(), zone);
        LocalDate today = LocalDate.ofInstant(clock.instant(), zone);
        if (!bothIn || userId.equals(recipientId) || day == null || day.isBefore(first) || day.isAfter(last)
                || day.isAfter(today)) {
            throw new TogetherInvalidStateException("Cannot react to that entry");
        }
        return challenge;
    }

    private FriendChallengeView view(FriendChallenge challenge, ChallengeTemplate template, UUID viewerId,
                                     boolean withBoard, TogetherPeople.Lookup lookup) {
        ChallengeRule rule = template.rule();
        Instant now = clock.instant();
        Map<UUID, Integer> points = new HashMap<>();
        Map<UUID, List<LocalDate>> days = new HashMap<>();
        for (UUID memberId : challenge.members().joinedIds()) {
            List<ActivityFact> facts = activity.activity(memberId, rule.metric().sources(),
                    challenge.startAt().minus(DAY_MARGIN), challenge.endAt().plus(DAY_MARGIN));
            points.put(memberId, FriendChallengeScore.points(rule, facts, challenge.startAt(), challenge.endAt(), zone,
                    challenge.dailyCap()));
            days.put(memberId, FriendChallengeScore.contributionDays(rule, facts, challenge.startAt(),
                    challenge.endAt(), zone));
        }
        boolean competition = challenge.mode() == FriendChallengeMode.COMPETITION;
        List<FriendChallengeView.Member> members = challenge.members().all().stream()
                .filter(m -> m.status().canView())
                .sorted(Comparator.comparing(
                                (TogetherMember m) -> competition ? -points.getOrDefault(m.userId(), 0) : 0)
                        .thenComparing(m -> m.status().ordinal()))
                .map(m -> new FriendChallengeView.Member(lookup.of(m.userId()), m.status(),
                        points.getOrDefault(m.userId(), 0) > 0,
                        competition && m.joined() ? points.getOrDefault(m.userId(), 0) : null,
                        m.userId().equals(viewerId)))
                .toList();
        MemberStatus myStatus = challenge.members().find(viewerId).map(TogetherMember::status)
                .orElse(MemberStatus.LEFT);
        List<FriendChallengeView.BoardEntry> board = withBoard && myStatus == MemberStatus.JOINED
                ? board(challenge, viewerId, days, lookup) : List.of();
        int total = points.values().stream().mapToInt(Integer::intValue).sum();
        return new FriendChallengeView(challenge.id(), template.title(), template.goal(), rule.metric(), rule.unit(),
                challenge.mode(), challenge.startAt(), challenge.endAt(), challenge.days(), myStatus,
                lookup.of(challenge.creatorId()), total, challenge.groupTarget(), points.getOrDefault(viewerId, 0),
                challenge.perPersonTarget(), challenge.isOver(now), members, board);
    }

    /**
     * Una entrada por persona y día en que sumó algo. Las reacciones de una entrada solo las cuenta quien la publicó;
     * a los demás solo se les dice la suya (ADR 0044: el número de ánimos no se convierte en una competición).
     */
    private List<FriendChallengeView.BoardEntry> board(FriendChallenge challenge, UUID viewerId,
                                                       Map<UUID, List<LocalDate>> days, TogetherPeople.Lookup lookup) {
        List<ReactionRecord> all = reactions.findByChallenge(challenge.id());
        List<UUID> joined = challenge.members().joinedIds();
        List<FriendChallengeView.BoardEntry> entries = new ArrayList<>();
        days.forEach((memberId, memberDays) -> {
            for (LocalDate day : memberDays) {
                boolean mine = memberId.equals(viewerId);
                Map<Reaction, Integer> counts = new EnumMap<>(Reaction.class);
                Reaction myReaction = null;
                for (ReactionRecord r : all) {
                    if (!r.recipientId().equals(memberId) || !r.day().equals(day) || !joined.contains(r.authorId())) {
                        continue;
                    }
                    if (mine) {
                        counts.merge(r.reaction(), 1, Integer::sum);
                    }
                    if (r.authorId().equals(viewerId)) {
                        myReaction = r.reaction();
                    }
                }
                entries.add(new FriendChallengeView.BoardEntry(lookup.of(memberId), day, mine, counts, myReaction));
            }
        });
        entries.sort(Comparator.comparing(FriendChallengeView.BoardEntry::day).reversed()
                .thenComparing(e -> e.person().name() == null ? "" : e.person().name()));
        return entries.size() > BOARD_LIMIT ? List.copyOf(entries.subList(0, BOARD_LIMIT)) : List.copyOf(entries);
    }

    private FriendChallenge visible(UUID userId, UUID challengeId) {
        return challenges.findById(challengeId)
                .filter(c -> c.canView(userId))
                .orElseThrow(() -> new FriendChallengeNotFoundException(challengeId));
    }

    /** Como {@link #visible}, pero bloqueado: para las acciones que lo cambian (ADR 0045). */
    private FriendChallenge visibleForUpdate(UUID userId, UUID challengeId) {
        return challenges.findByIdForUpdate(challengeId)
                .filter(c -> c.canView(userId))
                .orElseThrow(() -> new FriendChallengeNotFoundException(challengeId));
    }

    private ChallengeTemplate templateOf(FriendChallenge challenge, String language) {
        return templates.findById(challenge.templateId(), language)
                .orElseThrow(() -> new ChallengeTemplateNotFoundException(challenge.templateId()));
    }

    private UsageFocus focusOf(UUID userId) {
        return users.findById(userId).map(User::effectiveFocus).orElse(UsageFocus.BOTH);
    }
}
