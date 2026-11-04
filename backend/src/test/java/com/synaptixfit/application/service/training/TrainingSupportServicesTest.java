package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.training.DeleteExerciseUseCase;
import com.synaptixfit.application.port.input.training.WeeklyPlanProgress;
import com.synaptixfit.domain.exception.training.CatalogReferenceInvalidException;
import com.synaptixfit.domain.exception.training.ExerciseNotFoundException;
import com.synaptixfit.domain.exception.training.RecommendationAlreadyAppliedException;
import com.synaptixfit.domain.exception.training.RecommendationNotFoundException;
import com.synaptixfit.domain.exception.training.WeeklyPlanNotFoundException;
import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.event.training.CheckInSubmitted;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.CatalogItem;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.Difficulty;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseAdjustment;
import com.synaptixfit.domain.model.training.ExerciseCategory;
import com.synaptixfit.domain.model.training.ExerciseDraft;
import com.synaptixfit.domain.model.training.ExerciseNameTranslations;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.ExerciseSearchCriteria;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.PlanIntensity;
import com.synaptixfit.domain.model.training.Recommendation;
import com.synaptixfit.domain.model.training.RecommendationType;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.training.WeeklyTrainingPlan;
import com.synaptixfit.domain.model.user.ExperienceChange;
import com.synaptixfit.domain.port.output.training.ExerciseNameTranslationsRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/** Servicios pequeños del módulo: check-in, sugerencias, catálogo y plan semanal. */
class TrainingSupportServicesTest {

    private static final UUID USER = UUID.randomUUID();
    private static final UUID OTHER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-10-07T09:00:00Z"); // miércoles
    private static final Clock CLOCK = Clock.fixed(NOW, ZoneOffset.UTC);

    @Nested
    class CheckIn {
        private final TrainingFakes.CheckIns checkIns = new TrainingFakes.CheckIns();
        private final List<Integer> awarded = new ArrayList<>();
        private final List<DomainEvent> events = new ArrayList<>();
        private final TrainingFakes.HealthConsents consents = new TrainingFakes.HealthConsents();
        private final DailyCheckInService service = new DailyCheckInService(checkIns, consents, (u, amount) -> {
            awarded.add(amount);
            return new ExperienceChange(1, amount, 0, amount);
        }, events::add, CLOCK, ZoneOffset.UTC);

        @Test
        void withoutHealthConsentNothingIsStored() {
            assertThatThrownBy(() -> service.submit(USER,
                    new DailyCheckIn.Values(4, 2, 4, 1, List.of(), true, null)))
                    .isInstanceOf(com.synaptixfit.domain.exception.training.HealthConsentRequiredException.class);
            assertThat(checkIns.store).isEmpty();
            assertThat(awarded).isEmpty();
        }

        @Test
        void onlyTheFirstCheckInOfTheDayAwardsXp() {
            consents.save(com.synaptixfit.domain.model.training.HealthConsent.give(USER, NOW));
            var first = service.submit(USER, new DailyCheckIn.Values(4, 2, 4, 1, List.of("piernas"), true, null));
            assertThat(first.firstOfDay()).isTrue();
            assertThat(first.xpAwarded()).isEqualTo(20);
            var second = service.submit(USER, new DailyCheckIn.Values(2, 5, 1, 5, List.of(), false, "mal día"));
            assertThat(second.firstOfDay()).isFalse();
            assertThat(second.xpAwarded()).isZero();
            assertThat(awarded).containsExactly(20);
            // Cada guardado publica CheckInSubmitted (racha, insignias y aviso de fatiga).
            assertThat(events).hasSize(2).allMatch(CheckInSubmitted.class::isInstance);
            assertThat(((CheckInSubmitted) events.get(1)).requiresAdaptation()).isTrue();
            assertThat(checkIns.store).hasSize(1);
            assertThat(service.today(USER)).get().satisfies(c -> {
                assertThat(c.date()).isEqualTo(LocalDate.of(2026, 10, 7));
                assertThat(c.readyToTrain()).isFalse();
                assertThat(c.requiresAdaptation()).isTrue();
            });
            assertThat(service.today(OTHER)).isEmpty();
        }
    }

    @Nested
    class Recommendations {
        private final TrainingFakes.Recommendations recommendations = new TrainingFakes.Recommendations();
        private final TrainingFakes.Routines routines = new TrainingFakes.Routines();
        private final RecommendationService service = new RecommendationService(recommendations, routines);

