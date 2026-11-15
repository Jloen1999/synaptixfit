package com.synaptixfit.domain.model.together;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.together.TogetherGroupSizeException;
import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import java.time.Duration;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Reglas de la sala de «Estudiamos juntos» (ADR 0045): fases desde la hora de inicio, caducidad y rondas que cuentan. */
class StudyRoomTest {

    private static final Instant NOW = Instant.parse("2026-11-16T09:00:00Z");
    private final UUID me = UUID.randomUUID();
    private final UUID ana = UUID.randomUUID();

    private static Instant at(int minutes) {
        return NOW.plus(Duration.ofMinutes(minutes));
    }

    @Test
    void phasesComeFromTheStartTimeWithABreakBetweenRounds() {
        StudyRoom room = StudyRoom.create(me, Set.of(ana), StudyRoomLength.SHORT, 2, null, NOW);
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
        StudyRoom room = StudyRoom.create(me, Set.of(ana), StudyRoomLength.LONG, 1, null, NOW);
        Instant later = NOW.plus(StudyRoom.WAITING_LIMIT);
        assertThat(room.momentAt(later).phase()).isEqualTo(StudyRoom.Phase.EXPIRED);
        assertThatThrownBy(() -> room.join(ana, later)).isInstanceOf(TogetherInvalidStateException.class);
        assertThatThrownBy(() -> room.start(me, later)).isInstanceOf(TogetherInvalidStateException.class);
    }

    @Test
    void groupAndRoundsAreLimited() {
        assertThatThrownBy(() -> StudyRoom.create(me, Set.of(), StudyRoomLength.SHORT, 1, null, NOW))
                .isInstanceOf(TogetherGroupSizeException.class);
        Set<UUID> five = new HashSet<>();
        IntStream.range(0, 5).forEach(i -> five.add(UUID.randomUUID()));
        assertThatThrownBy(() -> StudyRoom.create(me, five, StudyRoomLength.SHORT, 1, null, NOW))
                .isInstanceOf(TogetherGroupSizeException.class);
        assertThatThrownBy(() -> StudyRoom.create(me, Set.of(ana), StudyRoomLength.SHORT, 5, null, NOW))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void eachFinishedRoundCountsForWhoIsInsideWithTheMinutesTheyWereThere() {
        UUID subject = UUID.randomUUID();
        StudyRoom room = StudyRoom.create(me, Set.of(ana), StudyRoomLength.SHORT, 2, subject, NOW);
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
        StudyRoom room = StudyRoom.create(me, Set.of(ana), StudyRoomLength.SHORT, 1, null, NOW);
        assertThatThrownBy(() -> room.react(ana, StudyRoomReaction.CLAP, NOW))
                .isInstanceOf(TogetherInvalidStateException.class);
        room.react(me, StudyRoomReaction.COFFEE, NOW);
        assertThat(room.reactionShown(me, at(1))).contains(StudyRoomReaction.COFFEE);
        assertThat(room.reactionShown(me, at(2))).isEmpty();
    }

    @Test
    void whenTheCreatorLeavesTheRoomGoesOnForTheOthers() {
        StudyRoom room = StudyRoom.create(me, Set.of(ana), StudyRoomLength.SHORT, 1, null, NOW);
        room.join(ana, NOW);
        room.start(ana, NOW);
        room.leave(me, at(5));
        assertThat(room.canView(me)).isFalse();
        assertThat(room.momentAt(at(6)).phase()).isEqualTo(StudyRoom.Phase.FOCUS);
        assertThat(room.creditsDue(at(25))).extracting(StudyRoom.Credit::userId).containsExactly(ana);
    }
}
