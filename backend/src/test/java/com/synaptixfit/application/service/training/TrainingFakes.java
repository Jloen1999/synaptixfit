package com.synaptixfit.application.service.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.CatalogItem;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.Difficulty;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseDraft;
import com.synaptixfit.domain.model.training.ExerciseFilterOptions;
import com.synaptixfit.domain.model.training.ExerciseSearchCriteria;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.Recommendation;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.VisibleRoutine;
import com.synaptixfit.domain.model.training.WeeklyTrainingPlan;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.port.output.training.DailyCheckInRepositoryPort;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.domain.port.output.training.RecommendationRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import com.synaptixfit.domain.port.output.training.WeeklyPlanRepositoryPort;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Predicate;

/** Dobles en memoria de los puertos del módulo de entrenamiento. */
final class TrainingFakes {

    private TrainingFakes() {
    }

    static <T> PageResult<T> page(List<T> all, PageRequest page) {
        List<T> items = all.stream().skip(page.offset()).limit(page.size()).toList();
        return new PageResult<>(items, page.page(), page.size(), all.size());
    }

    static Exercise exercise(String name, Modality modality, List<MeasurementType> types, List<String> targets,
                             List<String> secondaries, TrainingGoal purpose) {
        int[] seq = {1};
        List<CatalogItem> t = targets.stream().map(m -> new CatalogItem(seq[0]++, m, null)).toList();
        List<CatalogItem> s = secondaries.stream().map(m -> new CatalogItem(seq[0]++, m, null)).toList();
        return new Exercise(UUID.randomUUID(), name, null, List.of(), Difficulty.BEGINNER,
                List.of(purpose.label()), modality, types, false, true, 6.0, null, null,
                List.of(new CatalogItem(1, "Tren superior", null)), t, s, List.of(), Instant.EPOCH, Instant.EPOCH);
    }

    static Exercise strength(String name, String target) {
        return exercise(name, Modality.STRENGTH, List.of(MeasurementType.REPETITIONS, MeasurementType.WEIGHT),
                List.of(target), List.of(), TrainingGoal.HYPERTROPHY);
    }

    // ------------------------------------------------------------------ ejercicios

    static final class Exercises implements ExerciseRepositoryPort {
        final Map<UUID, Exercise> store = new LinkedHashMap<>();
        final Set<UUID> usedInRoutines = new HashSet<>();
        boolean referencesExist = true;

        Exercise add(Exercise e) {
            store.put(e.id(), e);
            return e;
        }

        public PageResult<Exercise> search(ExerciseSearchCriteria c, PageRequest page) {
            return page(store.values().stream().filter(e -> c.includeInactive() || e.active()).toList(), page);
        }
        public Optional<Exercise> findById(UUID id) { return Optional.ofNullable(store.get(id)); }
        public Map<UUID, Exercise> findByIds(Collection<UUID> ids) {
            Map<UUID, Exercise> m = new LinkedHashMap<>();
            ids.forEach(id -> Optional.ofNullable(store.get(id)).ifPresent(e -> m.put(id, e)));
            return m;
        }
        public List<Exercise> findAllActive() { return store.values().stream().filter(Exercise::active).toList(); }
        public List<Exercise> findActiveByTargetMuscles(java.util.Collection<Integer> muscleIds,
                java.util.Set<com.synaptixfit.domain.model.training.ExerciseCategory> categories, int limit) {
            return store.values().stream().filter(Exercise::active)
                    .filter(e -> e.targetMuscles().stream().anyMatch(m -> muscleIds.contains(m.id())))
                    .filter(e -> categories.isEmpty() || categories.contains(e.category()))
                    .limit(limit).toList();
        }
        public ExerciseFilterOptions filterOptions() { return new ExerciseFilterOptions(List.of(), List.of(), List.of()); }
        public boolean catalogReferencesExist(ExerciseDraft draft) { return referencesExist; }
        public Exercise create(UUID id, ExerciseDraft d, Instant now) {
            return add(new Exercise(id, d.name(), d.description(), d.instructions(), d.difficulty(),
                    d.purposes().stream().map(TrainingGoal::label).toList(), d.modality(), d.measurementTypes(),
                    d.circuit(), true, d.met(), d.gifUrl(), d.previewUrl(), List.of(), List.of(), List.of(), List.of(),
                    now, now));
        }
        public Exercise update(UUID id, ExerciseDraft d, Instant now) { return create(id, d, now); }
        public void setActive(UUID id, boolean active, Instant now) {
            Exercise e = store.get(id);
            store.put(id, new Exercise(e.id(), e.name(), e.description(), e.instructions(), e.difficulty(), e.purposes(),
                    e.modality(), e.measurementTypes(), e.circuit(), active, e.met(), e.gifUrl(), e.previewUrl(),
                    e.bodyParts(), e.targetMuscles(), e.secondaryMuscles(), e.equipment(), e.createdAt(), now));
        }
        public boolean isUsedInRoutines(UUID id) { return usedInRoutines.contains(id); }
        public void delete(UUID id) { store.remove(id); }
    }

    // ------------------------------------------------------------------ rutinas

    static final class Routines implements RoutineRepositoryPort {
        final Map<UUID, Routine> store = new LinkedHashMap<>();
        final Map<UUID, String> authors = new LinkedHashMap<>();
        final Set<UUID> shadowbanned = new HashSet<>();
        int saves;

