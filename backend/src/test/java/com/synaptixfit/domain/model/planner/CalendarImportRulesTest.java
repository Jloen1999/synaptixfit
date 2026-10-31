package com.synaptixfit.domain.model.planner;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.Base64;
import org.junit.jupiter.api.Test;

/** Enlaces de Google Calendar, siglas de la asignatura y curso académico (importar el calendario de una asignatura). */
class CalendarImportRulesTest {

    private static final String ICS =
            "https://calendar.google.com/calendar/ical/9sclgiog2n9a4ovcsulmc7oqek%40group.calendar.google.com/public/basic.ics";

    @Test
    void theEmbeddedCalendarOfTheVirtualCampusBecomesItsPublicIcs() {
        assertThat(CalendarUrls.normalize(
                "https://www.google.com/calendar/embed?src=9sclgiog2n9a4ovcsulmc7oqek%40group.calendar.google.com&ctz=Europe/Madrid"))
                .isEqualTo(ICS);
        assertThat(CalendarUrls.normalize(
                "https://calendar.google.com/calendar/u/0/embed?src=9sclgiog2n9a4ovcsulmc7oqek@group.calendar.google.com&ctz=Europe/Madrid"))
                .isEqualTo(ICS);
        String cid = Base64.getEncoder().withoutPadding()
                .encodeToString("9sclgiog2n9a4ovcsulmc7oqek@group.calendar.google.com".getBytes(StandardCharsets.UTF_8));
        assertThat(CalendarUrls.normalize("https://calendar.google.com/calendar/u/0?cid=" + cid)).isEqualTo(ICS);
    }

    @Test
    void otherAddressesAreKept() {
        assertThat(CalendarUrls.normalize(ICS)).isEqualTo(ICS);
        assertThat(CalendarUrls.normalize(" https://campusvirtual.unex.es/calendar/export.ics?x=1 "))
                .isEqualTo("https://campusvirtual.unex.es/calendar/export.ics?x=1");
        assertThat(CalendarUrls.normalize("https://www.google.com/search?src=x")).isEqualTo("https://www.google.com/search?src=x");
    }

    @Test
    void eventsTitledWithTheSubjectInitialsBelongToIt() {
        assertThat(SubjectMatcher.acronym("ESTRUCTURA DE COMPUTADORES")).isEqualTo("ec");
        assertThat(SubjectMatcher.acronym("Interacción Persona-Ordenador")).isEqualTo("ipo");
        assertThat(SubjectMatcher.acronym("Cálculo")).isEmpty();
        assertThat(SubjectMatcher.mentions("EC_GG_Sesiones 1 y 2", "ESTRUCTURA DE COMPUTADORES", null)).isTrue();
        assertThat(SubjectMatcher.mentions("EC-B_ORD_GIIT_T7", "Estructura de Computadores", null)).isTrue();
        assertThat(SubjectMatcher.mentions("2_3_GIIT_EC", "Estructura de Computadores", null)).isTrue();
        assertThat(SubjectMatcher.mentions("IPO_Teoría_Tema 6_GIIT (Aula 2)", "Estructura de Computadores", null))
                .isFalse();
        // Las siglas cuentan solo como palabra suelta, no dentro de otra.
        assertThat(SubjectMatcher.mentions("Recepción de proyectos", "Estructura de Computadores", null)).isFalse();
        // Solo en mayúsculas: «al» o «se» son palabras corrientes.
        assertThat(SubjectMatcher.mentions("Entrega al profesor el informe", "Álgebra Lineal", null)).isFalse();
        assertThat(SubjectMatcher.mentions("Examen AL tema 3", "Álgebra Lineal", null)).isTrue();
        assertThat(SubjectMatcher.mentions("ec gg sesiones", "Estructura de Computadores", null)).isFalse();
    }

    @Test
    void theAcademicYearStartsOnTheFirstOfSeptember() {
        assertThat(IcsCalendar.academicYearStart(LocalDate.of(2026, 10, 31))).isEqualTo(LocalDate.of(2026, 9, 1));
        assertThat(IcsCalendar.academicYearStart(LocalDate.of(2027, 3, 2))).isEqualTo(LocalDate.of(2026, 9, 1));
        assertThat(IcsCalendar.calendarName("BEGIN:VCALENDAR\r\nX-WR-CALNAME:2_3_GIIT_EC\r\nEND:VCALENDAR"))
                .isEqualTo("2_3_GIIT_EC");
    }
}
