package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Agenda de la tarjeta de asignatura (ADR 0036): próxima clase con su aula, días de clase y próxima entrega. */
class SubjectAgendaTest {

    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");

    private static Instant at(int day, int hour) {
        // Noviembre de 2026: el 9 es lunes.
        return LocalDateTime.of(2026, 11, day, hour, 0).atZone(MADRID).toInstant();
    }

    @Test
    void picksTheNextClassWithItsRoomAndTheDaysOfTheNextTwoWeeks() {
        SubjectAgenda agenda = SubjectAgenda.of(List.of(
                        new SubjectAgenda.ClassSlot(at(11, 12), "Aula 1.4"),
                        new SubjectAgenda.ClassSlot(at(9, 10), "Aula 2.3"),
                        new SubjectAgenda.ClassSlot(at(16, 10), null),
                        new SubjectAgenda.ClassSlot(at(30, 10), "Aula 9")),
                List.of(), "Aula 7", MADRID);

        assertThat(agenda.nextClassAt()).isEqualTo(at(9, 10));
        assertThat(agenda.nextClassPlace()).isEqualTo("Aula 2.3");
        // Lunes y miércoles; la del día 30 queda fuera de las dos semanas.
        assertThat(agenda.classDays()).containsExactly(1, 3);
    }

    @Test
    void usesTheSubjectRoomWhenTheClassHasNone() {
        SubjectAgenda agenda = SubjectAgenda.of(List.of(new SubjectAgenda.ClassSlot(at(10, 9), " ")), List.of(),
                "Aula 7", MADRID);

        assertThat(agenda.nextClassPlace()).isEqualTo("Aula 7");
    }

    @Test
    void picksTheClosestDeadlineAndIsEmptyWithoutData() {
        SubjectAgenda agenda = SubjectAgenda.of(List.of(), List.of(
                new SubjectAgenda.Deadline("Examen final", at(20, 9), true),
                new SubjectAgenda.Deadline("Práctica 2", at(12, 23), false)), null, MADRID);

        assertThat(agenda.nextDeadline().title()).isEqualTo("Práctica 2");
        assertThat(agenda.nextClassAt()).isNull();
        assertThat(agenda.nextClassPlace()).isNull();
        assertThat(SubjectAgenda.of(List.of(), List.of(), null, MADRID)).isEqualTo(SubjectAgenda.EMPTY);
    }

    @Test
    void anUrgentDeadlineGoesBeforeTheNextClass() {
        Instant now = at(9, 8);
        SubjectAgenda agenda = SubjectAgenda.of(List.of(new SubjectAgenda.ClassSlot(at(9, 10), "Aula 2.3")),
                List.of(new SubjectAgenda.Deadline("Práctica 1", at(10, 23), false)), null, null, now, MADRID);

        assertThat(agenda.nextUp()).isEqualTo(new SubjectAgenda.NextUp(SubjectAgenda.NextUpKind.DELIVERY,
                at(10, 23), null, 1, true));
    }

    @Test
    void theNextClassGoesBeforeADistantExamAndTheAssessmentIsTheLastResort() {
        Instant now = at(9, 8);
        SubjectAgenda withClass = SubjectAgenda.of(List.of(new SubjectAgenda.ClassSlot(at(11, 10), "Aula 2.3")),
                List.of(new SubjectAgenda.Deadline("Parcial", at(20, 9), true)), null, null, now, MADRID);
        assertThat(withClass.nextUp()).isEqualTo(new SubjectAgenda.NextUp(SubjectAgenda.NextUpKind.CLASS,
                at(11, 10), "Aula 2.3", 2, false));

        SubjectAgenda onlyExam = SubjectAgenda.of(List.of(),
                List.of(new SubjectAgenda.Deadline("Parcial", at(20, 9), true)), null, null, now, MADRID);
        assertThat(onlyExam.nextUp().kind()).isEqualTo(SubjectAgenda.NextUpKind.EXAM);
        assertThat(onlyExam.nextUp().daysLeft()).isEqualTo(11);

        SubjectAgenda onlyAssessment = SubjectAgenda.of(List.of(), List.of(), null, at(10, 9), now, MADRID);
        assertThat(onlyAssessment.nextUp()).isEqualTo(new SubjectAgenda.NextUp(
                SubjectAgenda.NextUpKind.ASSESSMENT, at(10, 9), null, 1, true));
        assertThat(SubjectAgenda.of(List.of(), List.of(), null, at(8, 9), now, MADRID).nextUp()).isNull();
    }

    @Test
    void daysAreCountedInTheZoneOfThePhone() {
        // 23:30 del lunes en Madrid ya es martes en Tokio: la clase del miércoles queda a un día, no a dos.
        Instant now = at(9, 23).plusSeconds(1800);
        SubjectAgenda agenda = SubjectAgenda.of(List.of(new SubjectAgenda.ClassSlot(at(11, 10), null)), List.of(),
                null, null, now, ZoneId.of("Asia/Tokyo"));

        assertThat(agenda.nextUp().daysLeft()).isEqualTo(1);
        assertThat(agenda.classDays()).containsExactly(3);
    }
}
