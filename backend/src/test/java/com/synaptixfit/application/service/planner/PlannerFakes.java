package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.model.insights.AcwrZone;
import com.synaptixfit.domain.model.insights.CrossRegulationState;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.model.planner.PlannerProfile;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.RoutineRef;
import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.planner.WeeklyAcademicLoad;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.ExperienceChange;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.ChallengeDirectoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.FocusSessionRepositoryPort;
import com.synaptixfit.domain.port.output.planner.PlannerProfilePort;
import com.synaptixfit.domain.port.output.planner.RoutineDirectoryPort;
import com.synaptixfit.domain.port.output.planner.StudyPlanRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import com.synaptixfit.domain.port.output.planner.WeeklyLoadRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Dobles en memoria de los puertos del planificador para las pruebas de servicios (sin Spring).
 *
 * <p>Reloj fijo: lunes 19/10/2026 08:00 UTC (10:00 en Madrid).
 */
final class PlannerFakes {

    static final Instant NOW = Instant.parse("2026-10-19T08:00:00Z");
    static final Clock CLOCK = Clock.fixed(NOW, ZoneOffset.UTC);
    /**
     * Domingo por la noche de la semana de {@link #NOW}: todos sus bloques ya han empezado, así que
     * se pueden marcar como hechos (no se completa un bloque antes de empezar).
     */
    static final Clock END_OF_WEEK = Clock.fixed(NOW.plus(java.time.Duration.ofDays(6)).plus(
            java.time.Duration.ofHours(14)), ZoneOffset.UTC);
    static final PlannerZone ZONE = PlannerZone.of("Europe/Madrid");
    static final LocalDate MONDAY = LocalDate.of(2026, 10, 19);

    final UUID user = UUID.randomUUID();
    final UUID otherUser = UUID.randomUUID();
    final Blocks blocks = new Blocks();
    final Deadlines deadlines = new Deadlines();
    final Plans plans = new Plans();
    final Loads loads = new Loads();
    final Focus focus = new Focus();
    final Directory directory = new Directory();
    final Xp xp = new Xp();
    final List<DomainEvent> events = new ArrayList<>();
    final DomainEventPublisherPort publisher = events::add;

    WeeklyLoadService weeklyLoadService() {
        return new WeeklyLoadService(loads, blocks, focus, deadlines, directory, xp, xp, ZONE);
    }

    /** Plan semanal con el reloj de {@link #NOW} (lunes de la semana de prueba). */
    StudyPlanService studyPlanService() {
        return new StudyPlanService(plans, blocks, deadlines, xp, xp, ZONE, CLOCK);
    }

    /** Minutos máximos de estudio por bloque que devuelve la regulación cruzada simulada. */
    int crossRegulationMaxStudyMinutes = 90;

    /** Regulación cruzada simulada (indicadores): solo importa su tope de minutos de estudio. */
    final GetCrossRegulationUseCase crossRegulation = (userId, tz) -> {
        CrossRegulationState state = new CrossRegulationState(userId, 0, 0, crossRegulationMaxStudyMinutes, null, NOW);
        return new CrossRegulationView(state, null, AcwrZone.NO_DATA, 0, 1);
    };

    /** Instante local de Madrid del lunes de la semana de prueba + días. */
    static Instant at(int dayOffset, int hour, int minute) {
        return ZONE.at(MONDAY.plusDays(dayOffset), java.time.LocalTime.of(hour, minute));
    }

    // ------------------------------------------------------------------ bloques

    static final class Blocks implements CalendarBlockRepositoryPort {
        final Map<UUID, CalendarBlock> store = new LinkedHashMap<>();

        public CalendarBlock save(CalendarBlock block) {
            store.put(block.id(), block);
            return block;
        }

        public List<CalendarBlock> saveAll(List<CalendarBlock> list) {
            list.forEach(this::save);
            return List.copyOf(list);
        }

        public Optional<CalendarBlock> findById(UUID id) {
            return Optional.ofNullable(store.get(id));
        }

