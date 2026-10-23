package com.synaptixfit.application.service.challenge;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeQuery;
import com.synaptixfit.domain.model.challenge.ChallengeSummary;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.ProgressEntry;
import com.synaptixfit.domain.model.challenge.StudyBlockProgress;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.ExperienceChange;
import com.synaptixfit.domain.model.challenge.OwnerAudience;
import com.synaptixfit.domain.port.output.challenge.ChallengeAudiencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** Dobles en memoria de los puertos de retos. */
final class ChallengeFixtures {

    static final Clock CLOCK = Clock.fixed(Instant.parse("2026-10-01T10:00:00Z"), ZoneOffset.UTC);

    final Map<UUID, Challenge> store = new HashMap<>();
    final List<ProgressEntry> progress = new ArrayList<>();
    final List<Integer> awarded = new ArrayList<>();
    final List<Integer> revoked = new ArrayList<>();
    final List<DomainEvent> events = new ArrayList<>();
    final Set<UUID> ownedRefs = new HashSet<>();
    final Map<UUID, StudyBlockProgress> blocks = new HashMap<>();
    /** Instantes de fin de las sesiones de entrenamiento completadas (recuento de los retos por sesiones). */
    final List<Instant> trainingSessions = new ArrayList<>();
    boolean audienceAllows;

    final ChallengeRepositoryPort repository = new ChallengeRepositoryPort() {
        public Optional<Challenge> findById(UUID id) { return Optional.ofNullable(store.get(id)); }
        public Challenge save(Challenge c) { store.put(c.id(), c); return c; }
        public void delete(UUID id) { store.remove(id); }
        public PageResult<Challenge> findByOwner(UUID o, ChallengeQuery q, PageRequest p, Instant now) {
            List<Challenge> items = store.values().stream().filter(c -> c.isOwnedBy(o)).toList();
            return new PageResult<>(items, p.page(), p.size(), items.size());
        }
        public ChallengeSummary summarize(UUID o, Instant now) { return new ChallengeSummary(0, 0, 0); }
        public List<Challenge> findActiveByOwner(UUID o, Instant now) {
            return store.values().stream().filter(c -> c.isOwnedBy(o) && !c.completed()).toList();
        }
        public List<Challenge> findByLinkedEntity(UUID o, UUID e) {
            return store.values().stream().filter(c -> c.isOwnedBy(o))
                    .filter(c -> (c.link() != null && c.link().entityId().equals(e))
                            || c.milestones().stream().anyMatch(m -> m.link() != null && m.link().entityId().equals(e)))
                    .toList();
        }
        public Optional<Challenge> findByMilestoneId(UUID m) {
            return store.values().stream().filter(c -> c.hasMilestone(m)).findFirst();
        }
        public List<Challenge> findTrainingTrackedByOwner(UUID o) {
            return store.values().stream().filter(c -> c.isOwnedBy(o) && c.type() == ChallengeType.FITNESS
                    && c.sessionTarget() != null).toList();
        }
        public List<Challenge> findNonPrivateByOwner(UUID o) {
            return store.values().stream().filter(c -> c.isOwnedBy(o) && c.visibility() != Visibility.PRIVATE).toList();
        }
        public ProgressEntry saveProgress(ProgressEntry e) { progress.add(e); return e; }
        public List<ProgressEntry> findProgress(UUID id) { return progress; }
    };

    final ChallengeReferencePort references = new ChallengeReferencePort() {
        public boolean subjectBelongsTo(UUID u, UUID s) { return ownedRefs.contains(s); }
        public boolean deadlineBelongsTo(UUID u, UUID d) { return ownedRefs.contains(d); }
        public boolean studyBlockBelongsTo(UUID u, UUID b) { return ownedRefs.contains(b); }
        public boolean noteBelongsTo(UUID u, UUID n) { return ownedRefs.contains(n); }
        public boolean fileBelongsTo(UUID u, UUID f) { return ownedRefs.contains(f); }
        public StudyBlockProgress studyBlockProgress(UUID u, UUID m) {
            return blocks.getOrDefault(m, new StudyBlockProgress(0, 0));
        }
        public int completedTrainingSessions(UUID u, Instant from, Instant to) {
            return (int) trainingSessions.stream().filter(t -> !t.isBefore(from) && !t.isAfter(to)).count();
        }
    };

    final ChallengeAudiencePort audience = new ChallengeAudiencePort() {
        public PageResult<CommunityEntry> findCommunity(UUID v, ChallengeType t, String q, PageRequest p, Instant now) {
            List<CommunityEntry> items = store.values().stream().filter(c -> !c.isOwnedBy(v))
                    .map(c -> new CommunityEntry(c.id(), "Autor")).toList();
            return new PageResult<>(items, p.page(), p.size(), items.size());
        }
        public OwnerAudience audienceOf(UUID v, UUID o) { return new OwnerAudience(true, !audienceAllows, audienceAllows); }
    };

    final AwardExperienceUseCase award = (u, a) -> {
        awarded.add(a);
        return new ExperienceChange(1, a, 0, a);
    };
    final RevokeExperienceUseCase revoke = (u, a) -> {
        revoked.add(a);
        return new ExperienceChange(1, 0, 0, -a);
    };

    ChallengeEffects effects() {
        return new ChallengeEffects(award, revoke, events::add, CLOCK);
    }

    int netXp() {
        return awarded.stream().mapToInt(Integer::intValue).sum() - revoked.stream().mapToInt(Integer::intValue).sum();
    }
}
