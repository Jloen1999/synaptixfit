package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.insights.GetCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.training.GenerateRoutineProposalUseCase;
import com.synaptixfit.application.port.input.training.RefineRoutineProposalUseCase;
import com.synaptixfit.domain.exception.ExternalServiceException;
import com.synaptixfit.domain.exception.training.NoCompatibleExercisesException;
import com.synaptixfit.domain.exception.training.RoutineWeekLimitException;
import com.synaptixfit.domain.exception.training.TrainingProfileRequiredException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.generation.AcademicContext;
import com.synaptixfit.domain.model.training.generation.CandidateCatalog;
import com.synaptixfit.domain.model.training.generation.ContextAdjuster;
import com.synaptixfit.domain.model.training.generation.GoalParameters;
import com.synaptixfit.domain.model.training.generation.GoalTransition;
import com.synaptixfit.domain.model.training.generation.Periodization;
import com.synaptixfit.domain.model.training.generation.PhysiologicalContext;
import com.synaptixfit.domain.model.training.generation.ProgressionCalculator;
import com.synaptixfit.domain.model.training.generation.ProposalRepair;
import com.synaptixfit.domain.model.training.generation.RoutineNaming;
import com.synaptixfit.domain.model.training.generation.RoutineProposal;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedDay;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedExercise;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedWeek;
import com.synaptixfit.domain.model.training.generation.RoutineRefinement;
import com.synaptixfit.domain.model.training.generation.RoutineRefinementRequest;
import com.synaptixfit.domain.model.training.generation.RoutineRuleEngine;
import com.synaptixfit.domain.model.training.generation.TrainingHistory;
import com.synaptixfit.domain.model.training.generation.TrainingProfile;
import com.synaptixfit.domain.port.output.training.DailyCheckInRepositoryPort;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineGeneratorPort;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Orquestador de la generación de rutinas (réplica del pipeline heredado, corregido):
 * <ol>
 *   <li>Contexto: perfil, catálogo activo, historial, check-in de hoy, situación académica y física.</li>
 *   <li>Reglas deterministas por objetivo y modalidad → semana tipo.</li>
 *   <li>Ajustes de contexto (regulación cruzada, FCT, energía, ACWR…) y filtro por check-in.</li>
 *   <li>Transición de objetivo y sobrecarga progresiva / degradación por inactividad.</li>
 *   <li>IA opcional (catálogo de 60 candidatos, modo JSON) con validación y reparación de su salida,
 *       saneado del nombre y preservación de parámetros. Si falla, se usa la propuesta de reglas.</li>
 *   <li>Periodización a todas las semanas.</li>
 * </ol>
 * El resultado es una propuesta que no se guarda.
 */
public class RoutineGenerationService implements GenerateRoutineProposalUseCase, RefineRoutineProposalUseCase {

    static final String AI_FALLBACK_NOTICE = "IA no disponible: se usa la rutina generada por reglas";
    private static final int HISTORY_SESSIONS = 30;

    private final TrainingContextPort context;
    private final ExerciseRepositoryPort exercises;
    private final TrainingSessionRepositoryPort sessions;
    private final DailyCheckInRepositoryPort checkIns;
    private final RoutineGeneratorPort generator;
    private final GetCognitiveStateUseCase cognitiveState;
    private final GetCrossRegulationUseCase crossRegulation;
    private final Clock clock;
    private final ZoneId zone;

    /**
     * @param cognitiveState  carga cognitiva de hoy recalculada (la columna guardada puede ser de otro día)
     * @param crossRegulation ACWR con las ventanas desplazadas a hoy, por el mismo motivo
     */
    public RoutineGenerationService(TrainingContextPort context, ExerciseRepositoryPort exercises,
                                    TrainingSessionRepositoryPort sessions, DailyCheckInRepositoryPort checkIns,
                                    RoutineGeneratorPort generator, GetCognitiveStateUseCase cognitiveState,
                                    GetCrossRegulationUseCase crossRegulation, Clock clock, ZoneId zone) {
        this.context = context;
        this.exercises = exercises;
        this.sessions = sessions;
        this.checkIns = checkIns;
        this.generator = generator;
        this.cognitiveState = cognitiveState;
        this.crossRegulation = crossRegulation;
        this.clock = clock;
        this.zone = zone;
    }

    private record Inputs(TrainingProfile profile, List<Exercise> catalog, Map<UUID, Exercise> catalogById,
                          DailyCheckIn checkIn, TrainingHistory history, AcademicContext academic,
                          PhysiologicalContext physio, LocalDate today) {
    }