        public Optional<CalendarBlock> findByIdForUpdate(UUID id) {
            return findById(id);
        }

        public void delete(UUID id) {
            store.remove(id);
        }

        public List<CalendarBlock> findOverlapping(UUID userId, Instant from, Instant to, UUID subjectId) {
            return store.values().stream()
                    .filter(b -> b.userId().equals(userId) && b.start().isBefore(to) && b.end().isAfter(from))
                    .filter(b -> subjectId == null || subjectId.equals(b.subjectId()))
                    .sorted(Comparator.comparing(CalendarBlock::start))
                    .toList();
        }

        public Map<String, CalendarBlock> findByIcsUids(UUID userId, Collection<String> icsUids) {
            Set<String> wanted = new HashSet<>(icsUids);
            return store.values().stream()
                    .filter(b -> b.userId().equals(userId) && b.icsUid() != null && wanted.contains(b.icsUid()))
                    .collect(Collectors.toMap(CalendarBlock::icsUid, b -> b, (a, b) -> a));
        }

        public List<CalendarBlock> findClassesToAttend(Instant from, Instant to) {
            return store.values().stream().filter(b -> b.type() == ActivityType.CLASS && !b.completed()
                            && !b.absent() && !b.end().isBefore(from) && b.end().isBefore(to))
                    .sorted(Comparator.comparing(CalendarBlock::end)).toList();
        }

        public List<CalendarBlock> findPendingReviews(UUID userId, UUID materialId) {
            return store.values().stream().filter(b -> b.userId().equals(userId)
                            && materialId.equals(b.studyMaterialId()) && !b.completed())
                    .sorted(Comparator.comparing(CalendarBlock::start)).toList();
        }

        public List<CalendarBlock> findBySubject(UUID userId, UUID subjectId) {
            return store.values().stream()
                    .filter(b -> b.userId().equals(userId) && subjectId.equals(b.subjectId())).toList();
        }

        public List<CalendarBlock> findByRoutine(UUID userId, UUID routineId) {
            return store.values().stream()
                    .filter(b -> b.userId().equals(userId) && routineId.equals(b.details().routineId()))
                    .sorted(Comparator.comparing(CalendarBlock::start)).toList();
        }

        public List<CalendarBlock> findByRoutineDays(UUID userId, java.util.Collection<UUID> dayIds) {
            return store.values().stream()
                    .filter(b -> b.userId().equals(userId) && dayIds.contains(b.details().routineDayId()))
                    .sorted(Comparator.comparing(CalendarBlock::start)).toList();
        }
    }

    // ------------------------------------------------------------------ entregas

    static final class Deadlines implements DeadlineRepositoryPort {
        final Map<UUID, Deadline> store = new LinkedHashMap<>();

        public Deadline save(Deadline d) {
            store.put(d.id(), d);
            return d;
        }

        public Optional<Deadline> findById(UUID id) {
            return Optional.ofNullable(store.get(id));
        }

        public void delete(UUID id) {
            store.remove(id);
        }

        public PageResult<Deadline> find(UUID userId, Query query, PageRequest page) {
            List<Deadline> all = findAll(userId, query);
            List<Deadline> slice = all.stream().skip(page.offset()).limit(page.size()).toList();
            return new PageResult<>(slice, page.page(), page.size(), all.size());
        }

        public List<Deadline> findAll(UUID userId, Query q) {
            return store.values().stream()
                    .filter(d -> d.userId().equals(userId))
                    .filter(d -> q.from() == null || !d.dueAt().isBefore(q.from()))
                    .filter(d -> q.to() == null || d.dueAt().isBefore(q.to()))
                    .filter(d -> q.subjectId() == null || q.subjectId().equals(d.subjectId()))
                    .filter(d -> !q.pendingOnly() || !d.completed())
                    .sorted(Comparator.comparing(Deadline::dueAt))
                    .toList();
        }