        @Test
        void applyCopiesAdjustmentsToTheRoutineAndCannotBeRepeated() {
            RoutineDay day = RoutineDay.create(1, null);
            var planned = day.addExercise(TrainingFakes.strength("Sentadilla", "Cuádriceps").toRef(),
                    new ExerciseParameters(3, 10, 90, 60.0, null, null, null, null));
            Routine routine = routines.save(Routine.create(USER, "Pierna", null, Visibility.PRIVATE,
                    TrainingGoal.HYPERTROPHY, null, null, List.of(RoutineWeek.create(1, null, WeekType.LOAD, List.of(day))), NOW));
            ExerciseParameters newParams = new ExerciseParameters(3, 11, 90, 63.0, null, null, null, null);
            Recommendation rec = recommendations.save(Recommendation.create(USER, RecommendationType.PROGRESSION, "Sube",
                    null, routine.id(), List.of(new ExerciseAdjustment(planned.id(), planned.exerciseId(), "Sentadilla",
                            newParams, "RPE bajo")), Map.of(), NOW));

            assertThatThrownBy(() -> service.apply(OTHER, rec.id())).isInstanceOf(RecommendationNotFoundException.class);
            Recommendation applied = service.apply(USER, rec.id());
            assertThat(applied.applied()).isTrue();
            assertThat(routine.plannedExercise(planned.id()).parameters()).isEqualTo(newParams);
            assertThatThrownBy(() -> service.apply(USER, rec.id())).isInstanceOf(RecommendationAlreadyAppliedException.class);
            assertThat(service.list(USER, true, new PageRequest(0, 10)).items()).hasSize(1);
        }

        @Test
        void discardDeletesOnlyOwnRecommendations() {
            Recommendation rec = recommendations.save(Recommendation.create(USER, RecommendationType.DELOAD, "Descansa",
                    null, null, List.of(), Map.of(), NOW));
            assertThatThrownBy(() -> service.discard(OTHER, rec.id())).isInstanceOf(RecommendationNotFoundException.class);
            service.discard(USER, rec.id());
            assertThat(recommendations.store).isEmpty();
        }
    }

    @Nested
    class Catalog {
        private final TrainingFakes.Exercises exercises = new TrainingFakes.Exercises();
        private final Map<UUID, ExerciseNameTranslations> names = new HashMap<>();
        private final ExerciseNameTranslationsRepositoryPort namesRepository = new ExerciseNameTranslationsRepositoryPort() {
            @Override
            public ExerciseNameTranslations findByExercise(UUID exerciseId) {
                return names.getOrDefault(exerciseId, ExerciseNameTranslations.EMPTY);
            }

            @Override
            public void replace(UUID exerciseId, ExerciseNameTranslations translations) {
                names.put(exerciseId, translations);
            }
        };
        private final ExerciseCatalogService service = new ExerciseCatalogService(exercises, namesRepository, CLOCK);

        private ExerciseDraft draft() {
            return draft(null);
        }

        private ExerciseDraft draft(ExerciseNameTranslations translations) {
            return new ExerciseDraft("Plancha frontal", null, List.of("Aguanta"), Difficulty.BEGINNER,
                    List.of(TrainingGoal.STABILITY), Modality.STRENGTH, null, false, 3.0, null, null,
                    List.of(1), List.of(2), List.of(), List.of(), translations);
        }

        @Test
        void namesInOtherLanguagesAreSavedWithTheExerciseAndKeptWhenOmitted() {
            ExerciseNameTranslations plank = new ExerciseNameTranslations("Front plank", "Gainage", "Prancha");
            Exercise e = service.create(draft(plank));
            assertThat(names).containsEntry(e.id(), plank);

            service.update(e.id(), draft(null));
            assertThat(names).containsEntry(e.id(), plank);

            service.update(e.id(), draft(ExerciseNameTranslations.EMPTY));
            assertThat(names.get(e.id()).isEmpty()).isTrue();
        }

        @Test
        void inactiveExercisesAreHiddenFromUsersButNotFromAdmins() {
            Exercise e = service.create(draft());
            service.setActive(e.id(), false);
            assertThatThrownBy(() -> service.get(e.id())).isInstanceOf(ExerciseNotFoundException.class);
            assertThat(service.adminGet(e.id()).active()).isFalse();
            assertThat(service.search(new ExerciseSearchCriteria(null, null, null, null, null, null, null, true),
                    new PageRequest(0, 10)).items()).isEmpty();
            assertThat(service.adminSearch(new ExerciseSearchCriteria(null, null, null, null, null, null, null, true),
                    new PageRequest(0, 10)).items()).hasSize(1);
        }