    @Override
    public RoutineProposal generate(Command c) {
        int weeks = Guard.range(c.durationWeeks(), "durationWeeks", 1, 12);
        Inputs in = gather(c.userId(), c.goal());
        TrainingGoal goal = in.profile().goal();

        GoalTransition.Transition transition = context.latestGoalChange(c.userId())
                .filter(change -> change.current() == goal && change.previous() != null)
                .map(change -> GoalTransition.compute(goal, change.previous(),
                        (int) (ChronoUnit.DAYS.between(change.since(), in.today()) / 7)))
                .orElse(new GoalTransition.Transition(GoalParameters.of(goal), 1.0, null));
        GoalParameters params = transition.parameters();

        RoutineRuleEngine.WeekTemplate template = RoutineRuleEngine.generate(in.profile(), in.catalog(), params,
                in.history());
        if (template.exerciseCount() == 0) {
            throw new NoCompatibleExercisesException();
        }
        ContextAdjuster.Adjustment adjustment = ContextAdjuster.compute(in.academic(), in.physio(), in.checkIn());
        List<ProposedDay> days = ContextAdjuster.apply(template.days(), adjustment, template.parameters());
        days = ContextAdjuster.filterByCheckIn(days, in.checkIn(), in.catalog());
        days = GoalTransition.apply(days, transition);
        days = progress(days, in, template.parameters());

        List<String> reasons = new ArrayList<>(adjustment.reasons());
        if (transition.reason() != null) {
            reasons.add(transition.reason());
        }
        String split = template.split().label();
        String baseName = RoutineNaming.baseName(goal, split, weeks);
        String baseDescription = RoutineNaming.baseDescription(goal, split, in.profile().daysPerWeek(),
                in.profile().equipment(), reasons);
        RoutineProposal base = new RoutineProposal(baseName, baseDescription, goal,
                Periodization.expand(days, weeks, in.history().requiresDeload()), split, reasons,
                adjustment.totalLoadFactor(), false, null);
        if (!c.useAi()) {
            return base;
        }
        try {
            RoutineRefinement refinement = generator.refine(new RoutineRefinementRequest(in.profile(), goal, weeks,
                    baseName, baseDescription, days, CandidateCatalog.top(in.catalog(), in.profile(), goal),
                    exercisesOf(days, in.catalogById()), in.academic(), in.checkIn(), in.history(), reasons));
            List<ProposedDay> repaired = ProposalRepair.repair(days, refinement.days(), in.catalogById(), in.profile());
            List<ProposedWeek> expanded = Periodization.expand(repaired, weeks, in.history().requiresDeload());
            return base.withAiResult(RoutineNaming.sanitize(refinement.name(), weeks, baseName),
                    description(refinement, baseDescription), applyNames(expanded, refinement));
        } catch (ExternalServiceException e) {
            return base.withAiNotice(AI_FALLBACK_NOTICE);
        }
    }

    @Override
    public RoutineProposal refine(UUID userId, RoutineProposal proposal) {
        if (proposal == null || proposal.weeks().isEmpty()) {
            throw new RoutineWeekLimitException();
        }
        Inputs in = gather(userId, proposal.goal());
        List<ProposedDay> template = proposal.weeks().getFirst().days();
        int weeks = proposal.durationWeeks();
        try {
            RoutineRefinement refinement = generator.refine(new RoutineRefinementRequest(in.profile(), proposal.goal(),
                    weeks, proposal.name(), proposal.description(), template,
                    CandidateCatalog.top(in.catalog(), in.profile(), proposal.goal()),
                    exercisesOf(template, in.catalogById()), in.academic(), in.checkIn(), in.history(),
                    proposal.adjustmentReasons()));
            List<ProposedDay> repaired = ProposalRepair.repair(template, refinement.days(), in.catalogById(), in.profile());
            List<ProposedWeek> refinedWeeks = new ArrayList<>();
            for (ProposedWeek week : proposal.weeks()) {
                refinedWeeks.add(week.number() == proposal.weeks().getFirst().number()
                        ? week.withDays(repaired) : week.withDays(substitute(week.days(), template, repaired)));
            }
            return proposal.withAiResult(RoutineNaming.sanitize(refinement.name(), weeks, proposal.name()),
                    description(refinement, proposal.description()), applyNames(refinedWeeks, refinement));
        } catch (ExternalServiceException e) {
            return proposal.withAiNotice(AI_FALLBACK_NOTICE);
        }
    }

    // ------------------------------------------------------------------ pasos