        public Map<String, Deadline> findByIcsUids(UUID userId, Collection<String> icsUids) {
            Set<String> wanted = new HashSet<>(icsUids);
            return store.values().stream()
                    .filter(d -> d.userId().equals(userId) && d.icsUid() != null && wanted.contains(d.icsUid()))
                    .collect(Collectors.toMap(Deadline::icsUid, d -> d, (a, b) -> a));
        }
    }

    // ------------------------------------------------------------------ planes, carga y pomodoro

    static final class Plans implements StudyPlanRepositoryPort {
        final Map<UUID, StudyPlan> store = new LinkedHashMap<>();

        public StudyPlan save(StudyPlan p) {
            store.put(p.id(), p);
            return p;
        }

        public Optional<StudyPlan> findById(UUID id) {
            return Optional.ofNullable(store.get(id));
        }

        public StudyPlan saveIfAbsent(StudyPlan p) {
            return findByUserAndWeek(p.userId(), p.weekStart()).orElseGet(() -> save(p));
        }

        public boolean markExperienceAwarded(UUID id, int points) {
            StudyPlan plan = store.get(id);
            if (plan == null || plan.xpAwarded()) {
                return false;
            }
            plan.markExperienceAwarded(points);
            return true;
        }

        public Optional<StudyPlan> findByUserAndWeek(UUID userId, LocalDate weekStart) {
            return store.values().stream()
                    .filter(p -> p.userId().equals(userId) && p.weekStart().equals(weekStart)).findFirst();
        }

        public PageResult<StudyPlan> findByUser(UUID userId, PageRequest page) {
            List<StudyPlan> all = store.values().stream().filter(p -> p.userId().equals(userId)).toList();
            return new PageResult<>(all, page.page(), page.size(), all.size());
        }

        public List<StudyPlan> findNonPrivateByUser(UUID userId) {
            return store.values().stream()
                    .filter(p -> p.userId().equals(userId) && p.visibility() != Visibility.PRIVATE).toList();
        }

        public void delete(UUID id) {
            store.remove(id);
        }
    }

    static final class Loads implements WeeklyLoadRepositoryPort {
        final Map<UUID, WeeklyAcademicLoad> store = new LinkedHashMap<>();

        public WeeklyAcademicLoad save(WeeklyAcademicLoad l) {
            store.put(l.id(), l);
            return l;
        }

        public Optional<WeeklyAcademicLoad> findByUserAndWeek(UUID userId, LocalDate weekStart) {
            return store.values().stream()
                    .filter(l -> l.userId().equals(userId) && l.weekStart().equals(weekStart)).findFirst();
        }

        public List<WeeklyAcademicLoad> findByUserBetween(UUID userId, LocalDate from, LocalDate to) {
            return store.values().stream().filter(l -> l.userId().equals(userId)
                    && !l.weekStart().isBefore(from) && !l.weekStart().isAfter(to)).toList();
        }
    }

    static final class Focus implements FocusSessionRepositoryPort {
        final List<FocusSession> store = new ArrayList<>();

        public FocusSession save(FocusSession s) {
            store.add(s);
            return s;
        }

        public int sumXpAwarded(UUID userId, LocalDate date) {
            return store.stream().filter(s -> s.userId().equals(userId) && s.date().equals(date))
                    .mapToInt(FocusSession::xpAwarded).sum();
        }

        public List<FocusSession> findByUserBetween(UUID userId, LocalDate from, LocalDate to) {
            return store.stream().filter(s -> s.userId().equals(userId)
                    && !s.date().isBefore(from) && !s.date().isAfter(to)).toList();
        }
    }

    // ------------------------------------------------------------------ lecturas de otros módulos

