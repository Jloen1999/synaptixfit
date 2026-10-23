package com.synaptixfit.domain.model.planner;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class IcsCalendarTest {

    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");

    @Test
    void parsesTimezonesAllDayDurationsFoldingAndEscapes() {
        String raw = String.join("\n",
                "BEGIN:VCALENDAR",
                "BEGIN:VEVENT",
                "UID:a@uni",
                "SUMMARY:Clase de Álgebra\\, grupo A",
                "DESCRIPTION:Primera línea\\nsegunda",
                "DTSTART;TZID=Europe/Madrid:20261021T090000",
                "DTEND;TZID=Europe/Madrid:20261021T110000",
                "LOCATION:Aula",
                "  Magna",
                "END:VEVENT",
                "BEGIN:VEVENT",
                "UID:b@uni",
                "SUMMARY:Entrega práctica 2",
                "DTSTART:20261105T225900Z",
                "DURATION:PT1H30M",
                "END:VEVENT",
                "BEGIN:VEVENT",
                "SUMMARY:Examen final",
                "DTSTART;VALUE=DATE:20270115",
                "END:VEVENT",
                "BEGIN:VEVENT",
                "UID:d@uni",
                "SUMMARY:Cancelada",
                "STATUS:CANCELLED",
                "DTSTART:20261105T100000Z",
                "END:VEVENT",
                "BEGIN:VEVENT",
                "UID:e@uni",
                "SUMMARY:Sin fecha",
                "END:VEVENT",
                "BEGIN:VEVENT",
                "UID:f@uni",
                "SUMMARY:Flotante",
                "DTSTART:20261023T120000",
                "DTEND:20261023T130000",
                "END:VEVENT",
                "END:VCALENDAR");

        List<IcsEvent> events = IcsCalendar.parse(raw, MADRID);

        assertThat(events).hasSize(4);
        IcsEvent lecture = events.get(0);
        assertThat(lecture.summary()).isEqualTo("Clase de Álgebra, grupo A");
        assertThat(lecture.description()).isEqualTo("Primera línea\nsegunda");
        assertThat(lecture.location()).isEqualTo("Aula Magna");
        assertThat(lecture.start()).isEqualTo(Instant.parse("2026-10-21T07:00:00Z"));
        assertThat(lecture.end()).isEqualTo(Instant.parse("2026-10-21T09:00:00Z"));
        assertThat(lecture.category()).isEqualTo(IcsEvent.Category.CLASS);

        IcsEvent delivery = events.get(1);
        assertThat(delivery.end()).isEqualTo(Instant.parse("2026-11-06T00:29:00Z"));
        assertThat(delivery.category()).isEqualTo(IcsEvent.Category.DELIVERY);

        IcsEvent exam = events.get(2);
        assertThat(exam.allDay()).isTrue();
        assertThat(exam.start()).isEqualTo(Instant.parse("2027-01-15T08:00:00Z"));
        assertThat(exam.uid()).startsWith("sxf-");
        assertThat(exam.category()).isEqualTo(IcsEvent.Category.EXAM);
        // El UID de respaldo es estable entre importaciones.
        assertThat(IcsCalendar.parse(raw, MADRID).get(2).uid()).isEqualTo(exam.uid());

        assertThat(events.get(3).start()).isEqualTo(Instant.parse("2026-10-23T10:00:00Z"));
    }

    @Test
    void rendersFoldedEscapedCalendar() {
        String longTitle = "Repaso de " + "termodinámica, ".repeat(10);
        TimelineItem block = new TimelineItem(TimelineItem.Kind.BLOCK, UUID.randomUUID(), ActivityType.REVIEW, null,
                longTitle, Instant.parse("2026-10-21T16:00:00Z"), Instant.parse("2026-10-21T16:30:00Z"), null, "Física",
                false, false, false, "Aula; 3", null, null, null, null, null);
        TimelineItem deadline = new TimelineItem(TimelineItem.Kind.DEADLINE, UUID.randomUUID(), null, DeadlineType.EXAM,
                "Parcial", Instant.parse("2026-10-30T09:00:00Z"), Instant.parse("2026-10-30T09:00:00Z"), null, null,
                true, false, false, null, null, null, null, null, null);

        String out = IcsCalendar.render(List.of(block, deadline), Instant.parse("2026-10-19T08:00:00Z"));

        assertThat(out).contains("DTSTART:20261021T160000Z\r\nDTEND:20261021T163000Z")
                .contains("LOCATION:Aula\\; 3").contains("CATEGORIES:repaso").contains("CATEGORIES:exam")
                .contains("STATUS:CONFIRMED").contains("DTSTAMP:20261019T080000Z");
        for (String line : out.split("\r\n")) {
            assertThat(line.getBytes(java.nio.charset.StandardCharsets.UTF_8).length).isLessThanOrEqualTo(75);
        }
        // Ida y vuelta: lo exportado se vuelve a leer con el mismo título.
        List<IcsEvent> back = IcsCalendar.parse(out, MADRID);
        assertThat(back).hasSize(2);
        assertThat(back.get(0).summary()).isEqualTo(longTitle.strip());
        assertThat(back.get(0).location()).isEqualTo("Aula; 3");
    }
}
