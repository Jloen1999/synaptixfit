package com.synaptixfit.application.service.analytics;

import com.synaptixfit.application.port.input.analytics.GetStudyBySubjectUseCase;
import com.synaptixfit.domain.model.analytics.StudyBySubject;
import com.synaptixfit.domain.model.insights.TimeZones;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.port.output.analytics.StudyBySubjectSourcePort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;

/**
 * Implementa {@link GetStudyBySubjectUseCase}: lee bloques y repasos de las últimas semanas (desde el lunes de la
 * primera, en la zona del usuario) y deja el agregado a {@link StudyBySubject#of}.
 */
public class StudyBySubjectService implements GetStudyBySubjectUseCase {

    private final StudyBySubjectSourcePort source;
    private final Clock clock;
    private final ZoneId defaultZone;

    public StudyBySubjectService(StudyBySubjectSourcePort source, Clock clock, ZoneId defaultZone) {
        this.source = source;
        this.clock = clock;
        this.defaultZone = defaultZone;
    }

    @Override
    public StudyBySubject getStudyBySubject(UUID userId, int weeks, String timeZone) {
        int span = Guard.range(weeks, "weeks", 1, MAX_WEEKS);
        ZoneId zone = TimeZones.resolve(timeZone, defaultZone);
        Instant now = clock.instant();
        LocalDate firstWeek = TimeZones.weekStart(LocalDate.ofInstant(now, zone)).minusWeeks(span - 1L);
        Instant from = TimeZones.startOfDay(firstWeek, zone);
        return StudyBySubject.of(firstWeek, span, source.activeSubjects(userId),
                source.completedStudyBlocks(userId, from, now), source.reviews(userId, from, now), zone);
    }
}