        public Optional<Routine> findById(UUID id) {
            return Optional.ofNullable(store.get(id)).filter(r -> !r.isDeleted());
        }
        public Routine save(Routine routine) {
            saves++;
            store.put(routine.id(), routine);
            return routine;
        }
        public PageResult<Routine> findByOwner(UUID ownerId, RoutineStatus status, PageRequest page) {
            return page(alive(r -> r.isOwnedBy(ownerId) && (status == null || r.status() == status)), page);
        }
        public List<Routine> findAllByOwner(UUID ownerId) { return alive(r -> r.isOwnedBy(ownerId)); }
        public Optional<Routine> findLatestActive(UUID ownerId) {
            return alive(r -> r.isOwnedBy(ownerId) && r.status() == RoutineStatus.ACTIVE).stream()
                    .max(Comparator.comparing(Routine::createdAt));
        }
        public PageResult<VisibleRoutine> findCommunity(UUID viewerId, String text, TrainingGoal goal, PageRequest page) {
            return page(alive(r -> !r.isOwnedBy(viewerId) && r.visibility() == Visibility.PUBLIC
                    && !shadowbanned.contains(r.ownerId())).stream()
                    .map(r -> new VisibleRoutine(r, authors.get(r.ownerId()))).toList(), page);
        }
        public Optional<VisibleRoutine> findVisible(UUID routineId, UUID viewerId) {
            return findById(routineId).filter(r -> r.isOwnedBy(viewerId)
                            || (r.visibility() == Visibility.PUBLIC && !shadowbanned.contains(r.ownerId())))
                    .map(r -> new VisibleRoutine(r, authors.get(r.ownerId())));
        }
        private List<Routine> alive(Predicate<Routine> p) {
            return store.values().stream().filter(r -> !r.isDeleted()).filter(p).toList();
        }
    }

    // ------------------------------------------------------------------ sesiones

    static final class Sessions implements TrainingSessionRepositoryPort {
        final Map<UUID, TrainingSession> store = new LinkedHashMap<>();
        Instant lastCompleted;
        List<CompletedSessionSummary> recent = new ArrayList<>();

        public TrainingSession save(TrainingSession s) {
            store.put(s.id(), s);
            return s;
        }
        public Optional<TrainingSession> findById(UUID id) { return Optional.ofNullable(store.get(id)); }
        public Optional<TrainingSession> findInProgressForDay(UUID userId, UUID dayId) {
            return store.values().stream().filter(s -> s.userId().equals(userId) && Objects.equals(s.dayId(), dayId)
                    && !s.isCompleted()).findFirst();
        }
        public boolean existsCompletedForDay(UUID dayId, UUID excludingSessionId) {
            return store.values().stream().anyMatch(s -> Objects.equals(s.dayId(), dayId) && s.isCompleted()
                    && !s.id().equals(excludingSessionId));
        }
        public PageResult<TrainingSession> findByUser(UUID userId, Boolean completed, PageRequest page) {
            return page(store.values().stream().filter(s -> s.userId().equals(userId))
                    .filter(s -> completed == null || s.isCompleted() == completed).toList(), page);
        }
        public Optional<Instant> lastCompletedAt(UUID userId) { return Optional.ofNullable(lastCompleted); }
        public List<CompletedSessionSummary> recentCompleted(UUID userId, int limit) { return recent; }
        public int countCompletedBetween(UUID userId, Instant from, Instant to) {
            return (int) store.values().stream().filter(s -> s.userId().equals(userId) && s.isCompleted()
                    && !s.completedAt().isBefore(from) && s.completedAt().isBefore(to)).count();
        }
        public void delete(UUID sessionId) { store.remove(sessionId); }
    }

    // ------------------------------------------------------------------ resto

    static final class Recommendations implements RecommendationRepositoryPort {
        final Map<UUID, Recommendation> store = new LinkedHashMap<>();

        public Recommendation save(Recommendation r) {
            store.put(r.id(), r);
            return r;
        }
        public void saveAll(List<Recommendation> list) { list.forEach(this::save); }
        public Optional<Recommendation> findById(UUID id) { return Optional.ofNullable(store.get(id)); }
        public PageResult<Recommendation> findByUser(UUID userId, Boolean applied, PageRequest page) {
            return page(store.values().stream().filter(r -> r.userId().equals(userId))
                    .filter(r -> applied == null || r.applied() == applied).toList(), page);
        }
        public void delete(UUID id) { store.remove(id); }
    }

    static final class CheckIns implements DailyCheckInRepositoryPort {
        final Map<UUID, DailyCheckIn> store = new LinkedHashMap<>();

        public Optional<DailyCheckIn> findByUserAndDate(UUID userId, LocalDate date) {
            return store.values().stream().filter(c -> c.userId().equals(userId) && c.date().equals(date)).findFirst();
        }
        public DailyCheckIn save(DailyCheckIn c) {
            store.put(c.id(), c);
            return c;
        }
        public PageResult<DailyCheckIn> findByUser(UUID userId, PageRequest page) {
            return page(store.values().stream().filter(c -> c.userId().equals(userId)).toList(), page);
        }
    }

    static final class Plans implements WeeklyPlanRepositoryPort {
        final Map<UUID, WeeklyTrainingPlan> store = new LinkedHashMap<>();

        public Optional<WeeklyTrainingPlan> findByUserAndWeek(UUID userId, LocalDate weekStart) {
            return store.values().stream().filter(p -> p.userId().equals(userId) && p.weekStart().equals(weekStart))
                    .findFirst();
        }
        public WeeklyTrainingPlan save(WeeklyTrainingPlan p) {
            store.put(p.id(), p);
            return p;
        }
        public void delete(UUID planId) { store.remove(planId); }
        public PageResult<WeeklyTrainingPlan> findByUser(UUID userId, PageRequest page) {
            return page(store.values().stream().filter(p -> p.userId().equals(userId)).toList(), page);
        }
    }
}
