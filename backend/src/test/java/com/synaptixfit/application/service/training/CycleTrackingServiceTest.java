package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.training.LogCycleDayUseCase;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.training.CycleConsentRequiredException;
import com.synaptixfit.domain.exception.training.CycleTrackingOffException;
import com.synaptixfit.domain.model.training.CycleDay;
import com.synaptixfit.domain.model.training.CycleEnergy;
import com.synaptixfit.domain.model.training.CycleOverview;
import com.synaptixfit.domain.model.training.CycleSymptom;
import com.synaptixfit.domain.model.training.CycleTracking;
import com.synaptixfit.domain.port.output.training.CycleRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.TreeMap;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Activar con consentimiento, apuntar solo con el seguimiento activo y borrar al desactivar si se pide. */
class CycleTrackingServiceTest {

    private static final Instant NOW = Instant.parse("2026-11-04T10:00:00Z");
    private static final LocalDate TODAY = LocalDate.of(2026, 11, 4);
    private final UUID user = UUID.randomUUID();
    private final FakeCycles cycles = new FakeCycles();
    private final CycleTrackingService service = new CycleTrackingService(cycles,
            Clock.fixed(NOW, ZoneOffset.UTC), ZoneId.of("Europe/Madrid"));

    @Test
    void sinConsentimientoNoSeActivaYSinActivarNoSeApunta() {
        assertThatThrownBy(() -> service.change(user, true, false, false))
                .isInstanceOf(CycleConsentRequiredException.class);
        assertThatThrownBy(() -> service.log(command(TODAY)))
                .isInstanceOf(CycleTrackingOffException.class);
        assertThat(service.overview(user).enabled()).isFalse();
    }

    @Test
    void apuntarHoyDevuelveElResumenConLoDeHoy() {
        CycleOverview on = service.change(user, true, true, false);
        assertThat(on.enabled()).isTrue();
        assertThat(on.consentedAt()).isEqualTo(NOW);

        CycleOverview o = service.log(command(TODAY));
        assertThat(o.today().period()).isTrue();
        assertThat(o.today().symptoms()).containsExactly(CycleSymptom.CRAMPS);
        assertThat(service.list(user, TODAY.minusDays(30), TODAY)).hasSize(1);
    }

    @Test
    void desactivarPuedeBorrarTodoLoApuntado() {
        service.change(user, true, true, false);
        service.log(command(TODAY));
        service.change(user, false, false, false);
        assertThat(cycles.days.get(user)).hasSize(1);

        service.change(user, true, true, false);
        service.change(user, false, false, true);
        assertThat(cycles.days.getOrDefault(user, new TreeMap<>())).isEmpty();
    }

    @Test
    void elCalendarioPideComoMuchoUnMesYAlgo() {
        assertThatThrownBy(() -> service.list(user, TODAY.minusDays(200), TODAY))
                .isInstanceOf(FieldValidationException.class);
    }

    private LogCycleDayUseCase.Command command(LocalDate date) {
        return new LogCycleDayUseCase.Command(user, date, true, CycleEnergy.LOW, Set.of(CycleSymptom.CRAMPS), null);
    }

    /** Doble en memoria del puerto del ciclo. */
    static final class FakeCycles implements CycleRepositoryPort {
        final Map<UUID, CycleTracking> tracking = new HashMap<>();
        final Map<UUID, TreeMap<LocalDate, CycleDay>> days = new HashMap<>();

        @Override
        public Optional<CycleTracking> findTracking(UUID userId) {
            return Optional.ofNullable(tracking.get(userId));
        }

        @Override
        public void saveTracking(UUID userId, CycleTracking t, Instant now) {
            tracking.put(userId, t);
        }

        @Override
        public List<CycleDay> findDays(UUID userId, LocalDate from, LocalDate to) {
            return List.copyOf(days.getOrDefault(userId, new TreeMap<>()).subMap(from, true, to, true).values());
        }

        @Override
        public Optional<CycleDay> findDay(UUID userId, LocalDate date) {
            return Optional.ofNullable(days.getOrDefault(userId, new TreeMap<>()).get(date));
        }

        @Override
        public void saveDay(UUID userId, CycleDay day) {
            days.computeIfAbsent(userId, k -> new TreeMap<>()).put(day.date(), day);
        }

        @Override
        public void deleteDay(UUID userId, LocalDate date) {
            days.getOrDefault(userId, new TreeMap<>()).remove(date);
        }

        @Override
        public void deleteAllDays(UUID userId) {
            days.remove(userId);
        }
    }
}
