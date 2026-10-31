package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.application.port.input.planner.ScanScheduleUseCase;
import com.synaptixfit.domain.model.planner.ClassKind;
import com.synaptixfit.domain.model.planner.ScheduleEntry;
import java.time.LocalTime;
import java.util.List;

/** Resultado del escaneo de horario, con el horario semanal detectado para que el estudiante lo vea. */
public record ScheduleScanResponse(int classesFound, int blocksCreated, int blocksUpdated,
                                   List<String> unmatchedSubjects, List<ScheduleClassResponse> classes) {

    /** Una clase del horario: día ISO (1 = lunes), horas locales, aula y si es teoría o práctica. */
    public record ScheduleClassResponse(String subjectName, ClassKind classKind, int dayOfWeek, LocalTime start,
                                        LocalTime end, String room) {

        static ScheduleClassResponse from(ScheduleEntry e) {
            return new ScheduleClassResponse(e.subjectName(), e.classKind(), e.dayOfWeek(), e.start(), e.end(),
                    e.room());
        }
    }

    public static ScheduleScanResponse from(ScanScheduleUseCase.Result r) {
        return new ScheduleScanResponse(r.classesFound(), r.blocksCreated(), r.blocksUpdated(), r.unmatchedSubjects(),
                r.classes().stream().map(ScheduleClassResponse::from).toList());
    }
}