        @Test
        void deletingAnExerciseInUseDeactivatesIt() {
            Exercise used = service.create(draft());
            exercises.usedInRoutines.add(used.id());
            assertThat(service.delete(used.id())).isEqualTo(new DeleteExerciseUseCase.Result(false, true));
            assertThat(exercises.store.get(used.id()).active()).isFalse();
            Exercise free = service.create(draft());
            assertThat(service.delete(free.id())).isEqualTo(new DeleteExerciseUseCase.Result(true, false));
            assertThat(exercises.store).doesNotContainKey(free.id());
        }

        @Test
        void unknownCatalogReferencesAreRejected() {
            exercises.referencesExist = false;
            assertThatThrownBy(() -> service.create(draft())).isInstanceOf(CatalogReferenceInvalidException.class);
        }

        private Exercise add(String name, ExerciseCategory category, int muscle) {
            return exercises.add(new Exercise(UUID.randomUUID(), name, null, List.of(), Difficulty.BEGINNER, List.of(),
                    Modality.STRENGTH, List.of(MeasurementType.REPETITIONS), false, true, 3.0, null, null, List.of(),
                    List.of(new CatalogItem(muscle, "Músculo " + muscle, null)), List.of(), List.of(), NOW, NOW,
                    category));
        }

        @Test
        void bookendsOnlyAskForWarmUpAndCoolDownCategories() {
            List<UUID> session = new ArrayList<>();
            for (int muscle = 1; muscle <= 3; muscle++) {
                session.add(add("Press " + muscle, ExerciseCategory.STRENGTH, muscle).id());
                // Muchos de fuerza que antes llenaban el cupo de candidatos.
                for (int i = 0; i < ExerciseCatalogService.ALTERNATIVE_CANDIDATES; i++) {
                    add("A fuerza " + muscle + "-" + i, ExerciseCategory.STRENGTH, muscle);
                }
                add("Movilidad " + muscle, ExerciseCategory.MOBILITY, muscle);
                add("Estiramiento " + muscle, ExerciseCategory.STRETCHING, muscle);
            }
            session.add(session.getFirst());

            var bookends = service.bookends(session);

            assertThat(bookends.warmUp()).hasSize(3).allMatch(e -> e.category() == ExerciseCategory.MOBILITY);
            assertThat(bookends.coolDown()).hasSize(3).allMatch(e -> e.category() == ExerciseCategory.STRETCHING);
            assertThat(service.bookends(List.of()).warmUp()).isEmpty();
        }

        @Test
        void alternativesPreferTheSameCategoryAndFillWithOthers() {
            Exercise base = add("Sentadilla", ExerciseCategory.STRENGTH, 1);
            Exercise sameCategory = add("Prensa", ExerciseCategory.STRENGTH, 1);
            Exercise other = add("Sentadilla con salto", ExerciseCategory.PLYOMETRICS, 1);
            add("Remo", ExerciseCategory.STRENGTH, 2);

            assertThat(service.alternatives(base.id())).containsExactly(sameCategory, other);
        }
    }

    @Nested
    class Plans {
        private final TrainingFakes.Plans plans = new TrainingFakes.Plans();
        private final TrainingFakes.Sessions sessions = new TrainingFakes.Sessions();
        private final WeeklyPlanService service = new WeeklyPlanService(plans, sessions, CLOCK);

        @Test
        void planIsNormalizedToMondayAndReportsCompliance() {
            TrainingSession done = TrainingSession.start(USER, null, null, NOW);
            done.complete(1800, 6, 100, 100, NOW);
            sessions.save(done);
            WeeklyPlanProgress saved = service.save(USER, LocalDate.of(2026, 10, 8),
                    new WeeklyTrainingPlan.Values(4, PlanIntensity.HIGH, 45, null, null));
            assertThat(saved.plan().weekStart()).isEqualTo(LocalDate.of(2026, 10, 5));
            assertThat(saved.completedSessions()).isEqualTo(1);
            assertThat(saved.compliance()).isEqualTo(0.25);
            WeeklyPlanProgress updated = service.save(USER, LocalDate.of(2026, 10, 5),
                    new WeeklyTrainingPlan.Values(2, null, 30, null, "ajustado"));
            assertThat(updated.plan().id()).isEqualTo(saved.plan().id());
            assertThat(plans.store).hasSize(1);
            assertThatThrownBy(() -> service.get(OTHER, LocalDate.of(2026, 10, 5)))
                    .isInstanceOf(WeeklyPlanNotFoundException.class);
            service.delete(USER, LocalDate.of(2026, 10, 11));
            assertThat(plans.store).isEmpty();
        }
    }
}
