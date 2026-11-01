package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.ScanScheduleUseCase;
import com.synaptixfit.domain.exception.planner.ScheduleFileTooLargeException;
import com.synaptixfit.domain.exception.planner.ScheduleNothingFoundException;
import com.synaptixfit.domain.exception.planner.SemesterDatesMissingException;
import com.synaptixfit.domain.exception.planner.UnsupportedScheduleFileException;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.PlannerProfile;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.ScheduleEntry;
import com.synaptixfit.domain.model.planner.ScheduleScan;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.planner.WeeklyPatternMaterializer;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.PlannerProfilePort;
import com.synaptixfit.domain.port.output.planner.ScheduleScannerPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/** Escaneo de horarios con IA y materialización del patrón semanal en el calendario. */
public class ScheduleScanService implements ScanScheduleUseCase {

    static final Set<String> SUPPORTED_TYPES = Set.of("application/pdf", "image/png", "image/jpeg", "image/jpg",
            "image/webp", "image/heic", "image/heif");

    private final ScheduleScannerPort scanner;
    private final SubjectDirectoryPort subjects;
    private final PlannerProfilePort profiles;
    private final CalendarBlockRepositoryPort blocks;
    private final PlannerZone zone;
    private final Clock clock;
    private final ConflictFlagger conflicts;

    public ScheduleScanService(ScheduleScannerPort scanner, SubjectDirectoryPort subjects, PlannerProfilePort profiles,
                               CalendarBlockRepositoryPort blocks, PlannerZone zone, Clock clock) {
        this.scanner = scanner;
        this.subjects = subjects;
        this.profiles = profiles;
        this.blocks = blocks;
        this.zone = zone;
        this.clock = clock;
        this.conflicts = new ConflictFlagger(blocks);
    }

    @Override
    public Result scan(Command command) {
        if (command.content() == null || command.content().length == 0) {
            throw new UnsupportedScheduleFileException();
        }
        if (command.content().length > MAX_BYTES) {
            throw new ScheduleFileTooLargeException();
        }
        String mime = command.mimeType() == null ? "" : command.mimeType().toLowerCase(Locale.ROOT).strip();
        if (!SUPPORTED_TYPES.contains(mime)) {
            throw new UnsupportedScheduleFileException();
        }
        PlannerProfile.Academic academic = profiles.findAcademic(command.userId())
                .filter(PlannerProfile.Academic::hasSemesterDates)
                .orElseThrow(SemesterDatesMissingException::new);
        List<SubjectRef> active = subjects.findActive(command.userId());
        List<String> searched = active.stream().map(SubjectRef::name).toList();
        int semester = academic.semesterNumber();
        ScheduleScan scan = scanner.extractWeeklyPattern(command.content(), mime, searched, semester);
        List<ScheduleEntry> entries = scan.entries();
        if (entries.isEmpty()) {
            // Sin ninguna asignatura legible no hay nada que explicar; si el documento trae otras, se enseñan.
            if (scan.documentSubjects().isEmpty()) {
                throw new ScheduleNothingFoundException();
            }
            return new Result(0, 0, 0, List.of(), List.of(), searched, scan.documentSubjects(), semester);
        }
        Instant now = clock.instant();
        WeeklyPatternMaterializer.Result pattern = WeeklyPatternMaterializer.materialize(command.userId(), entries,
                active, academic.semesterStart(), academic.semesterEnd(), zone, UUID::randomUUID, now);
        Map<String, CalendarBlock> existing = blocks.findByIcsUids(command.userId(),
                pattern.blocks().stream().map(CalendarBlock::icsUid).toList());
        List<CalendarBlock> toSave = new ArrayList<>();
        int created = 0;
        int updated = 0;
        for (CalendarBlock block : pattern.blocks()) {
            CalendarBlock current = existing.get(block.icsUid());
            if (current == null) {
                toSave.add(block);
                created++;
            } else {
                current.syncFromSource(block.range(), block.dayOfWeek(), block.type(), block.details());
                toSave.add(current);
                updated++;
            }
        }
        List<CalendarBlock> saved = blocks.saveAll(toSave);
        conflicts.refresh(command.userId(), saved, List.of());
        List<ScheduleEntry> timetable = entries.stream()
                .sorted(Comparator.comparingInt(ScheduleEntry::dayOfWeek).thenComparing(ScheduleEntry::start))
                .toList();
        return new Result(pattern.classes(), created, updated, pattern.unmatchedSubjects(), timetable, searched,
                scan.documentSubjects(), semester);
    }
}
