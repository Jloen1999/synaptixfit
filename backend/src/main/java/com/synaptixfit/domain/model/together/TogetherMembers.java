package com.synaptixfit.domain.model.together;

import com.synaptixfit.domain.exception.together.TogetherGroupSizeException;
import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Lista de personas de algo compartido con amigos y sus transiciones (ADR 0044): invitar al crear, aceptar,
 * decir que no y salir. La comparten {@link FriendChallenge} y {@link WorkoutTogether}.
 */
public final class TogetherMembers {

    private final List<TogetherMember> members;

    public TogetherMembers(List<TogetherMember> members) {
        this.members = new ArrayList<>(members);
    }

    /** Quien crea entra dentro; los amigos, invitados. Sin repetir y sin incluirse a uno mismo. */
    static TogetherMembers create(UUID ownerId, Set<UUID> friendIds, int minFriends, int maxFriends, Instant now) {
        Set<UUID> invited = new LinkedHashSet<>(friendIds);
        invited.remove(ownerId);
        if (invited.size() < minFriends || invited.size() > maxFriends) {
            throw new TogetherGroupSizeException(invited.size(), minFriends, maxFriends);
        }
        List<TogetherMember> list = new ArrayList<>();
        list.add(new TogetherMember(ownerId, MemberStatus.JOINED, now));
        invited.forEach(id -> list.add(new TogetherMember(id, MemberStatus.INVITED, now)));
        return new TogetherMembers(list);
    }

    public Optional<TogetherMember> find(UUID userId) {
        return members.stream().filter(m -> m.userId().equals(userId)).findFirst();
    }

    public boolean canView(UUID userId) {
        return find(userId).map(m -> m.status().canView()).orElse(false);
    }

    /** Acepta una invitación pendiente o vuelve tras salir (solo mientras siga en marcha, lo comprueba el dueño). */
    void join(UUID userId, Instant now) {
        TogetherMember m = require(userId);
        if (m.status() != MemberStatus.INVITED && m.status() != MemberStatus.LEFT) {
            throw new TogetherInvalidStateException("Cannot join from " + m.status());
        }
        replace(m.with(MemberStatus.JOINED, now));
    }

    void decline(UUID userId, Instant now) {
        TogetherMember m = require(userId);
        if (m.status() != MemberStatus.INVITED) {
            throw new TogetherInvalidStateException("Cannot decline from " + m.status());
        }
        replace(m.with(MemberStatus.DECLINED, now));
    }

    /** Sale (o deja una invitación sin contestar). Idempotente: quien ya no está no cambia. */
    boolean leave(UUID userId, Instant now) {
        Optional<TogetherMember> m = find(userId);
        if (m.isEmpty() || !m.get().status().canView()) {
            return false;
        }
        replace(m.get().with(m.get().joined() ? MemberStatus.LEFT : MemberStatus.DECLINED, now));
        return true;
    }

    /**
     * Quién sale cuando {@code userId} bloquea a {@code otherUserId} o deja de ser su amigo (ADR 0044): si uno de los
     * dos es el dueño, el otro; si los dos son invitados, quien bloquea (dejar de ser amigos no obliga a salir, porque
     * los invitados no tenían que ser amigos entre sí). Vacío si no comparten nada.
     */
    public Optional<UUID> leavingWhenSeparated(UUID ownerId, UUID userId, UUID otherUserId, boolean blocked) {
        if (!canView(userId) || !canView(otherUserId)) {
            return Optional.empty();
        }
        if (ownerId.equals(userId)) {
            return Optional.of(otherUserId);
        }
        if (ownerId.equals(otherUserId)) {
            return Optional.of(userId);
        }
        return blocked ? Optional.of(userId) : Optional.empty();
    }

    public List<TogetherMember> all() {
        return List.copyOf(members);
    }

    public List<UUID> joinedIds() {
        return members.stream().filter(TogetherMember::joined).map(TogetherMember::userId).toList();
    }

    public List<UUID> invitedIds() {
        return members.stream().filter(m -> m.status() == MemberStatus.INVITED).map(TogetherMember::userId).toList();
    }

    private TogetherMember require(UUID userId) {
        return find(userId).orElseThrow(() -> new TogetherInvalidStateException("Not a member"));
    }

    private void replace(TogetherMember updated) {
        members.replaceAll(m -> m.userId().equals(updated.userId()) ? updated : m);
    }
}
