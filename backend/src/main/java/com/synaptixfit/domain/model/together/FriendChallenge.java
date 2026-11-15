package com.synaptixfit.domain.model.together;

import com.synaptixfit.domain.exception.together.FriendChallengeTemplateNotAllowedException;
import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import com.synaptixfit.domain.model.challenge.ChallengeRule;
import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import com.synaptixfit.domain.model.challenge.RuleMetric;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Set;
import java.util.UUID;

/**
 * Reto privado entre amigos (ADR 0044): sale de una plantilla de reto que se cuenta sola (ADR 0043) y lo cuenta el
 * servidor con la misma {@link ChallengeRule}. Dura de {@value #MIN_DAYS} a {@value #MAX_DAYS} días y reúne de 2 a
 * {@value #MAX_PEOPLE} personas (quien lo crea y de 1 a {@value #MAX_FRIENDS} amigos mutuos).
 *
 * <p>La meta de cada persona es la de la plantilla en proporción a los días ({@link #perPersonTarget}); en modo
 * juntos la meta del grupo es esa meta por cada persona dentro, así salir o entrar la ajusta. Lo que se suma cada
 * día tiene un tope ({@link #dailyCapFor}) en los dos modos: en competición es lo que evita premiar el exceso.
 * Nunca vale una plantilla de bienestar (registro diario): esos datos no se comparten.
 */
public final class FriendChallenge {

    public static final int MIN_DAYS = 7;
    public static final int MAX_DAYS = 14;
    public static final int MAX_PEOPLE = 25;
    public static final int MAX_FRIENDS = MAX_PEOPLE - 1;
    /** Minutos de Pomodoro que cuentan como mucho al día (cuatro Pomodoros largos y un poco más). */
    public static final int FOCUS_MINUTES_DAILY_CAP = 120;

    private final UUID id;
    private final UUID creatorId;
    private final UUID templateId;
    private final FriendChallengeMode mode;
    private final Instant startAt;
    private final Instant endAt;
    private final int days;
    private final int perPersonTarget;
    private final int dailyCap;
    private final Instant createdAt;
    private final TogetherMembers members;

    public FriendChallenge(UUID id, UUID creatorId, UUID templateId, FriendChallengeMode mode, Instant startAt,
                           Instant endAt, int days, int perPersonTarget, int dailyCap, Instant createdAt,
                           TogetherMembers members) {
        this.id = Guard.notNull(id, "id");
        this.creatorId = Guard.notNull(creatorId, "creatorId");
        this.templateId = Guard.notNull(templateId, "templateId");
        this.mode = Guard.notNull(mode, "mode");
        this.startAt = Guard.notNull(startAt, "startAt");
        this.endAt = Guard.notNull(endAt, "endAt");
        this.days = Guard.range(days, "days", MIN_DAYS, MAX_DAYS);
        this.perPersonTarget = Guard.range(perPersonTarget, "perPersonTarget", 1, ChallengeRule.MAX_TARGET);
        this.dailyCap = Guard.range(dailyCap, "dailyCap", 1, ChallengeRule.MAX_TARGET);
        this.createdAt = Guard.notNull(createdAt, "createdAt");
        this.members = Guard.notNull(members, "members");
    }

    /** Crea el reto desde ahora hasta el final del día {@code days} (hoy cuenta como el primero). */
    public static FriendChallenge create(UUID creatorId, ChallengeTemplate template, Set<UUID> friendIds,
                                         FriendChallengeMode mode, int days, Instant now, ZoneId zone) {
        Guard.notNull(template, "template");
        if (template.rule().privateOnly()) {
            throw new FriendChallengeTemplateNotAllowedException(template.id());
        }
        Guard.range(days, "days", MIN_DAYS, MAX_DAYS);
        LocalDate lastDay = LocalDate.ofInstant(now, zone).plusDays(days - 1L);
        Instant end = lastDay.plusDays(1).atStartOfDay(zone).toInstant().minusSeconds(1);
        return new FriendChallenge(UUID.randomUUID(), creatorId, template.id(),
                mode == null ? FriendChallengeMode.COOPERATIVE : mode, now, end, days,
                perPersonTarget(template, days), dailyCapFor(template.rule().metric()), now,
                TogetherMembers.create(creatorId, friendIds, 1, MAX_FRIENDS, now));
    }

    /**
     * Meta de una persona: la de la plantilla en proporción a los días, hacia arriba (12 de 14 días son 6 en 7 días;
     * 600 minutos en 14 días son 300 en 7 días), y nunca más días o semanas de los que dura el reto.
     */
    public static int perPersonTarget(ChallengeTemplate template, int days) {
        ChallengeRule rule = template.rule();
        int scaled = (int) Math.ceil((double) rule.target() * days / template.days());
        return switch (rule.unit()) {
            case DAY -> Math.max(1, Math.min(scaled, days));
            // Un reto de 7 a 14 días pisa como mucho 3 semanas de lunes a domingo.
            case WEEK -> Math.max(1, Math.min(scaled, (days + 6) / 7 + 1));
            case TOTAL -> Math.max(1, scaled);
        };
    }

    /** Tope de lo que suma una persona en un día: los minutos de Pomodoro hasta 120; lo demás, una cosa. */
    public static int dailyCapFor(RuleMetric metric) {
        return metric == RuleMetric.FOCUS_MINUTES ? FOCUS_MINUTES_DAILY_CAP : 1;
    }

    public boolean isOver(Instant now) {
        return now.isAfter(endAt);
    }

    /** Meta común en modo juntos: la de cada persona por las que están dentro. */
    public int groupTarget() {
        return perPersonTarget * Math.max(1, members.joinedIds().size());
    }

    public boolean canView(UUID userId) {
        return members.canView(userId);
    }

    /** Acepta la invitación (o vuelve tras salir) mientras el reto siga en marcha. */
    public void join(UUID userId, Instant now) {
        if (isOver(now)) {
            throw new TogetherInvalidStateException("Challenge is over");
        }
        members.join(userId, now);
    }

    public void decline(UUID userId, Instant now) {
        members.decline(userId, now);
    }

    /** Sale en un toque; si era una invitación sin contestar, cuenta como «no». Devuelve si cambió algo. */
    public boolean leave(UUID userId, Instant now) {
        return members.leave(userId, now);
    }

    public UUID id() { return id; }
    public UUID creatorId() { return creatorId; }
    public UUID templateId() { return templateId; }
    public FriendChallengeMode mode() { return mode; }
    public Instant startAt() { return startAt; }
    public Instant endAt() { return endAt; }
    public int days() { return days; }
    public int perPersonTarget() { return perPersonTarget; }
    public int dailyCap() { return dailyCap; }
    public Instant createdAt() { return createdAt; }
    public TogetherMembers members() { return members; }
}
