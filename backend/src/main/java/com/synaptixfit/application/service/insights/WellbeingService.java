package com.synaptixfit.application.service.insights;

import com.synaptixfit.application.port.input.insights.GetWellbeingUseCase;
import com.synaptixfit.domain.model.insights.AcademicAdherence;
import com.synaptixfit.domain.model.insights.DailyCheckIn;
import com.synaptixfit.domain.model.insights.EnergyScore;
import com.synaptixfit.domain.model.insights.TimeZones;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.insights.TotalLoadFactor;
import com.synaptixfit.domain.model.insights.WeeklyAcademicLoad;
import com.synaptixfit.domain.model.insights.WellbeingSnapshot;
import com.synaptixfit.domain.port.output.insights.InsightsSourcePort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Optional;
import java.util.UUID;

/** Estado energético, adherencia académica y FCT (los "medidores" del inicio de la app antigua). */
public class WellbeingService implements GetWellbeingUseCase {

    private final InsightsSourcePort sources;
    private final Clock clock;
    private final ZoneId defaultZone;

    public WellbeingService(InsightsSourcePort sources, Clock clock, ZoneId defaultZone) {
        this.sources = sources;
        this.clock = clock;
        this.defaultZone = defaultZone;
    }

    @Override
    public WellbeingSnapshot getWellbeing(UUID userId, String timeZone) {
        ZoneId zone = TimeZones.resolve(timeZone, defaultZone);
        LocalDate today = LocalDate.ofInstant(clock.instant(), zone);
        LocalDate weekStart = TimeZones.weekStart(today);
        Optional<DailyCheckIn> checkIn = sources.checkIn(userId, today);
        Optional<WeeklyAcademicLoad> weekly = sources.weeklyAcademicLoad(userId, weekStart);

        EnergyScore energy = checkIn.map(c -> EnergyScore.compute(c, weekly.orElse(null))).orElse(null);
        AcademicAdherence adherence = weekly.map(w -> adherence(userId, w, weekStart, zone)).orElse(null);
        TotalLoadFactor totalLoad = weekly.map(w -> TotalLoadFactor.compute(w, checkIn.orElse(null))).orElse(null);
        return new WellbeingSnapshot(today, checkIn.isPresent(), checkIn.orElse(null), energy, adherence,
                totalLoad, weekly.orElse(null));
    }

    private AcademicAdherence adherence(UUID userId, WeeklyAcademicLoad weekly, LocalDate weekStart, ZoneId zone) {
        Instant from = TimeZones.startOfDay(weekStart, zone);
        Instant to = TimeZones.startOfDay(weekStart.plusDays(7), zone);
        InsightsSourcePort.DeadlineCounts counts = sources.deadlineCounts(userId, from, to);
        int studyDays = (int) sources.completedStudyBlocks(userId, from, to).stream()
                .filter(b -> ActivityType.countsAsStudyCode(b.activityType()))
                .map(b -> LocalDate.ofInstant(b.start(), zone))
                .distinct()
                .count();
        return AcademicAdherence.compute(weekly, counts.total(), counts.completed(), studyDays);
    }
}
