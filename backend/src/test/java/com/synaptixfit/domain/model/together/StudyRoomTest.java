package com.synaptixfit.domain.model.together;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.together.TogetherGroupSizeException;
import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import com.synaptixfit.domain.exception.FieldValidationException;
import java.time.Duration;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/**
 * Reglas de la sala de «Estudiamos juntos» (ADR 0045 y 0053): fases desde la hora de inicio con los minutos elegidos,
 * cambio de minutos antes de empezar, caducidad y rondas que cuentan.
 */
class StudyRoomTest {

    private static final Instant NOW = Instant.parse("2026-11-16T09:00:00Z");
    private final UUID me = UUID.randomUUID();
    private final UUID ana = UUID.randomUUID();

    private static Instant at(int minutes) {
        return NOW.plus(Duration.ofMinutes(minutes));
    }

    @Test
    void phasesComeFromTheStartTimeWithABreakBetweenRounds() {
        StudyRoom room = StudyRoom.create(me, Set.of(ana), StudyRoomTimes.SHORT, 2, null, NOW);
        assertThat(room.momentAt(NOW).phase()).isEqualTo(StudyRoom.Phase.WAITING);
        assertThat(room.momentAt(NOW).endsAt()).isEqualTo(NOW.plus(StudyRoom.WAITING_LIMIT));
        room.start(me, NOW);
        assertThat(room.momentAt(at(10))).isEqualTo(new StudyRoom.Moment(StudyRoom.Phase.FOCUS, 1, at(25)));
        assertThat(room.momentAt(at(25))).isEqualTo(new StudyRoom.Moment(StudyRoom.Phase.BREAK, 1, at(30)));
        assertThat(room.momentAt(at(30))).isEqualTo(new StudyRoom.Moment(StudyRoom.Phase.FOCUS, 2, at(55)));
        assertThat(room.momentAt(at(55)).phase()).isEqualTo(StudyRoom.Phase.FINISHED);
        assertThat(room.endsAt()).isEqualTo(at(55));
        assertThatThrownBy(() -> room.start(me, at(1))).isInstanceOf(TogetherInvalidStateException.class);
    }

    @Test
    void aRoomNobodyStartsExpiresAfterFourHours() {
        StudyRoom room = StudyRoom.create(me, Set.of(ana), StudyRoomTimes.LONG, 1, null, NOW);
        Instant later = NOW.plus(StudyRoom.WAITING_LIMIT);
        assertThat(room.momentAt(later).phase()).isEqualTo(StudyRoom.Phase.EXPIRED);
        assertThatThrownBy(() -> room.join(ana, later)).isInstanceOf(TogetherInvalidStateException.class);
        assertThatThrownBy(() -> room.start(me, later)).isInstanceOf(TogetherInvalidStateException.class);
    }

