package com.synaptixfit.application.service.together;

import com.synaptixfit.application.port.input.together.AcceptFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.DeclineFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.EndFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.FriendStreakView;
import com.synaptixfit.application.port.input.together.NudgeFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.ProposeFriendStreakUseCase;
import com.synaptixfit.domain.exception.social.FriendshipSelfTargetException;
import com.synaptixfit.domain.exception.together.FriendStreakAlreadyExistsException;
import com.synaptixfit.domain.exception.together.FriendStreakNotFoundException;
import com.synaptixfit.domain.model.badge.StreakPause;
import com.synaptixfit.domain.model.notification.ReminderOptions;
import com.synaptixfit.domain.model.together.FriendStreak;
import com.synaptixfit.domain.model.together.FriendStreakCount;
import com.synaptixfit.domain.port.output.badge.StreakPauseRepositoryPort;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.notification.ReminderOptionsRepositoryPort;
import com.synaptixfit.domain.port.output.together.FriendStreakRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Rachas con un amigo (ADR 0044): proponer, aceptar, decir que no, terminar y «Recordárselo». Los días se cuentan
 * siempre desde cero con lo hecho por los dos ({@link FriendStreak#COUNTED_KINDS}, leído con
 * {@link ChallengeReferencePort#activity}) y las pausas de racha de cada uno (ADR 0042), con {@link FriendStreakCount}.
 * El aviso al amigo respeta sus preferencias: si apagó los avisos de racha («Más avisos»), no le llega.
 */
public class FriendStreakService implements ProposeFriendStreakUseCase, AcceptFriendStreakUseCase,
        DeclineFriendStreakUseCase, EndFriendStreakUseCase, NudgeFriendStreakUseCase {

    private final FriendStreakRepositoryPort streaks;
    private final ChallengeReferencePort activity;
    private final StreakPauseRepositoryPort pauses;
    private final ReminderOptionsRepositoryPort reminderOptions;
    private final TogetherPeople people;
    private final TogetherNotifier notifier;
    private final Clock clock;
    private final ZoneId zone;

    public FriendStreakService(FriendStreakRepositoryPort streaks, ChallengeReferencePort activity,
                               StreakPauseRepositoryPort pauses, ReminderOptionsRepositoryPort reminderOptions,
                               TogetherPeople people, TogetherNotifier notifier, Clock clock, ZoneId zone) {
        this.streaks = streaks;
        this.activity = activity;
        this.pauses = pauses;
        this.reminderOptions = reminderOptions;
        this.people = people;
        this.notifier = notifier;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public FriendStreakView propose(UUID userId, UUID friendId) {
        if (userId.equals(friendId)) {
            throw new FriendshipSelfTargetException(userId);
        }
        people.ensureFriends(userId, List.of(friendId));
        if (streaks.findBetween(userId, friendId).isPresent()) {
            throw new FriendStreakAlreadyExistsException(friendId);
        }
        FriendStreak.ensureRoom(streaks.findByUser(userId).size(), streaks.findByUser(friendId).size());
        FriendStreak saved = streaks.save(FriendStreak.propose(userId, friendId, clock.instant()));
        notifier.streakInvited(friendId, userId, saved.id());
        return view(saved, userId, people.lookup());
    }

    @Override
    public FriendStreakView accept(UUID userId, UUID streakId) {
        FriendStreak streak = owned(userId, streakId);
        streak.accept(userId, today(), clock.instant());
        return view(streaks.save(streak), userId, people.lookup());
    }

    @Override
    public void decline(UUID userId, UUID streakId) {
        FriendStreak streak = owned(userId, streakId);
        streak.ensureDeclinableBy(userId);
        streaks.delete(streak.id());
    }

    @Override
    public void end(UUID userId, UUID streakId) {
        streaks.delete(owned(userId, streakId).id());
    }

    @Override
    public FriendStreakView nudge(UUID userId, UUID streakId) {
        FriendStreak streak = owned(userId, streakId);
        UUID friendId = streak.otherThan(userId);
        LocalDate today = today();
        Days days = days(streak, userId, today);
        streak.nudge(today, days.meDone(), days.friendDone(), clock.instant());
        streaks.save(streak);
        boolean wantsStreakReminders = reminderOptions.find(friendId).map(ReminderOptions::streak).orElse(true);
        if (wantsStreakReminders) {
            notifier.streakNudged(friendId, userId, streak.id(), today.toString());
        }
        return view(streak, userId, people.lookup());
    }

    /** Rachas de la persona (propuestas y activas), las activas más largas primero. */
    List<FriendStreakView> overview(UUID userId, TogetherPeople.Lookup lookup) {
        return streaks.findByUser(userId).stream()
                .map(s -> view(s, userId, lookup))
                .sorted(Comparator.comparing((FriendStreakView v) -> v.status() != FriendStreak.Status.ACTIVE)
                        .thenComparing(v -> -v.days()))
                .toList();
    }

    private FriendStreakView view(FriendStreak streak, UUID viewerId, TogetherPeople.Lookup lookup) {
        UUID friendId = streak.otherThan(viewerId);
        boolean requestedByMe = streak.requesterId().equals(viewerId);
        if (!streak.isActive()) {
            return new FriendStreakView(streak.id(), streak.status(), lookup.of(friendId), requestedByMe, 0, false,
                    false, false, false);
        }
        LocalDate today = today();
        Days d = days(streak, viewerId, today);
        return new FriendStreakView(streak.id(), streak.status(), lookup.of(friendId), requestedByMe, d.count(),
                d.meDone(), d.friendDone(), d.paused(), streak.canNudge(today, d.meDone(), d.friendDone()));
    }

    private record Days(int count, boolean meDone, boolean friendDone, boolean paused) {
    }

    private Days days(FriendStreak streak, UUID viewerId, LocalDate today) {
        UUID friendId = streak.otherThan(viewerId);
        if (!streak.isActive()) {
            return new Days(0, false, false, false);
        }
        Instant from = streak.since().minusDays(1).atStartOfDay(zone).toInstant();
        Instant to = clock.instant();
        Set<LocalDate> mine = doneDays(viewerId, from, to);
        Set<LocalDate> theirs = doneDays(friendId, from, to);
        Set<LocalDate> myPauses = StreakPause.pausedDays(pauses.findByUser(viewerId), today);
        Set<LocalDate> theirPauses = StreakPause.pausedDays(pauses.findByUser(friendId), today);
        int count = FriendStreakCount.days(streak.since(), today, mine, theirs, myPauses, theirPauses);
        return new Days(count, mine.contains(today), theirs.contains(today),
                myPauses.contains(today) || theirPauses.contains(today));
    }

    private Set<LocalDate> doneDays(UUID userId, Instant from, Instant to) {
        return activity.activity(userId, FriendStreak.COUNTED_KINDS, from, to).stream()
                .map(f -> f.dayIn(zone))
                .collect(Collectors.toSet());
    }

    private FriendStreak owned(UUID userId, UUID streakId) {
        return streaks.findById(streakId)
                .filter(s -> s.involves(userId))
                .orElseThrow(() -> new FriendStreakNotFoundException(streakId));
    }

    private LocalDate today() {
        return LocalDate.ofInstant(clock.instant(), zone);
    }
}
