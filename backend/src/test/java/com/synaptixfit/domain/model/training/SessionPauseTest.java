package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.training.SessionAlreadyCompletedException;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Pausas de la sesión y cronómetro por serie (ADR 0030): escenarios reales de un entreno. */
class SessionPauseTest {

    private static final Instant START = Instant.parse("2026-11-02T18:00:00Z");
    private static final UUID USER = UUID.randomUUID();

    private static TrainingSession session() {
        return TrainingSession.start(USER, null, null, START);
    }

    private static Instant at(int minutes) {
        return START.plus(Duration.ofMinutes(minutes));
    }

    @Test
    void unaLlamadaEnMitadDelEntrenoNoCuentaComoTiempoEntrenado() {
        TrainingSession s = session();
        s.pause(at(20));
        s.resume(at(35));

        assertThat(s.activeSeconds(at(50))).isEqualTo(Duration.ofMinutes(35).toSeconds());
        assertThat(s.pausedSeconds()).isEqualTo(Duration.ofMinutes(15).toSeconds());
        // El cliente pide 50 min, pero solo se entrenaron 35.
        assertThat(s.boundedDurationSeconds(Duration.ofMinutes(50).toSeconds(), at(50)))
                .isEqualTo(Duration.ofMinutes(35).toSeconds());
    }

    @Test
    void laPausaEnCursoTambienSeDescuentaYUnDobleToqueNoFalla() {
        TrainingSession s = session();
        s.pause(at(10));
        s.pause(at(12));
        assertThat(s.isPaused()).isTrue();
        assertThat(s.activeSeconds(at(30))).isEqualTo(Duration.ofMinutes(10).toSeconds());

        s.resume(at(30));
        s.resume(at(31));
        assertThat(s.isPaused()).isFalse();
        assertThat(s.pausedSeconds()).isEqualTo(Duration.ofMinutes(20).toSeconds());
    }

    @Test
    void terminarEnPausaCierraLaPausaYGuardaElTiempoActivo() {
        TrainingSession s = session();
        s.pause(at(40));
        long duration = s.boundedDurationSeconds(Duration.ofMinutes(60).toSeconds(), at(60));
        s.complete(duration, 7, 200, 30, at(60));

        assertThat(s.durationMinutes()).isEqualTo(40);
        assertThat(s.isPaused()).isFalse();
        assertThat(s.pausedSeconds()).isEqualTo(Duration.ofMinutes(20).toSeconds());
        assertThatThrownBy(() -> s.pause(at(61))).isInstanceOf(SessionAlreadyCompletedException.class);
    }

    @Test
    void seMarcaUnaSerieSinHaberUsadoElCronometroYConElCronometro() {
        TrainingSession s = session();
        UUID planned = UUID.randomUUID();
        // «Olvidé empezar el cronómetro»: se guarda igual, sin tiempo.
        SessionSet forgot = s.recordSet(planned, null, 1, 10, 40.0, true, 0, null, null, null);
        // Con el cronómetro de la serie: 48 s.
        SessionSet timed = s.recordSet(planned, null, 2, 10, 40.0, true, 0, null, null, 48);

        assertThat(forgot.activeSeconds()).isNull();
        assertThat(timed.activeSeconds()).isEqualTo(48);
        assertThat(s.sets()).hasSize(2);
    }

    @Test
    void enPausaSePuedeSeguirApuntandoUnaSerieExtraOEnOtroOrden() {
        TrainingSession s = session();
        s.pause(at(5));
        UUID other = UUID.randomUUID();
        // Máquina ocupada: se apunta antes la serie 3 de otro ejercicio y una serie extra.
        s.recordSet(other, null, 3, 12, 20.0, true, 0, null, null, 30);
        s.recordSet(other, null, 4, 8, 20.0, true, 0, null, null, null);
        assertThat(s.sets()).hasSize(2);
        assertThat(s.isPaused()).isTrue();
    }

    @Test
    void elCronometroDeUnaSerieNoAdmiteValoresImposibles() {
        TrainingSession s = session();
        assertThatThrownBy(() -> s.recordSet(UUID.randomUUID(), null, 1, 10, 40.0, true, 0, null, null, -1))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void unaSesionAbandonadaSeFechaConSusPausasCerradasPeroNuncaDespuesDeAhora() {
        TrainingSession s = session();
        s.pause(at(30));
        s.resume(at(45));
        Instant later = at(60 * 8);
        long duration = s.boundedDurationSeconds(Duration.ofMinutes(40).toSeconds(), later);

        assertThat(s.isStale(later)).isTrue();
        assertThat(s.completionInstant(duration, later)).isEqualTo(at(40 + 15));
    }

    @Test
    void desmarcarUnaSesionNoLaDejaEnPausa() {
        TrainingSession s = session();
        s.complete(600, 6, 80, 10, at(10));
        s.unmark(java.time.LocalDate.of(2026, 11, 2), java.time.ZoneOffset.UTC);
        assertThat(s.isPaused()).isFalse();
    }

    @Test
    void reanudarSinConexionSeCuentaDesdeElToqueAunqueElAvisoLlegueTarde() {
        TrainingSession s = session();
        s.pause(at(10));
        // Se reanudó en el minuto 15 sin conexión; el móvil lo avisa en el 55.
        s.resume(at(15), at(55));

        assertThat(s.pausedSeconds()).isEqualTo(Duration.ofMinutes(5).toSeconds());
        assertThat(s.activeSeconds(at(55))).isEqualTo(Duration.ofMinutes(50).toSeconds());
    }

    @Test
    void laHoraDeReanudarSeAcotaEntreElInicioDeLaPausaYAhora() {
        TrainingSession before = session();
        before.pause(at(10));
        before.resume(at(5), at(20));
        assertThat(before.pausedSeconds()).isZero();

        TrainingSession future = session();
        future.pause(at(10));
        future.resume(at(90), at(20));
        assertThat(future.pausedSeconds()).isEqualTo(Duration.ofMinutes(10).toSeconds());

        TrainingSession notPaused = session();
        notPaused.resume(at(5), at(20));
        assertThat(notPaused.pausedSeconds()).isZero();
    }
}
