package com.synaptixfit.application.service.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.planner.ImportIcsUseCase;
import com.synaptixfit.application.port.input.planner.ScanScheduleUseCase;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.ClassKind;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.PlannerProfile;
import com.synaptixfit.domain.model.planner.ScheduleEntry;
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
    void withoutMatchesNothingIsImportedUnlessForced() {
        SubjectRef other = f.directory.addSubject(f.user, "Química Orgánica", "QO", 3);
        ImportIcsUseCase.Result none = ics.importIcs(
                new ImportIcsUseCase.Command(f.user, other.id(), "https://uni.example/x.ics", false));
        assertThat(none.match()).isEqualTo(ImportIcsUseCase.Match.NONE);
        assertThat(none.imported()).isFalse();
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
        ScheduleScanService scan = new ScheduleScanService((content, mime, names) -> {
            assertThat(names).containsExactly("Álgebra Lineal");
            return pattern;
        }, f.directory, f.directory, f.blocks, PlannerFakes.ZONE, PlannerFakes.CLOCK);
        var command = new ScanScheduleUseCase.Command(f.user, new byte[]{1, 2, 3}, "application/pdf");

        assertThatThrownBy(() -> scan.scan(command)).extracting("code").isEqualTo("SCHEDULE_SEMESTER_DATES_MISSING");

        f.directory.academic.put(f.user, new PlannerProfile.Academic(14, LocalDate.of(2026, 9, 14),
                LocalDate.of(2026, 10, 9)));
        ScanScheduleUseCase.Result first = scan.scan(command);
        // 14/09 → 09/10: 4 miércoles y 4 viernes.
        assertThat(first.blocksCreated()).isEqualTo(8);
        assertThat(first.unmatchedSubjects()).containsExactly("Asignatura desconocida");
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
        ScheduleScanService scan = new ScheduleScanService((c, m, n) -> List.of(), f.directory, f.directory,
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
