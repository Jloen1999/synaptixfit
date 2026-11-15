package com.synaptixfit.application.port.input.together;

import com.synaptixfit.domain.model.challenge.RuleMetric;
import com.synaptixfit.domain.model.challenge.RuleUnit;
import com.synaptixfit.domain.model.together.FriendChallengeMode;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.Person;
import com.synaptixfit.domain.model.together.Reaction;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Un reto con amigos tal como lo ve una persona (ADR 0044). En modo juntos solo se ve el total del grupo y quién ha
 * aportado; los puntos de cada uno solo en competición. En el tablón, cuántas reacciones tiene una entrada solo lo ve
 * quien la publicó; los demás ven la suya.
 *
 * @param groupTotal  suma de los puntos de quienes están dentro (con el tope diario)
 * @param groupTarget meta común (la de cada persona por las que están dentro)
 * @param myPoints    lo que he sumado yo
 * @param myTarget    mi meta personal (la de la plantilla en proporción a los días)
 * @param board       vacío en los listados y para quien aún no ha aceptado
 */
public record FriendChallengeView(UUID id, String title, String goal, RuleMetric metric, RuleUnit unit,
                                  FriendChallengeMode mode, Instant startAt, Instant endAt, int days,
                                  MemberStatus myStatus, Person creator, int groupTotal, int groupTarget,
                                  int myPoints, int myTarget, boolean over, List<Member> members,
                                  List<BoardEntry> board) {

    /**
     * @param points solo en competición; nulo en modo juntos
     * @param me     es quien mira
     */
    public record Member(Person person, MemberStatus status, boolean contributed, Integer points, boolean me) {
    }

    /** @param counts reacciones por tipo, solo en las entradas propias (vacío en las de los demás) */
    public record BoardEntry(Person person, LocalDate day, boolean mine, Map<Reaction, Integer> counts,
                             Reaction myReaction) {
    }
}