    private Inputs gather(UUID userId, TrainingGoal goalOverride) {
        TrainingProfile stored = context.profile(userId).orElseThrow(TrainingProfileRequiredException::new);
        TrainingProfile profile = goalOverride == null ? stored : new TrainingProfile(stored.age(), stored.sex(),
                stored.weightKg(), stored.heightCm(), stored.bmi(), stored.activityLevel(), goalOverride,
                stored.equipment(), stored.daysPerWeek(), stored.minutesPerSession(), stored.availableDays());
        List<Exercise> catalog = exercises.findAllActive();
        if (catalog.isEmpty()) {
            throw new NoCompatibleExercisesException();
        }
        LocalDate today = LocalDate.ofInstant(clock.instant(), zone);
        DailyCheckIn checkIn = checkIns.findByUserAndDate(userId, today).orElse(null);
        TrainingHistory history = TrainingHistory.from(sessions.recentCompleted(userId, HISTORY_SESSIONS), today,
                zone, checkIn == null ? null : checkIn.fatigueScore());
        AcademicContext academic = context.academicContext(userId, today).withInsights(
                cognitiveState.getCognitiveState(userId, zone.getId()).cognitiveLoad(),
                crossRegulation.getCrossRegulation(userId, zone.getId()).acwr());
        return new Inputs(profile, catalog,
                catalog.stream().collect(Collectors.toMap(Exercise::id, Function.identity(), (a, b) -> a)),
                checkIn, history, academic, context.physiologicalContext(userId, today), today);
    }

    /** Degradación si lleva más de 14 días sin entrenar; si no, progresión con el último registro de cada ejercicio. */
    private static List<ProposedDay> progress(List<ProposedDay> days, Inputs in, GoalParameters params) {
        Integer inactive = in.history().daysSinceLastSession();
        return days.stream().map(d -> d.mapExercises(e -> {
            Exercise exercise = in.catalogById().get(e.exerciseId());
            if (exercise == null) {
                return e;
            }
            if (inactive != null && inactive > ProgressionCalculator.INACTIVITY_DAYS) {
                return e.withParameters(ProgressionCalculator.degradeForInactivity(e.parameters(),
                        exercise.measurementTypes(), inactive, params).parameters());
            }
            TrainingHistory.ExercisePerformance perf = in.history().performances().get(e.exerciseId());
            if (perf == null) {
                return e;
            }
            return e.withParameters(ProgressionCalculator.progress(e.parameters(), exercise.measurementTypes(),
                    perf.rpe(), perf.lastSets(), params).parameters());
        })).toList();
    }

    private static Map<UUID, Exercise> exercisesOf(List<ProposedDay> days, Map<UUID, Exercise> catalogById) {
        Map<UUID, Exercise> result = new HashMap<>();
        days.stream().flatMap(d -> d.exercises().stream()).map(ProposedExercise::exerciseId)
                .forEach(id -> Optional.ofNullable(catalogById.get(id)).ifPresent(e -> result.put(id, e)));
        return result;
    }

    /** En las demás semanas sustituye el ejercicio cuando coincidía con el de la semana base en la misma posición. */
    private static List<ProposedDay> substitute(List<ProposedDay> days, List<ProposedDay> original,
                                                List<ProposedDay> repaired) {
        return days.stream().map(day -> {
            Optional<ProposedDay> before = original.stream().filter(o -> o.dayNumber() == day.dayNumber()).findFirst();
            Optional<ProposedDay> after = repaired.stream().filter(o -> o.dayNumber() == day.dayNumber()).findFirst();
            if (before.isEmpty() || after.isEmpty()) {
                return day;
            }
            List<ProposedExercise> list = new ArrayList<>();
            for (int i = 0; i < day.exercises().size(); i++) {
                ProposedExercise e = day.exercises().get(i);
                if (i < before.get().exercises().size() && i < after.get().exercises().size()
                        && e.exerciseId().equals(before.get().exercises().get(i).exerciseId())) {
                    ProposedExercise replacement = after.get().exercises().get(i);
                    list.add(new ProposedExercise(replacement.exerciseId(), replacement.exerciseName(), e.parameters()));
                } else {
                    list.add(e);
                }
            }
            return day.withExercises(list);
        }).toList();
    }

    private static List<ProposedWeek> applyNames(List<ProposedWeek> weeks, RoutineRefinement refinement) {
        return weeks.stream().map(w -> {
            String weekName = clean(refinement.weekNames().get(w.number()));
            Map<Integer, String> names = refinement.dayNames().getOrDefault(w.number(),
                    refinement.dayNames().getOrDefault(1, Map.of()));
            List<ProposedDay> days = w.days().stream().map(d -> {
                String dayName = clean(names.get(d.dayNumber()));
                return dayName == null ? d : d.withName(dayName);
            }).toList();
            ProposedWeek named = weekName == null ? w : w.withName(weekName);
            return named.withDays(days);
        }).toList();
    }

    private static String description(RoutineRefinement refinement, String fallback) {
        String d = clean2000(refinement.description());
        return d == null ? fallback : d;
    }

    private static String clean(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String v = value.strip();
        return v.length() > 120 ? v.substring(0, 120).strip() : v;
    }

    private static String clean2000(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String v = value.strip();
        return v.length() > 2000 ? v.substring(0, 2000) : v;
    }
}
