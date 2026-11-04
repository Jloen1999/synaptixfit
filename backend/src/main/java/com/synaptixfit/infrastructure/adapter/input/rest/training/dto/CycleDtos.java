package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.domain.model.training.CycleDay;
import com.synaptixfit.domain.model.training.CycleEnergy;
import com.synaptixfit.domain.model.training.CycleOverview;
import com.synaptixfit.domain.model.training.CyclePhase;
import com.synaptixfit.domain.model.training.CycleSymptom;
import com.synaptixfit.domain.model.training.FatigueCause;
import com.synaptixfit.domain.model.training.SessionAdaptation;
import com.synaptixfit.application.port.input.training.GetTodayAdaptationUseCase;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;

/** DTOs del seguimiento del ciclo (opcional, ADR 0033) y de la adaptación de hoy. */
public final class CycleDtos {

    private CycleDtos() {
    }

    /**
     * Activar o desactivar. Activar exige {@code consent: true}; al desactivar, {@code deleteHistory: true} borra
     * todo lo apuntado.
     */
    public record CycleSettingsRequest(@NotNull Boolean enabled, Boolean consent, Boolean deleteHistory) {
    }

    /** Lo apuntado un día: regla, energía (opcional), molestias y nota (opcional, 300 caracteres). */
    public record CycleDayRequest(@NotNull Boolean period, CycleEnergy energy, @Size(max = 5) Set<CycleSymptom> symptoms,
                                  @Size(max = 300) String note) {
    }

    public record CycleDayResponse(LocalDate date, boolean period, CycleEnergy energy, Set<CycleSymptom> symptoms,
                                   String note) {
        public static CycleDayResponse from(CycleDay d) {
            return new CycleDayResponse(d.date(), d.period(), d.energy(), d.symptoms(), d.note());
        }
    }

    /**
     * Resumen. Sin activar, solo {@code enabled: false}. Activo: momento estimado ({@code phase}, nulo si aún no se
     * puede estimar), día del ciclo, duración media, desde cuándo se espera la próxima regla y lo apuntado hoy.
     */
    public record CycleOverviewResponse(boolean enabled, Instant consentedAt, CyclePhase phase, Integer dayOfCycle,
                                        int cycleLength, LocalDate nextPeriodFrom, CycleDayResponse today) {
        public static CycleOverviewResponse from(CycleOverview o) {
            return new CycleOverviewResponse(o.enabled(), o.consentedAt(), o.phase(), o.dayOfCycle(), o.cycleLength(),
                    o.nextPeriodFrom(), o.today() == null ? null : CycleDayResponse.from(o.today()));
        }
    }

    /** Días apuntados del rango pedido, para pintar el calendario del mes. */
    public record CycleDaysResponse(List<CycleDayResponse> days) {
    }

    /**
     * Cómo se adapta hoy el entreno sin empezar sesión: factor de series, motivos, lo que más pesa en la fatiga (si
     * es un motivo) y si ya hay registro diario hoy.
     */
    public record TodayAdaptationResponse(double volumeFactor, List<SessionAdaptation.Reason> reasons,
                                          FatigueCause fatigueCause, boolean checkInDone) {
        public static TodayAdaptationResponse from(GetTodayAdaptationUseCase.Result r) {
            return new TodayAdaptationResponse(r.adaptation().volumeFactor(), r.adaptation().reasons(),
                    r.adaptation().fatigueCause(), r.checkInDone());
        }
    }
}