    static final class Directory implements SubjectDirectoryPort, PlannerProfilePort, RoutineDirectoryPort,
            ChallengeDirectoryPort {
        final Map<UUID, Map<UUID, SubjectRef>> subjects = new HashMap<>();
        final Map<UUID, PlannerProfile.Metabolic> metabolic = new HashMap<>();
        final Map<UUID, PlannerProfile.Academic> academic = new HashMap<>();
        final Map<UUID, Map<UUID, RoutineRef>> routines = new HashMap<>();
        final Map<UUID, Set<UUID>> challenges = new HashMap<>();

        SubjectRef addSubject(UUID userId, String name, String code, int difficulty) {
            SubjectRef s = new SubjectRef(UUID.randomUUID(), name, code, difficulty, 6, null);
            subjects.computeIfAbsent(userId, k -> new LinkedHashMap<>()).put(s.id(), s);
            return s;
        }

        void addSubject(UUID userId, SubjectRef s) {
            subjects.computeIfAbsent(userId, k -> new LinkedHashMap<>()).put(s.id(), s);
        }

        public Optional<SubjectRef> findOwned(UUID userId, UUID subjectId) {
            return Optional.ofNullable(subjects.getOrDefault(userId, Map.of()).get(subjectId));
        }

        public List<SubjectRef> findActive(UUID userId) {
            return List.copyOf(subjects.getOrDefault(userId, Map.of()).values());
        }

        public Map<UUID, String> namesOf(UUID userId, Collection<UUID> ids) {
            Map<UUID, String> names = new HashMap<>();
            subjects.getOrDefault(userId, Map.of()).values().stream().filter(s -> ids.contains(s.id()))
                    .forEach(s -> names.put(s.id(), s.name()));
            return names;
        }

        public Optional<PlannerProfile.Metabolic> findMetabolic(UUID userId) {
            return Optional.ofNullable(metabolic.get(userId));
        }

        public Optional<PlannerProfile.Academic> findAcademic(UUID userId) {
            return Optional.ofNullable(academic.get(userId));
        }

        public Optional<RoutineRef> findOwnedWithDays(UUID userId, UUID routineId) {
            return Optional.ofNullable(routines.getOrDefault(userId, Map.of()).get(routineId));
        }

        public List<RoutineRef> findActive(UUID userId, int limit) {
            return routines.getOrDefault(userId, Map.of()).values().stream().limit(limit).toList();
        }

        /** Periodo de los retos dados de alta (por defecto, muy amplio) y reto de cada tarea. */
        final Map<UUID, com.synaptixfit.domain.model.planner.ChallengeRef> challengePeriods = new HashMap<>();
        final Map<UUID, UUID> milestoneChallenge = new HashMap<>();

        public Optional<com.synaptixfit.domain.model.planner.ChallengeRef> findOwnedChallenge(UUID userId,
                                                                                            UUID challengeId) {
            if (!challenges.getOrDefault(userId, Set.of()).contains(challengeId)) {
                return Optional.empty();
            }
            return Optional.of(challengePeriods.getOrDefault(challengeId, new com.synaptixfit.domain.model.planner
                    .ChallengeRef(challengeId, java.time.Instant.parse("2000-01-01T00:00:00Z"),
                    java.time.Instant.parse("2100-01-01T00:00:00Z"))));
        }

        public Optional<UUID> findMilestoneChallenge(UUID userId, UUID milestoneId) {
            if (!challenges.getOrDefault(userId, Set.of()).contains(milestoneId)) {
                return Optional.empty();
            }
            return Optional.of(milestoneChallenge.getOrDefault(milestoneId, milestoneId));
        }
    }

    // ------------------------------------------------------------------ experiencia

    static final class Xp implements AwardExperienceUseCase, RevokeExperienceUseCase {
        final Map<UUID, Integer> balance = new HashMap<>();

        int of(UUID userId) {
            return balance.getOrDefault(userId, 0);
        }

        public ExperienceChange award(UUID userId, int amount) {
            balance.merge(userId, amount, Integer::sum);
            return new ExperienceChange(1, of(userId), 0, amount);
        }

        public ExperienceChange revoke(UUID userId, int amount) {
            balance.merge(userId, -amount, Integer::sum);
            return new ExperienceChange(1, of(userId), 0, -amount);
        }
    }
}
