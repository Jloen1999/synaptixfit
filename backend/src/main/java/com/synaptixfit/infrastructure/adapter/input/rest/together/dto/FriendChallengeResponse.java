package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.application.port.input.together.FriendChallengeView;
import com.synaptixfit.domain.model.challenge.RuleMetric;
import com.synaptixfit.domain.model.challenge.RuleUnit;
import com.synaptixfit.domain.model.together.FriendChallengeMode;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.Reaction;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Reto con amigos (ADR 0044). {@code members[].points} solo en competición; {@code board[].counts} solo en las
 * entradas propias. {@code board} va vacío en el listado y para quien aún no ha aceptado.
 */
public record FriendChallengeResponse(UUID id, String title, String goal, RuleMetric metric, RuleUnit unit,
                                      FriendChallengeMode mode, Instant startAt, Instant endAt, int days,
                                      MemberStatus myStatus, PersonResponse creator, int groupTotal, int groupTarget,
                                      int myPoints, int myTarget, boolean over, List<FriendChallengeMember> members,
                                      List<FriendChallengeBoardEntry> board) {

    public record FriendChallengeMember(PersonResponse person, MemberStatus status, boolean contributed,
                                        Integer points,
                         boolean me) {
    }

    public record FriendChallengeBoardEntry(PersonResponse person, LocalDate day, boolean mine,
                                            Map<Reaction, Integer> counts,
                             Reaction myReaction) {
    }

    public static FriendChallengeResponse from(FriendChallengeView v) {
        return new FriendChallengeResponse(v.id(), v.title(), v.goal(), v.metric(), v.unit(), v.mode(), v.startAt(),
                v.endAt(), v.days(), v.myStatus(), PersonResponse.from(v.creator()), v.groupTotal(), v.groupTarget(),
                v.myPoints(), v.myTarget(), v.over(),
                v.members().stream().map(m -> new FriendChallengeMember(PersonResponse.from(m.person()), m.status(),
                        m.contributed(),
                        m.points(), m.me())).toList(),
                v.board().stream().map(b -> new FriendChallengeBoardEntry(PersonResponse.from(b.person()), b.day(),
                        b.mine(),
                        b.counts(), b.myReaction())).toList());
    }
}
