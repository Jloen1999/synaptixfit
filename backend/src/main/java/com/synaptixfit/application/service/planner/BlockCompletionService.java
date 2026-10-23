package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.planner.CompleteReviewBlockUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.port.input.planner.SyncSportBlockWithSessionUseCase;
import com.synaptixfit.domain.event.planner.StudyBlockCompletionChanged;
import com.synaptixfit.domain.exception.planner.CalendarBlockNotFoundException;
import com.synaptixfit.domain.model.neuro.CognitiveLoad;
import com.synaptixfit.domain.model.neuro.StudyBlockLoad;
import com.synaptixfit.domain.model.neuro.StudyEnergy;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.PlannerProfilePort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Completar y desmarcar bloques.
 *
 * <p>Al completar un bloque cognitivo (estudio, clase, repaso, examen, entrega) se guardan su MET
 * cognitivo, su gasto calórico (Fórmula 1, con el RMR del perfil de bienestar; nulo si no hay perfil)
 * y la carga cognitiva generada (Fórmula 2, con la dificultad percibida de la asignatura).
 *
 * <p>Los bloques que reflejan una actividad de otro módulo siguen su estado por eventos: el bloque de
 * deporte de un día de rutina sigue a la sesión de entrenamiento y el bloque de repaso de un material
 * se completa al hacer el repaso SM-2. Esos bloques no dan XP propia ({@link CalendarBlock#experienceReward()}).
 */
public class BlockCompletionService implements SetBlockCompletionUseCase, SyncSportBlockWithSessionUseCase,
        CompleteReviewBlockUseCase {

    private final CalendarBlockRepositoryPort blocks;
    private final SubjectDirectoryPort subjects;
    private final PlannerProfilePort profiles;
    private final AwardExperienceUseCase award;
    private final RevokeExperienceUseCase revoke;
    private final DomainEventPublisherPort events;
    private final WeeklyLoadService weeklyLoads;
    private final PlannerZone zone;
    private final Clock clock;

    public BlockCompletionService(CalendarBlockRepositoryPort blocks, SubjectDirectoryPort subjects,
                                  PlannerProfilePort profiles, AwardExperienceUseCase award,
                                  RevokeExperienceUseCase revoke, DomainEventPublisherPort events,
                                  WeeklyLoadService weeklyLoads, PlannerZone zone, Clock clock) {
        this.blocks = blocks;
        this.subjects = subjects;
        this.profiles = profiles;
        this.award = award;
        this.revoke = revoke;
        this.events = events;
        this.weeklyLoads = weeklyLoads;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public Result setCompletion(UUID userId, UUID blockId, boolean completed) {
        CalendarBlock block = blocks.findById(blockId)
                .filter(b -> b.userId().equals(userId))
                .orElseThrow(() -> new CalendarBlockNotFoundException(blockId));
        return apply(block, completed);
    }

    @Override
    public void syncSportBlock(UUID userId, UUID routineDayId, LocalDate date, boolean completed) {
        if (routineDayId == null || date == null) {
            return;
        }
        blocks.findOverlapping(userId, zone.startOfDay(date), zone.startOfDay(date.plusDays(1)), null).stream()
                .filter(b -> b.type() == ActivityType.SPORT && routineDayId.equals(b.details().routineDayId()))
                .filter(b -> zone.localDate(b.start()).equals(date))
                .forEach(b -> apply(b, completed));
    }

    @Override
    public void completeReviewBlock(UUID userId, UUID studyMaterialId) {
        Instant endOfToday = zone.startOfDay(zone.today(clock.instant()).plusDays(1));
        blocks.findPendingReviews(userId, studyMaterialId).stream()
                .filter(b -> b.start().isBefore(endOfToday))
                .reduce((first, second) -> second)
                .ifPresent(b -> apply(b, true));
    }

    /**
     * Cambia el estado (idempotente) con su XP, guarda, recalcula la semana y publica el evento. La
     * semana se recalcula antes de publicar para que los oyentes (insignias) lean la carga ya al día.
     */
    private Result apply(CalendarBlock block, boolean completed) {
        UUID userId = block.userId();
        Instant now = clock.instant();
        int xpDelta = 0;
        if (completed) {
            Energy energy = energyOf(block);
            if (!block.complete(now, energy.met(), energy.calories(), energy.load())) {
                return new Result(block, 0);
            }
            int reward = block.experienceReward();
            if (!block.xpAwarded() && reward > 0) {
                award.award(userId, reward);
                block.markExperienceAwarded(true);
                xpDelta = reward;
            }
        } else {
            if (!block.uncomplete()) {
                return new Result(block, 0);
            }
            if (block.xpAwarded()) {
                int reward = block.experienceReward();
                revoke.revoke(userId, reward);
                block.markExperienceAwarded(false);
                xpDelta = -reward;
            }
        }
        CalendarBlock saved = blocks.save(block);
        weeklyLoads.refresh(userId, zone.localDate(saved.start()));
        events.publish(new StudyBlockCompletionChanged(userId, saved.id(), saved.type().code(), saved.subjectId(),
                saved.details().milestoneId(), saved.start(), saved.end(), saved.completed(), now));
        return new Result(saved, xpDelta);
    }

    private Energy energyOf(CalendarBlock block) {
        if (!block.type().isCognitive()) {
            return new Energy(null, null, null);
        }
        double met = block.type() == ActivityType.CLASS ? StudyEnergy.MET_CLASS : StudyEnergy.MET_STUDY;
        Double calories = profiles.findMetabolic(block.userId())
                .map(p -> StudyEnergy.blockCalories(
                        StudyEnergy.restingMetabolicRate(p.weightKg(), p.heightCm(), p.age(), p.sex()),
                        block.range().seconds(), met))
                .orElse(null);
        double difficulty = block.subjectId() == null ? 1.0 : subjects.findOwned(block.userId(), block.subjectId())
                .map(SubjectRef::perceivedDifficulty)
                .map(CognitiveLoad::difficultyMultiplier)
                .orElse(1.0);
        double load = CognitiveLoad.accumulated(List.of(new StudyBlockLoad(block.range().minutes(), difficulty, 0)));
        return new Energy(met, calories, load);
    }

    private record Energy(Double met, Double calories, Double load) {
    }
}
