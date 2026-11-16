package com.synaptixfit.domain.model.challenge;

import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;

/**
 * Plantilla de reto productivo (ADR 0043): título y meta en el idioma pedido, ámbito, dificultad, cuántos días dura y
 * la regla con la que el servidor lo cuenta solo. «Empezar este reto» crea un reto normal y privado a partir de ella.
 * Una plantilla retirada ({@code active} falso, ADR 0054) ya no se ofrece ni se empieza, pero se sigue leyendo para
 * los retos en curso que salieron de ella.
 */
public record ChallengeTemplate(UUID id, String code, ChallengeType type, Difficulty difficulty, int days,
                                ChallengeRule rule, String title, String goal, boolean active) {

    public static final int MAX_DAYS = 90;

    public ChallengeTemplate(UUID id, String code, ChallengeType type, Difficulty difficulty, int days,
                             ChallengeRule rule, String title, String goal) {
        this(id, code, type, difficulty, days, rule, title, goal, true);
    }

    public ChallengeTemplate {
        Guard.notNull(id, "id");
        Guard.notNull(code, "code");
        Guard.notNull(type, "type");
        Guard.notNull(difficulty, "difficulty");
        Guard.range(days, "days", 1, MAX_DAYS);
        Guard.notNull(rule, "rule");
    }

    /** Se ofrece si no está retirada y su ámbito y todo lo que cuenta están en el modo de uso de la persona. */
    public boolean availableFor(UsageFocus focus) {
        return active && type.allowedFor(focus) && rule.availableFor(focus);
    }

    /**
     * Datos del reto que crea: empieza ahora y termina al final del día {@code days} (hoy cuenta como el primero),
     * en la zona de la persona. Siempre privado: compartirlo es decisión de quien lo hace.
     */
    public ChallengeDetails detailsFrom(Instant now, ZoneId zone) {
        LocalDate lastDay = LocalDate.ofInstant(now, zone).plusDays(days - 1L);
        Instant end = lastDay.plusDays(1).atStartOfDay(zone).toInstant().minusSeconds(1);
        return new ChallengeDetails(title, type, goal, Visibility.PRIVATE, difficulty, now, end, null, null);
    }
}
