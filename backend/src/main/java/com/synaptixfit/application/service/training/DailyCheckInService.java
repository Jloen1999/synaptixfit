package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.training.GetTodayCheckInUseCase;
import com.synaptixfit.application.port.input.training.ListCheckInsUseCase;
import com.synaptixfit.application.port.input.training.SubmitDailyCheckInUseCase;
import com.synaptixfit.domain.event.training.CheckInSubmitted;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.TrainingRewards;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.training.DailyCheckInRepositoryPort;
import java.time.LocalDate;
import java.time.Clock;
import java.time.ZoneId;
import java.util.Optional;
import java.util.UUID;

/**
 * Check-in diario: uno por día; repetirlo actualiza el del día sin volver a dar experiencia (el
 * sistema heredado otorgaba los 20 puntos en cada guardado). Cada guardado publica
 * {@link CheckInSubmitted} (racha e insignias; aviso de fatiga si hay que adaptar el entrenamiento).
 */
public class DailyCheckInService implements SubmitDailyCheckInUseCase, GetTodayCheckInUseCase, ListCheckInsUseCase {

    private final DailyCheckInRepositoryPort checkIns;
    private final AwardExperienceUseCase awardExperience;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final ZoneId zone;

    /** @param zone zona que define «hoy» (la de indicadores e insignias, que leen el check-in por fecha) */
    public DailyCheckInService(DailyCheckInRepositoryPort checkIns, AwardExperienceUseCase awardExperience,
                               DomainEventPublisherPort events, Clock clock, ZoneId zone) {
        this.checkIns = checkIns;
        this.awardExperience = awardExperience;
        this.events = events;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public Result submit(UUID userId, DailyCheckIn.Values values) {
        LocalDate today = today();
        Optional<DailyCheckIn> existing = checkIns.findByUserAndDate(userId, today);
        if (existing.isPresent()) {
            DailyCheckIn checkIn = existing.get();
            checkIn.apply(values);
            return new Result(published(checkIns.save(checkIn)), false, 0);
        }
        DailyCheckIn saved = checkIns.save(DailyCheckIn.create(userId, today, values, clock.instant()));
        awardExperience.award(userId, TrainingRewards.CHECK_IN_XP);
        return new Result(published(saved), true, TrainingRewards.CHECK_IN_XP);
    }

    private DailyCheckIn published(DailyCheckIn saved) {
        events.publish(new CheckInSubmitted(saved.userId(), saved.date(), saved.fatigueScore(),
                saved.requiresAdaptation(), clock.instant()));
        return saved;
    }

    @Override
    public Optional<DailyCheckIn> today(UUID userId) {
        return checkIns.findByUserAndDate(userId, today());
    }

    @Override
    public PageResult<DailyCheckIn> list(UUID userId, PageRequest page) {
        return checkIns.findByUser(userId, page);
    }

    private LocalDate today() {
        return LocalDate.ofInstant(clock.instant(), zone);
    }
}
