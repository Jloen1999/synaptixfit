package com.synaptixfit.domain.model.dashboard;

import com.synaptixfit.domain.model.dashboard.DashboardReadModels.CalendarBlock;
import com.synaptixfit.domain.model.planner.ActivityType;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Reglas deterministas del banner inteligente. Conserva el orden de la app antigua (señales
 * académicas, energía, refuerzo por constancia, check-in) y añade las señales de los indicadores:
 * sobrecarga física (ACWR), fatiga de los últimos días y vuelta tras inactividad (de la antigua
 * {@code generar_recomendaciones_diarias}) y capacidad atencional agotada.
 *
 * <p>Con un solo enfoque (solo estudios o solo deporte) se saltan los avisos del otro ámbito: el
 * check-in, la fatiga, la carga física y las rachas de entreno son de deporte; entregas, adherencia
 * al plan, atención y racha de estudio, de estudios.
 *
 * <p>Corrección: la app antigua comparaba la "racha de estudio" (una fracción 0-1) con 5, así que
 * ese mensaje nunca salía; ahora es un número de días.
 */
public final class SmartBannerRules {

    static final double LOW_ADHERENCE = 40;
    static final double LOW_ENERGY = 30;
    static final double HIGH_ENERGY = 70;
    static final int LOW_STRESS = 5;
    static final int HIGH_FATIGUE = 50;
    static final double LOW_ATTENTION = 0.4;
    static final int STREAK_DAYS = 5;
    static final int COMEBACK_MIN_DAYS = 7;
    static final int COMEBACK_MAX_DAYS = 30;
    static final double COMEBACK_LOAD_FACTOR = 0.8;

    private SmartBannerRules() {
    }

    public static SmartBanner choose(BannerContext c) {
        boolean academic = c.focus().includesAcademic();
        boolean fitness = c.focus().includesFitness();
        if (fitness && c.zone().isRisky()) {
            return banner(SmartBanner.Type.PHYSICAL_OVERLOAD, "acwr", round2(c.acwr()), "maxStudyMinutes", c.maxStudyMinutes());
        }
        // Lo vencido va antes que lo que viene: aún se puede entregar o hablar con el profesor.
        if (academic && c.overdueDeadlines() > 0) {
            return banner(SmartBanner.Type.OVERDUE_DEADLINES, "count", c.overdueDeadlines());
        }
        if (academic && c.upcomingDeadlines() > 0) {
            return banner(SmartBanner.Type.UPCOMING_DEADLINES, "count", c.upcomingDeadlines(),
                    "daysUntilNext", c.daysUntilNextDeadline() == null ? 0 : c.daysUntilNextDeadline());
        }
        // La fatiga alta va antes que lo no hecho: con el cuerpo al límite no toca recuperar bloques.
        if (fitness && c.recentFatigueScore() != null && c.recentFatigueScore() > HIGH_FATIGUE) {
            return banner(SmartBanner.Type.HIGH_FATIGUE, "fatigueScore", c.recentFatigueScore());
        }
        if (c.missedBlocks() > 0) {
            return banner(SmartBanner.Type.MISSED_BLOCKS, "count", c.missedBlocks());
        }
        if (academic && c.adherence() != null && c.adherence() < LOW_ADHERENCE) {
            return banner(SmartBanner.Type.LOW_ADHERENCE, "adherence", Math.round(c.adherence()));
        }
        if (fitness && c.checkInDone() && c.energy() != null && c.energy() < LOW_ENERGY) {
            return banner(SmartBanner.Type.LOW_ENERGY, "energy", Math.round(c.energy()));
        }
        if (academic && c.attentionCapacity() < LOW_ATTENTION) {
            return banner(SmartBanner.Type.ATTENTION_DEPLETED, "attentionCapacity", round2(c.attentionCapacity()),
                    "cognitiveLoad", round2(c.cognitiveLoad()));
        }
        int stress = c.weeklyStress() == null ? LOW_STRESS : c.weeklyStress();
        if (fitness && c.checkInDone() && c.energy() != null && c.energy() > HIGH_ENERGY && stress < LOW_STRESS) {
            return banner(SmartBanner.Type.PEAK_DAY, "energy", Math.round(c.energy()), "stress", stress);
        }
        if (academic && c.studyStreakDays() >= STREAK_DAYS) {
            return banner(SmartBanner.Type.STUDY_STREAK, "days", c.studyStreakDays());
        }
        if (fitness && c.trainingStreak() >= STREAK_DAYS) {
            return banner(SmartBanner.Type.TRAINING_STREAK, "days", c.trainingStreak());
        }
        Integer inactive = c.daysSinceLastSession();
        if (fitness && inactive != null && inactive >= COMEBACK_MIN_DAYS && inactive <= COMEBACK_MAX_DAYS) {
            return banner(SmartBanner.Type.COMEBACK, "daysInactive", inactive, "loadFactor", COMEBACK_LOAD_FACTOR);
        }
        if (fitness && !c.checkInDone()) {
            return banner(SmartBanner.Type.CHECK_IN_PENDING);
        }
        return banner(SmartBanner.Type.BALANCE);
    }

    /**
     * Concreta el aviso de bloques sin hacer con el más reciente: así se sabe de un vistazo cuál es
     * («Álgebra, hoy a las 16:00») sin abrir el calendario.
     */
    public static SmartBanner describeLatestMissed(SmartBanner banner, List<CalendarBlock> missed, LocalDate today,
                                                   ZoneId zone) {
        return missed.stream().max(Comparator.comparing(CalendarBlock::start)).map(latest -> {
            var local = latest.start().atZone(zone);
            String title = latest.subjectName() != null && !latest.subjectName().isBlank()
                    ? latest.subjectName()
                    : latest.topics();
            Map<String, String> labels = new LinkedHashMap<>();
            if (title != null && !title.isBlank()) {
                labels.put("title", title.strip());
            }
            labels.put("activity", ActivityType.fromCode(latest.activityType()).name());
            // Para que el aviso actúe sobre ese bloque («Hecho», «Al próximo hueco») sin abrir el calendario.
            labels.put("blockId", latest.id().toString());
            return banner.with(Map.of("startMinutes", local.getHour() * 60 + local.getMinute(),
                    "yesterday", local.toLocalDate().isBefore(today) ? 1 : 0), labels);
        }).orElse(banner);
    }

    private static SmartBanner banner(SmartBanner.Type type, Object... kv) {
        Map<String, Number> params = new LinkedHashMap<>();
        for (int i = 0; i < kv.length; i += 2) {
            params.put((String) kv[i], (Number) kv[i + 1]);
        }
        return new SmartBanner(type, params);
    }

    private static double round2(Double v) {
        return v == null ? 0 : Math.round(v * 100) / 100.0;
    }
}
