package com.synaptixfit.application.service.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.planner.IcsUrlMissingException;
import com.synaptixfit.application.port.input.planner.ImportGeneralCalendarUseCase;
import com.synaptixfit.application.port.input.planner.ImportIcsUseCase;
import com.synaptixfit.application.port.input.planner.ScanScheduleUseCase;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.ClassKind;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.PlannerProfile;
import com.synaptixfit.domain.model.planner.ScheduleEntry;
import com.synaptixfit.domain.model.planner.ScheduleScan;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.planner.TimelineItem;
import java.net.URI;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ImportAndScanServiceTest {

    private static final String ICS = String.join("\r\n",
            "BEGIN:VCALENDAR",
            "BEGIN:VEVENT",
            "UID:ev-1@uni",
            "SUMMARY:Álgebra Lineal - Teoría",
            "DTSTART;TZID=Europe/Madrid:20261021T090000",
            "DTEND;TZID=Europe/Madrid:20261021T110000",
            "LOCATION:Aula 2",
            "END:VEVENT",
            "BEGIN:VEVENT",
            "UID:ev-2@uni",
            "SUMMARY:Examen parcial Álgebra Lineal",
            "DTSTART:20261105T080000Z",
            "DTEND:20261105T100000Z",
            "END:VEVENT",
            "BEGIN:VEVENT",
            "UID:ev-3@uni",
            "SUMMARY:Reunión de delegados",
            "DTSTART:20261106T080000Z",
            "END:VEVENT",
            "END:VCALENDAR");

    private PlannerFakes f;
    private IcsService ics;
    private final List<URI> downloads = new ArrayList<>();
    private SubjectRef algebra;

    @BeforeEach
    void setUp() {
        f = new PlannerFakes();
        algebra = new SubjectRef(UUID.randomUUID(), "Álgebra Lineal", "ALG", 4, 6, "webcal://uni.example/alg.ics");
        f.directory.addSubject(f.user, algebra);
        TimelineService timeline = new TimelineService(f.blocks, f.deadlines, f.directory);
        ics = new IcsService(f.directory, f.blocks, f.deadlines, url -> {
            downloads.add(url);
            return ICS;
        }, timeline, f.weeklyLoadService(), PlannerFakes.ZONE, PlannerFakes.CLOCK);
    }

    /** Calendario del Campus Virtual: entregas y cuestionarios de varios cursos, con el curso en CATEGORIES. */
    private static final String MOODLE = String.join("\r\n",
            "BEGIN:VCALENDAR",
            "BEGIN:VEVENT",
            "UID:m-1@moodle",
            "SUMMARY:Práctica 2 está en fecha de entrega",
            "CATEGORIES:ÁLGEBRA LINEAL (2026-27)",
            "DTSTART:20261110T225900Z",
            "END:VEVENT",
            "BEGIN:VEVENT",
            "UID:m-2@moodle",
            "SUMMARY:Cuestionario tema 3 se abre",
            "CATEGORIES:ÁLGEBRA LINEAL (2026-27)",
            "DTSTART:20261108T080000Z",
            "END:VEVENT",
            "BEGIN:VEVENT",
            "UID:m-3@moodle",
            "SUMMARY:Entrega del informe",
            "CATEGORIES:FÍSICA I",
            "DTSTART:20261112T225900Z",
            "END:VEVENT",
            "BEGIN:VEVENT",
            "UID:m-4@moodle",
            "SUMMARY:Tutoría colectiva",
            "DTSTART:20261109T080000Z",
            "END:VEVENT",
            "END:VCALENDAR");

    @Test
    void aGeneralCalendarBringsOnlyDeadlinesEachInTheSubjectItMentions() {
        IcsService moodle = new IcsService(f.directory, f.blocks, f.deadlines, url -> MOODLE,
                new TimelineService(f.blocks, f.deadlines, f.directory), f.weeklyLoadService(), PlannerFakes.ZONE,
                PlannerFakes.CLOCK);

        ImportIcsUseCase.Result result = moodle.importGeneral(
                new ImportGeneralCalendarUseCase.Command(f.user, "https://campusvirtual.example/calendar.ics"));

        // Sin la tutoría (sería una clase) ni el aviso de apertura del cuestionario.
        assertThat(result.deliveries()).isEqualTo(2);
        assertThat(result.classes()).isZero();
        assertThat(f.deadlines.store.values()).extracting(d -> d.subjectId())
                .containsExactlyInAnyOrder(algebra.id(), null);
        assertThatThrownBy(() -> moodle.importGeneral(new ImportGeneralCalendarUseCase.Command(f.user, null)))
                .isInstanceOf(IcsUrlMissingException.class);
    }

    @Test
    void importsMatchingEventsIdempotentlyUsingTheSubjectUrl() {
        ImportIcsUseCase.Result first = ics.importIcs(new ImportIcsUseCase.Command(f.user, algebra.id(), null, false));

        assertThat(downloads).containsExactly(URI.create("https://uni.example/alg.ics"));
        assertThat(first.match()).isEqualTo(ImportIcsUseCase.Match.PARTIAL);
        assertThat(first.totalEvents()).isEqualTo(3);
        assertThat(first.classes()).isEqualTo(1);
        assertThat(first.exams()).isEqualTo(1);
        assertThat(first.created()).isEqualTo(3);
        assertThat(f.blocks.store).hasSize(2);
        assertThat(f.deadlines.store).hasSize(1);
        assertThat(f.deadlines.store.values().iterator().next().type()).isEqualTo(DeadlineType.EXAM);
        assertThat(f.blocks.store.values()).allSatisfy(b -> {
            assertThat(b.immovable()).isTrue();
            assertThat(b.subjectId()).isEqualTo(algebra.id());
        });
        CalendarBlock lecture = f.blocks.store.values().stream()
                .filter(b -> b.type() == ActivityType.CLASS).findFirst().orElseThrow();
        assertThat(lecture.start()).isEqualTo(PlannerFakes.at(2, 9, 0));
        assertThat(lecture.details().location()).isEqualTo("Aula 2");

        ImportIcsUseCase.Result second = ics.importIcs(new ImportIcsUseCase.Command(f.user, algebra.id(), null, false));
        assertThat(second.created()).isZero();
        assertThat(second.updated()).isEqualTo(3);
        assertThat(f.blocks.store).hasSize(2);
        assertThat(f.deadlines.store).hasSize(1);
    }

    @Test
    void aTeachersGoogleCalendarIsRecognisedByInitialsAndOnlyTheCurrentYearIsImported() {
        // Como el del Campus Virtual: nombre con siglas, eventos de cursos pasados y de otra asignatura.
        String teacher = String.join("\r\n",
                "BEGIN:VCALENDAR",
                "X-WR-CALNAME:2_3_GIIT_EC",
                "BEGIN:VEVENT", "UID:old@g", "SUMMARY:EC_GG_Tema 5", "DTSTART:20151020T080000Z",
                "DTEND:20151020T100000Z", "END:VEVENT",
                "BEGIN:VEVENT", "UID:now@g", "SUMMARY:EC_GG_Sesiones 1 y 2", "DTSTART:20261020T080000Z",
                "DTEND:20261020T100000Z", "END:VEVENT",
                "BEGIN:VEVENT", "UID:ipo@g", "SUMMARY:IPO_Teoría_Tema 6_GIIT (Aula 2)", "DTSTART:20261021T080000Z",
                "DTEND:20261021T100000Z", "END:VEVENT",
                "END:VCALENDAR");
        ics = new IcsService(f.directory, f.blocks, f.deadlines, url -> {
            downloads.add(url);
            return teacher;
        }, new TimelineService(f.blocks, f.deadlines, f.directory), f.weeklyLoadService(), PlannerFakes.ZONE,
                PlannerFakes.CLOCK);
        SubjectRef ec = f.directory.addSubject(f.user, "ESTRUCTURA DE COMPUTADORES", null, 2);

        ImportIcsUseCase.Result result = ics.importIcs(new ImportIcsUseCase.Command(f.user, ec.id(),
                "https://www.google.com/calendar/embed?src=abc%40group.calendar.google.com&ctz=Europe/Madrid", false));

        assertThat(downloads.getLast().toString())
                .isEqualTo("https://calendar.google.com/calendar/ical/abc%40group.calendar.google.com/public/basic.ics");
        assertThat(result.totalEvents()).isEqualTo(2);
        assertThat(result.matchingEvents()).isEqualTo(1);
        assertThat(result.imported()).isTrue();
        assertThat(f.blocks.store).hasSize(1);
    }

    @Test
    void theCalendarDescriptionIdentifiesTheSubjectAndHolidaysAreLeftOut() {
        // Como el de Programación del Campus: eventos «PR1_…», descripción «Asignatura: Programación».
        String teacher = String.join("\r\n",
                "BEGIN:VCALENDAR",
                "X-WR-CALNAME:1_1_GII_GITT_Programación",
                "X-WR-CALDESC:Asignatura: Programación (1er curso\\, 1er semestre)",
                "BEGIN:VEVENT", "UID:t2@g", "SUMMARY:PR1_GG_T2(2/2)", "DTSTART:20261017T090000Z",
                "DTEND:20261017T110000Z", "END:VEVENT",
                "BEGIN:VEVENT", "UID:p9@g", "SUMMARY:PR1_ORD_D_P9", "DTSTART:20261109T130000Z",
                "DTEND:20261109T150000Z", "END:VEVENT",
                "BEGIN:VEVENT", "UID:fest@g", "SUMMARY:Festivo", "DTSTART:20261012T000000Z",
                "DTEND:20261013T000000Z", "END:VEVENT",
                "END:VCALENDAR");
        ics = new IcsService(f.directory, f.blocks, f.deadlines, url -> teacher,
                new TimelineService(f.blocks, f.deadlines, f.directory), f.weeklyLoadService(), PlannerFakes.ZONE,
                PlannerFakes.CLOCK);
        SubjectRef fp = f.directory.addSubject(f.user, "Fundamentos de la Programación", null, 2);

        ImportIcsUseCase.Result result = ics.importIcs(
                new ImportIcsUseCase.Command(f.user, fp.id(), "https://uni.example/fp.ics", false));

        assertThat(result.imported()).isTrue();
        assertThat(result.totalEvents()).isEqualTo(2);
        assertThat(result.items()).extracting(ImportIcsUseCase.Item::title)
                .containsExactly("PR1_GG_T2(2/2)", "PR1_ORD_D_P9");
        assertThat(result.items()).allMatch(ImportIcsUseCase.Item::imported);
    }

    @Test
    void withoutMatchesNothingIsImportedUnlessForced() {
        SubjectRef other = f.directory.addSubject(f.user, "Química Orgánica", "QO", 3);
        ImportIcsUseCase.Result none = ics.importIcs(
                new ImportIcsUseCase.Command(f.user, other.id(), "https://uni.example/x.ics", false));
        assertThat(none.match()).isEqualTo(ImportIcsUseCase.Match.NONE);
        assertThat(none.imported()).isFalse();
        // Sin coincidencias se enseña lo que trae el calendario, sin importarlo.
        assertThat(none.items()).hasSize(3).noneMatch(ImportIcsUseCase.Item::imported);
        assertThat(f.blocks.store).isEmpty();

        ImportIcsUseCase.Result forced = ics.importIcs(
                new ImportIcsUseCase.Command(f.user, other.id(), "https://uni.example/x.ics", true));
        assertThat(forced.imported()).isTrue();
        assertThat(f.blocks.store).hasSize(3);
    }

    @Test
    void rejectsMissingOrUnsafeUrls() {
        SubjectRef noUrl = f.directory.addSubject(f.user, "Sin URL", null, 3);
        assertThatThrownBy(() -> ics.importIcs(new ImportIcsUseCase.Command(f.user, noUrl.id(), null, false)))
                .extracting("code").isEqualTo("PLANNER_ICS_URL_MISSING");
        assertThatThrownBy(() -> ics.importIcs(new ImportIcsUseCase.Command(f.user, noUrl.id(), "file:///etc/passwd", false)))
                .extracting("code").isEqualTo("PLANNER_ICS_URL_INVALID");
        assertThatThrownBy(() -> ics.importIcs(new ImportIcsUseCase.Command(f.otherUser, algebra.id(), null, false)))
                .extracting("code").isEqualTo("PLANNER_SUBJECT_NOT_FOUND");
    }

    @Test
    void exportContainsBlocksAndDeadlinesWithoutDuplicatingLinkedBlocks() {
        ics.importIcs(new ImportIcsUseCase.Command(f.user, algebra.id(), null, false));
        String out = ics.exportIcs(f.user, PlannerFakes.at(0, 0, 0), PlannerFakes.at(30, 0, 0));
        assertThat(out).startsWith("BEGIN:VCALENDAR\r\n").contains("SUMMARY:Álgebra Lineal - Teoría")
                .contains("LOCATION:Aula 2").endsWith("END:VCALENDAR\r\n");
        assertThat(out.split("BEGIN:VEVENT", -1)).hasSize(3);
        assertThat(out).contains("UID:" + TimelineItem.Kind.DEADLINE.name().toLowerCase() + "-");
    }

    // ------------------------------------------------------------------ escaneo

    @Test
    void scanRequiresSemesterDatesAndMaterializesIdempotently() {
        List<ScheduleEntry> pattern = List.of(
                new ScheduleEntry("ALG", "Algebra lineal", ClassKind.THEORY, 3, LocalTime.of(9, 0), LocalTime.of(11, 0),
                        "Aula 2"),
                new ScheduleEntry("", "Asignatura desconocida", null, 5, LocalTime.of(12, 0), LocalTime.of(13, 0), ""));
        ScheduleScanService scan = new ScheduleScanService((content, mime, names, sem) -> {
            assertThat(names).containsExactly("Álgebra Lineal");
            // Clases desde el 14 de septiembre: primer semestre.
            assertThat(sem).isEqualTo(1);
            return new ScheduleScan(pattern, List.of("ALG: Algebra lineal (1.º curso, 1.er semestre)"));
        }, f.directory, f.directory, f.blocks, PlannerFakes.ZONE, PlannerFakes.CLOCK);
        var command = new ScanScheduleUseCase.Command(f.user, new byte[]{1, 2, 3}, "application/pdf");

        assertThatThrownBy(() -> scan.scan(command)).extracting("code").isEqualTo("SCHEDULE_SEMESTER_DATES_MISSING");

        f.directory.academic.put(f.user, new PlannerProfile.Academic(14, LocalDate.of(2026, 9, 14),
                LocalDate.of(2026, 10, 9)));
        ScanScheduleUseCase.Result first = scan.scan(command);
        // 14/09 → 09/10: 4 miércoles y 4 viernes.
        assertThat(first.blocksCreated()).isEqualTo(8);
        assertThat(first.unmatchedSubjects()).containsExactly("Asignatura desconocida");
        assertThat(first.searchedSubjects()).containsExactly("Álgebra Lineal");
        assertThat(first.documentSubjects()).hasSize(1);
        assertThat(f.blocks.store.values()).allSatisfy(b -> {
            assertThat(b.type()).isEqualTo(ActivityType.CLASS);
            assertThat(b.fixed()).isFalse();
            assertThat(b.immovable()).isTrue();
        });
        assertThat(f.blocks.store.values()).filteredOn(b -> algebra.id().equals(b.subjectId())).hasSize(4)
                .allSatisfy(b -> assertThat(b.details().classKind()).isEqualTo(ClassKind.THEORY));

        ScanScheduleUseCase.Result again = scan.scan(command);
        assertThat(again.blocksCreated()).isZero();
        assertThat(again.blocksUpdated()).isEqualTo(8);
        assertThat(f.blocks.store).hasSize(8);
    }

    @Test
    void scanRejectsUnsupportedFilesAndEmptyResults() {
        f.directory.academic.put(f.user, new PlannerProfile.Academic(14, LocalDate.of(2026, 9, 14),
                LocalDate.of(2027, 1, 22)));
        ScheduleScanService scan = new ScheduleScanService((c, m, n, sem) -> new ScheduleScan(List.of(), List.of()), f.directory, f.directory,
                f.blocks, PlannerFakes.ZONE, PlannerFakes.CLOCK);
        assertThatThrownBy(() -> scan.scan(new ScanScheduleUseCase.Command(f.user, new byte[]{1}, "text/plain")))
                .extracting("code").isEqualTo("SCHEDULE_UNSUPPORTED_FILE");
        assertThatThrownBy(() -> scan.scan(new ScanScheduleUseCase.Command(f.user,
                new byte[(int) ScanScheduleUseCase.MAX_BYTES + 1], "image/png")))
                .extracting("code").isEqualTo("SCHEDULE_FILE_TOO_LARGE");
        assertThatThrownBy(() -> scan.scan(new ScanScheduleUseCase.Command(f.user, new byte[]{1}, "image/png")))
                .extracting("code").isEqualTo("SCHEDULE_NOTHING_FOUND");
    }
}
