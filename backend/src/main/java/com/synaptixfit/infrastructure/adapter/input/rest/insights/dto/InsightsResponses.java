package com.synaptixfit.infrastructure.adapter.input.rest.insights.dto;

import com.synaptixfit.domain.model.insights.AcademicAdherence;
import com.synaptixfit.domain.model.insights.AcwrZone;
import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.insights.EnergyScore;
import com.synaptixfit.domain.model.insights.PhysicalLoadSummary;
import com.synaptixfit.domain.model.insights.StudyCaloriesSummary;
import com.synaptixfit.domain.model.insights.TotalLoadFactor;
import com.synaptixfit.domain.model.insights.WeeklyAcademicLoad;
import com.synaptixfit.domain.model.insights.WellbeingSnapshot;
import com.synaptixfit.domain.model.neuro.CrossRegulation;
import com.synaptixfit.domain.model.planner.FocusPlan;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/** DTOs de respuesta de los indicadores neurofisiológicos. Los decimales se redondean para la UI. */
public final class InsightsResponses {

    private InsightsResponses() {
    }

    public static double round(double v, int decimals) {
        double factor = Math.pow(10, decimals);
        return Math.round(v * factor) / factor;
    }

    public static Double round(Double v, int decimals) {
        return v == null ? null : round(v.doubleValue(), decimals);
    }

    /** Regulación cruzada: ACWR, zona, T_max de estudio y factor de volumen de entrenamiento. */
    public record CrossRegulationResponse(Double acwr, AcwrZone zone, double acuteDailyLoad, double chronicDailyLoad,
                                          int maxStudyMinutes, int baseStudyMinutes, Integer daysUntilExam,
                                          double academicLoad, double recommendedVolumeFactor, Instant updatedAt,
                                          int focusMinutes, int focusBreakMinutes) {

        /** {@code focusMinutes}/{@code focusBreakMinutes}: el bloque y la pausa del Pomodoro de hoy ({@link FocusPlan}). */
        public static CrossRegulationResponse from(CrossRegulationView v) {
            FocusPlan plan = FocusPlan.of(v);
            return new CrossRegulationResponse(round(v.acwr(), 2), v.zone(), round(v.state().acuteDailyLoad(), 2),
                    round(v.state().chronicDailyLoad(), 2), v.state().maxStudyMinutes(),
                    CrossRegulation.DEFAULT_STUDY_MINUTES, v.state().daysUntilExam(), round(v.academicLoad(), 3),
                    round(v.recommendedVolumeFactor(), 3), v.state().updatedAt(), plan.focusMinutes(),
                    plan.shortBreakMinutes());
        }
    }

    public record DailyLoadResponse(LocalDate date, double load) {
    }

    /** Carga física de hoy (AU = RPE x minutos), máxima diaria histórica y serie de 28 días. */
    public record PhysicalLoadResponse(LocalDate date, double todayLoad, double maxDailyLoad, double todayRatio,
                                       List<DailyLoadResponse> last28Days) {

        public static PhysicalLoadResponse from(PhysicalLoadSummary s) {
            return new PhysicalLoadResponse(s.date(), round(s.todayLoad(), 2), round(s.maxDailyLoad(), 2),
                    round(s.todayRatio(), 3),
                    s.last28Days().stream().map(d -> new DailyLoadResponse(d.date(), round(d.load(), 2))).toList());
        }
    }

    /** Estado cognitivo: carga 0-1, capacidad atencional 0-1, último bloque y último descanso. */
    public record CognitiveStateResponse(double cognitiveLoad, double attentionCapacity, int lastBlockMinutes,
                                         Instant lastRestAt, Double restingMetabolicRate, Instant updatedAt) {

        public static CognitiveStateResponse from(CognitiveState s) {
            return new CognitiveStateResponse(round(s.cognitiveLoad(), 4), round(s.attentionCapacity(), 3),
                    s.lastBlockMinutes(), s.lastRestAt(), round(s.rmrBase(), 2), s.updatedAt());
        }
    }

    /** Calorías de los bloques académicos completados hoy. */
    public record StudyCaloriesResponse(LocalDate date, double totalCalories, int completedBlocks, int studyMinutes) {

        public static StudyCaloriesResponse from(StudyCaloriesSummary s) {
            return new StudyCaloriesResponse(s.date(), round(s.totalCalories(), 1), s.completedBlocks(), s.studyMinutes());
        }
    }

    public record EnergyResponse(double score, double base, double dailyEnergy, double sleep, double recovery,
                                 double cognitive, double stress, double sleepGate, double sorenessGate,
                                 double energyGate) {

        static EnergyResponse from(EnergyScore e) {
            return e == null ? null : new EnergyResponse(round(e.score(), 1), round(e.base(), 1),
                    round(e.dailyEnergy(), 1), round(e.sleep(), 1), round(e.recovery(), 1), round(e.cognitive(), 1),
                    round(e.stress(), 1), e.sleepGate(), e.sorenessGate(), e.energyGate());
        }
    }

    public record AdherenceResponse(double score, double hoursCompliance, double taskCompletion, int studyDays) {

        static AdherenceResponse from(AcademicAdherence a) {
            return a == null ? null : new AdherenceResponse(round(a.score(), 1), round(a.hoursCompliance(), 3),
                    round(a.taskCompletion(), 3), a.studyDays());
        }
    }

    public record TotalLoadResponse(double value, double percent, TotalLoadFactor.LoadLevel level) {

        static TotalLoadResponse from(TotalLoadFactor t) {
            return t == null ? null : new TotalLoadResponse(round(t.value(), 3), round(t.percent(), 1), t.level());
        }
    }

    @Schema(name = "InsightsWeeklyLoadResponse")

    public record WeeklyLoadResponse(LocalDate weekStart, int plannedStudyHours, int realStudyHours, int evaluations,
                                     int deliveries, int stressLevel, double avgSleepHours) {

        static WeeklyLoadResponse from(WeeklyAcademicLoad w) {
            return w == null ? null : new WeeklyLoadResponse(w.weekStart(), w.plannedStudyHours(), w.realStudyHours(),
                    w.evaluations(), w.deliveries(), w.stressLevel(), w.avgSleepHours());
        }
    }

    /** Bienestar de hoy. Cada bloque es null si faltan sus datos (check-in o carga académica semanal). */
    public record WellbeingResponse(LocalDate date, boolean checkInDone, Integer fatigueScore, EnergyResponse energy,
                                    AdherenceResponse adherence, TotalLoadResponse totalLoad,
                                    WeeklyLoadResponse weeklyLoad) {

        public static WellbeingResponse from(WellbeingSnapshot w) {
            return new WellbeingResponse(w.date(), w.checkInDone(),
                    w.checkIn() == null ? null : w.checkIn().fatigueScore(), EnergyResponse.from(w.energy()),
                    AdherenceResponse.from(w.adherence()), TotalLoadResponse.from(w.totalLoad()),
                    WeeklyLoadResponse.from(w.weeklyLoad()));
        }
    }
}