    @Test
    void groupAndRoundsAreLimited() {
        assertThatThrownBy(() -> StudyRoom.create(me, Set.of(), StudyRoomTimes.SHORT, 1, null, NOW))
                .isInstanceOf(TogetherGroupSizeException.class);
        Set<UUID> five = new HashSet<>();
        IntStream.range(0, 5).forEach(i -> five.add(UUID.randomUUID()));
        assertThatThrownBy(() -> StudyRoom.create(me, five, StudyRoomTimes.SHORT, 1, null, NOW))
                .isInstanceOf(TogetherGroupSizeException.class);
        assertThatThrownBy(() -> StudyRoom.create(me, Set.of(ana), StudyRoomTimes.SHORT, 5, null, NOW))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void eachFinishedRoundCountsForWhoIsInsideWithTheMinutesTheyWereThere() {
        UUID subject = UUID.randomUUID();
        StudyRoom room = StudyRoom.create(me, Set.of(ana), StudyRoomTimes.SHORT, 2, subject, NOW);
        room.start(me, NOW);
        assertThat(room.creditsDue(at(24))).isEmpty();
        room.join(ana, at(10));
        assertThat(room.creditsDue(at(26))).containsExactlyInAnyOrder(
                new StudyRoom.Credit(me, 1, 25, at(25), subject),
                new StudyRoom.Credit(ana, 1, 15, at(25), null));
        room.markCredited(room.roundsToCredit(at(26)));
        assertThat(room.creditsDue(at(29))).isEmpty();
        room.leave(ana, at(40));
        assertThat(room.creditsDue(at(56))).containsExactly(new StudyRoom.Credit(me, 2, 25, at(55), subject));
    }

    @Test
    void reactionsAreOnlyForPeopleInsideAndFade() {
        StudyRoom room = StudyRoom.create(me, Set.of(ana), StudyRoomTimes.SHORT, 1, null, NOW);
        assertThatThrownBy(() -> room.react(ana, StudyRoomReaction.CLAP, NOW))
                .isInstanceOf(TogetherInvalidStateException.class);
        room.react(me, StudyRoomReaction.COFFEE, NOW);
        assertThat(room.reactionShown(me, at(1))).contains(StudyRoomReaction.COFFEE);
        assertThat(room.reactionShown(me, at(2))).isEmpty();
    }

    @Test
    void whenTheCreatorLeavesTheRoomGoesOnForTheOthers() {
        StudyRoom room = StudyRoom.create(me, Set.of(ana), StudyRoomTimes.SHORT, 1, null, NOW);
        room.join(ana, NOW);
        room.start(ana, NOW);
        room.leave(me, at(5));
        assertThat(room.canView(me)).isFalse();
        assertThat(room.momentAt(at(6)).phase()).isEqualTo(StudyRoom.Phase.FOCUS);
        assertThat(room.creditsDue(at(25))).extracting(StudyRoom.Credit::userId).containsExactly(ana);
    }

    @Test
    void anyMinutesWithinTheLimitsAreValid() {
        StudyRoom room = StudyRoom.create(me, Set.of(ana), new StudyRoomTimes(40, 8), 2, null, NOW);
        room.start(me, NOW);
        assertThat(room.momentAt(at(39))).isEqualTo(new StudyRoom.Moment(StudyRoom.Phase.FOCUS, 1, at(40)));
        assertThat(room.momentAt(at(40))).isEqualTo(new StudyRoom.Moment(StudyRoom.Phase.BREAK, 1, at(48)));
        assertThat(room.endsAt()).isEqualTo(at(88));
        assertThatThrownBy(() -> new StudyRoomTimes(14, 5)).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> new StudyRoomTimes(91, 5)).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> new StudyRoomTimes(25, 0)).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> new StudyRoomTimes(25, 31)).isInstanceOf(FieldValidationException.class);
        assertThat(new StudyRoomTimes(15, 1)).isNotNull();
        assertThat(new StudyRoomTimes(90, 30)).isNotNull();
        // Los límites son los del Pomodoro individual.
        assertThat(StudyRoomTimes.MAX_FOCUS_MINUTES).isEqualTo(
                com.synaptixfit.domain.model.planner.FocusPlan.MAX_FOCUS_MINUTES);
    }

    @Test
    void anyoneInsideChangesTheMinutesOnlyBeforeStarting() {
        StudyRoom room = StudyRoom.create(me, Set.of(ana), StudyRoomTimes.SHORT, 1, null, NOW);
        // Invitada sin entrar aún: no puede cambiarlos.
        assertThatThrownBy(() -> room.changeTimes(ana, StudyRoomTimes.LONG, NOW))
                .isInstanceOf(TogetherInvalidStateException.class);
        room.join(ana, NOW);
        room.changeTimes(ana, new StudyRoomTimes(30, 6), at(1));
        assertThat(room.times()).isEqualTo(new StudyRoomTimes(30, 6));
        room.start(me, at(2));
        assertThat(room.endsAt()).isEqualTo(at(32));
        assertThatThrownBy(() -> room.changeTimes(me, StudyRoomTimes.LONG, at(3)))
                .isInstanceOf(TogetherInvalidStateException.class);
    }
}
