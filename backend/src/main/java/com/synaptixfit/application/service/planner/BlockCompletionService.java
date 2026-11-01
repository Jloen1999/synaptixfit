package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.planner.AttendClassUseCase;
import com.synaptixfit.application.port.input.planner.AttendEndedClassesUseCase;
import com.synaptixfit.application.port.input.planner.CompleteReviewBlockUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.port.input.planner.SyncSportBlockWithSessionUseCase;
import com.synaptixfit.domain.event.planner.SportBlockCompletionChanged;
import com.synaptixfit.domain.event.planner.StudyBlockCompletionChanged;
import com.synaptixfit.domain.exception.planner.BlockRoutineLinkedException;
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
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
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
 * El de un día de rutina tampoco se marca a mano ({@code BLOCK_ROUTINE_LINKED}): marcarlo no avanzaría
 * la rutina ni sumaría carga; se empieza la sesión o se registra como sesión pasada.
 *
 * <p>Las clases se dan por asistidas solas al terminar ({@link AttendEndedClassesUseCase} y
 * {@link AttendClassUseCase}, ADR 0029); desmarcar una clase es «No fui»: queda la ausencia y ya no se completa
 * sola. Marcar a mano y darla por asistida leen el bloque bloqueándolo ({@code findByIdForUpdate}) para que
 * un «No fui» a la vez que la tarea no se pise.
 */
public class BlockCompletionService implements SetBlockCompletionUseCase, SyncSportBlockWithSessionUseCase,
        CompleteReviewBlockUseCase, AttendEndedClassesUseCase, AttendClassUseCase {

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
    public Result setCompletion(UUID userId, UUID blockId, boolean completed, Integer effort) {
        CalendarBlock block = blocks.findByIdForUpdate(blockId)
                .filter(b -> b.userId().equals(userId))
                .orElseThrow(() -> new CalendarBlockNotFoundException(blockId));
        if (block.type() == ActivityType.SPORT && block.details().routineDayId() != null) {
            throw new BlockRoutineLinkedException();
        }
        if (completed) {
            block.requireStarted(clock.instant());
        } else if (block.type() == ActivityType.CLASS) {
            // «No fui»: además de desmarcarla, que no se dé por asistida sola al terminar.
            boolean marked = block.markAbsent();
            if (!block.completed()) {
                return new Result(marked ? blocks.save(block) : block, 0);
            }
        }
        return apply(block, completed, effort);
    }

    @Override
    public List<UUID> endedClassesToAttend() {
        Instant now = clock.instant();
        return blocks.findClassesToAttend(now.minus(CalendarBlock.AUTO_ATTEND_WINDOW), now).stream()
                .map(CalendarBlock::id).toList();
    }

    @Override
    public boolean attendClass(UUID blockId) {
        Instant now = clock.instant();
        return blocks.findByIdForUpdate(blockId)
                .filter(b -> b.attendsAutomatically(now))
                .map(b -> {
                    apply(b, true, null);
                    return true;
                })
                .orElse(false);
    }

    /**
     * El bloque que sigue a la sesión es el de ese día de rutina en la fecha de la sesión o, si se entrenó
     * otro día, el más cercano a esa fecha (por días; a igual distancia, el anterior): la rutina avanza
     * por orden, así que el calendario marca el día de rutina hecho aunque se moviera de fecha. Se elige sin
     * mirar su estado para que repetir el evento no marque otro bloque (los oyentes deben ser idempotentes).
     */
    @Override
    public void syncSportBlock(UUID userId, UUID routineDayId, LocalDate date, boolean completed) {
        if (routineDayId == null || date == null) {
            return;
        }
        blocks.findByRoutineDays(userId, List.of(routineDayId)).stream()
                .filter(b -> b.type() == ActivityType.SPORT)
                .min(Comparator.comparingLong((CalendarBlock b) -> Math.abs(ChronoUnit.DAYS.between(date,
                                zone.localDate(b.start()))))
                        .thenComparing(CalendarBlock::start))
                .ifPresent(b -> apply(b, completed, null));
    }

    @Override
    public void completeReviewBlock(UUID userId, UUID studyMaterialId) {
        Instant endOfToday = zone.startOfDay(zone.today(clock.instant()).plusDays(1));
        blocks.findPendingReviews(userId, studyMaterialId).stream()
                .filter(b -> b.start().isBefore(endOfToday))
                .reduce((first, second) -> second)
                .ifPresent(b -> apply(b, true, null));
    }

    /**
     * Cambia el estado (idempotente) con su XP, guarda, recalcula la semana y publica el evento. La
     * semana se recalcula antes de publicar para que los oyentes (insignias) lean la carga ya al día.
     */
    private Result apply(CalendarBlock block, boolean completed, Integer effort) {
        UUID userId = block.userId();
        Instant now = clock.instant();
        int xpDelta = 0;
        if (completed) {
            Energy energy = energyOf(block);
            if (!block.complete(now, energy.met(), energy.calories(), energy.load())) {
                return new Result(block, 0);
            }
            int reward = block.experienceReward();
            if (!block.xpAwarded() && reward > 0 && CalendarBlock.fitsDailyXp(blockXpOfDay(block), reward)) {
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
        if (saved.countsAsPhysicalActivity()) {
            events.publish(new SportBlockCompletionChanged(userId, saved.id(), zone.localDate(saved.start()), effort,
                    (int) saved.range().minutes(), saved.completed(), now));
        }
        return new Result(saved, xpDelta);
    }

    /** XP que ya dieron los otros bloques completados del mismo día que {@code block}. */
    private int blockXpOfDay(CalendarBlock block) {
        LocalDate day = zone.localDate(block.start());
        return blocks.findOverlapping(block.userId(), zone.startOfDay(day), zone.startOfDay(day.plusDays(1)), null)
                .stream()
                .filter(b -> !b.id().equals(block.id()) && b.completed() && b.xpAwarded()
                        && zone.localDate(b.start()).equals(day))
                .mapToInt(CalendarBlock::experienceReward)
                .sum();
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
