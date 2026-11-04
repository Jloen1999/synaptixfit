package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.training.CycleConsentRequiredException;
import com.synaptixfit.domain.exception.training.CycleDayOutOfRangeException;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Seguimiento del ciclo (estimación y consentimiento), causa de la fatiga y ajuste suave del entreno. */
class CycleAndWellbeingTest {

    private static final Instant NOW = Instant.parse("2026-11-04T10:00:00Z");
    private static final LocalDate TODAY = LocalDate.of(2026, 11, 4);
    private static final CycleTracking ON = new CycleTracking(true, NOW);

    private static List<CycleDay> period(LocalDate start, int days) {
        List<CycleDay> out = new ArrayList<>();
        for (int i = 0; i < days; i++) {
            out.add(new CycleDay(start.plusDays(i), true, null, Set.of(), null, NOW));
        }
        return out;
    }

    @Test
    void activarExigeConsentimientoExplicito() {
        assertThatThrownBy(() -> CycleTracking.enable(false, NOW)).isInstanceOf(CycleConsentRequiredException.class);
        assertThat(CycleTracking.enable(true, NOW)).isEqualTo(new CycleTracking(true, NOW));
    }

    @Test
    void apagadoNoEstimaNada() {
        CycleOverview o = CycleOverview.compute(CycleTracking.OFF, period(TODAY.minusDays(3), 4), TODAY);
        assertThat(o.enabled()).isFalse();
        assertThat(o.phase()).isNull();
    }

    @Test
    void estimaLaDuracionConLaMediaDeLosCiclosYElMomentoDeHoy() {
        List<CycleDay> days = new ArrayList<>();
        days.addAll(period(LocalDate.of(2026, 8, 20), 5));
        days.addAll(period(LocalDate.of(2026, 9, 19), 5));   // 30 días
        days.addAll(period(LocalDate.of(2026, 10, 19), 4));  // 30 días
        CycleOverview o = CycleOverview.compute(ON, days, TODAY);

        assertThat(o.cycleLength()).isEqualTo(30);
        assertThat(o.dayOfCycle()).isEqualTo(17);
        // Ovulación estimada en el día 16 (30 - 14): del 14 al 18 es «mitad del ciclo».
        assertThat(o.phase()).isEqualTo(CyclePhase.MID_CYCLE);
        assertThat(o.nextPeriodFrom()).isEqualTo(LocalDate.of(2026, 11, 18));
    }

    @Test
    void sinCiclosCompletosUsaVeintiochoDiasYDistingueLosMomentos() {
        List<CycleDay> days = period(TODAY.minusDays(2), 3);
        assertThat(CycleOverview.compute(ON, days, TODAY).phase()).isEqualTo(CyclePhase.PERIOD);

        CycleOverview after = CycleOverview.compute(ON, period(TODAY.minusDays(7), 5), TODAY);
        assertThat(after.cycleLength()).isEqualTo(28);
        assertThat(after.phase()).isEqualTo(CyclePhase.AFTER_PERIOD);

        CycleOverview before = CycleOverview.compute(ON, period(TODAY.minusDays(24), 5), TODAY);
        assertThat(before.phase()).isEqualTo(CyclePhase.BEFORE_PERIOD);
    }

    @Test
    void sinNadaApuntadoReciente_noSeEstima() {
        CycleOverview o = CycleOverview.compute(ON, period(TODAY.minusDays(90), 5), TODAY);
        assertThat(o.phase()).isNull();
        assertThat(o.dayOfCycle()).isNull();
    }

    @Test
    void unDiaSoloSeApuntaDelUltimoAnoYNoDelFuturo() {
        CycleDay tomorrow = new CycleDay(TODAY.plusDays(1), true, null, Set.of(), null, NOW);
        assertThatThrownBy(() -> tomorrow.requireLoggableOn(TODAY)).isInstanceOf(CycleDayOutOfRangeException.class);
        new CycleDay(TODAY.minusDays(365), false, null, null, " ", NOW).requireLoggableOn(TODAY);
    }

    @Test
    void laCausaDeLaFatigaEsLoQueMasPesa() {
        DailyCheckIn badSleep = DailyCheckIn.create(UUID.randomUUID(), TODAY,
                new DailyCheckIn.Values(1, null, 3, 2, List.of(), true, null), NOW);
        assertThat(badSleep.stress()).isEqualTo(DailyCheckIn.NEUTRAL_STRESS);
        assertThat(badSleep.mainCause()).isEqualTo(FatigueCause.POOR_SLEEP);

        DailyCheckIn sore = DailyCheckIn.create(UUID.randomUUID(), TODAY,
                new DailyCheckIn.Values(4, 2, 4, 5, List.of(), true, null), NOW);
        assertThat(sore.mainCause()).isEqualTo(FatigueCause.SORENESS);
    }

    @Test
    void elRegistroRapidoConservaElEstresQueYaHabia() {
        DailyCheckIn c = DailyCheckIn.create(UUID.randomUUID(), TODAY,
                new DailyCheckIn.Values(3, 5, 3, 3, List.of(), true, null), NOW);
        c.apply(new DailyCheckIn.Values(4, null, 4, 2, List.of(), true, null));
        assertThat(c.stress()).isEqualTo(5);
    }

    @Test
    void elCicloPideUnAjusteSuaveSoloConMolestiasOEnergiaBaja() {
        CycleDay cramps = new CycleDay(TODAY, true, CycleEnergy.NORMAL, Set.of(CycleSymptom.CRAMPS), null, NOW);
        SessionAdaptation a = SessionAdaptation.of(1.0, false, null, cramps);
        assertThat(a.reasons()).containsExactly(SessionAdaptation.Reason.CYCLE_DISCOMFORT);
        assertThat(a.volumeFactor()).isEqualTo(SessionAdaptation.CYCLE_FACTOR);
        assertThat(a.fatigueCause()).isNull();

        CycleDay fine = new CycleDay(TODAY, true, CycleEnergy.HIGH, Set.of(), null, NOW);
        assertThat(SessionAdaptation.of(1.0, false, null, fine).adapted()).isFalse();
    }

    @Test
    void conFatigaAltaSeExplicaLaCausaYGanaElMasRestrictivo() {
        DailyCheckIn tired = DailyCheckIn.create(UUID.randomUUID(), TODAY,
                new DailyCheckIn.Values(1, 4, 1, 4, List.of(), true, null), NOW);
        CycleDay low = new CycleDay(TODAY, false, CycleEnergy.LOW, Set.of(), null, NOW);
        SessionAdaptation a = SessionAdaptation.of(1.0, false, tired, low);
        assertThat(a.reasons()).containsExactly(SessionAdaptation.Reason.HIGH_FATIGUE,
                SessionAdaptation.Reason.CYCLE_DISCOMFORT);
        assertThat(a.volumeFactor()).isEqualTo(SessionAdaptation.HIGH_FATIGUE_FACTOR);
        assertThat(a.fatigueCause()).isEqualTo(FatigueCause.POOR_SLEEP);
    }
}
