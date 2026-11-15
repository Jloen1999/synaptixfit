package com.synaptixfit.domain.model.together;

import com.synaptixfit.domain.model.challenge.ActivityFact;
import com.synaptixfit.domain.model.challenge.ChallengeRule;
import com.synaptixfit.domain.model.challenge.RuleMetric;
import com.synaptixfit.domain.model.challenge.RuleUnit;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;

/**
 * Cuánto suma una persona en un reto con amigos (ADR 0044), con la misma regla que un reto propio
 * ({@link ChallengeRule#count}) pero sin el tope de la meta y con un tope diario: en un reto «por suma» (minutos,
 * carreras) cada día cuenta como mucho {@code dailyCap}; en uno por días o semanas el tope ya es natural (un día o
 * una semana cumplidos).
 */
public final class FriendChallengeScore {

    private FriendChallengeScore() {
    }

    /** Puntos de una persona entre {@code start} y {@code end}. */
    public static int points(ChallengeRule rule, List<ActivityFact> facts, Instant start, Instant end, ZoneId zone,
                             int dailyCap) {
        ChallengeRule open = new ChallengeRule(rule.metric(), rule.unit(), rule.perUnit(), ChallengeRule.MAX_TARGET,
                rule.weekdaysOnly());
        List<ActivityFact> counted = rule.unit() == RuleUnit.TOTAL ? capped(rule, facts, zone, dailyCap) : facts;
        return open.count(counted, start, end, zone);
    }

    /**
     * Días en que la persona sumó algo (para el tablón): los que por sí solos ya cuentan con la regla del reto como
     * si fuera diaria y con mínimo 1. Del más reciente al más antiguo.
     */
    public static List<LocalDate> contributionDays(ChallengeRule rule, List<ActivityFact> facts, Instant start,
                                                   Instant end, ZoneId zone) {
        ChallengeRule daily = new ChallengeRule(rule.metric(), RuleUnit.DAY, 1, ChallengeRule.MAX_TARGET,
                rule.weekdaysOnly());
        Map<LocalDate, List<ActivityFact>> byDay = facts.stream()
                .filter(f -> rule.metric().sources().contains(f.kind()))
                .collect(Collectors.groupingBy(f -> f.dayIn(zone)));
        Set<LocalDate> days = new TreeSet<>(Comparator.reverseOrder());
        byDay.forEach((day, dayFacts) -> {
            if (daily.count(dayFacts, start, end, zone) > 0) {
                days.add(day);
            }
        });
        return List.copyOf(days);
    }

    /** Recorta lo de cada día al tope: minutos de Pomodoro hasta {@code cap}; el resto, {@code cap} cosas. */
    private static List<ActivityFact> capped(ChallengeRule rule, List<ActivityFact> facts, ZoneId zone, int cap) {
        List<ActivityFact> sorted = new ArrayList<>(facts.stream()
                .filter(f -> rule.metric().sources().contains(f.kind())).toList());
        sorted.sort(Comparator.comparing((ActivityFact f) -> f.dayIn(zone))
                .thenComparing(f -> f.at() == null ? Instant.EPOCH : f.at()));
        Map<LocalDate, Integer> used = new HashMap<>();
        List<ActivityFact> result = new ArrayList<>();
        boolean minutes = rule.metric() == RuleMetric.FOCUS_MINUTES;
        for (ActivityFact f : sorted) {
            LocalDate day = f.dayIn(zone);
            int already = used.getOrDefault(day, 0);
            int room = cap - already;
            if (room <= 0) {
                continue;
            }
            int take = minutes ? Math.min(f.amount(), room) : 1;
            used.put(day, already + take);
            result.add(minutes ? new ActivityFact(f.kind(), f.at(), f.day(), take) : f);
        }
        return result;
    }
}
