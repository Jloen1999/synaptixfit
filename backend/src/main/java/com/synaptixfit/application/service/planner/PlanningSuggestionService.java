package com.synaptixfit.application.service.planner;

import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.port.output.user.UsageFocusPort;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.planner.SuggestWeekPlanUseCase;
import com.synaptixfit.domain.exception.ExternalServiceException;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.PlanningInbox;
import com.synaptixfit.domain.model.planner.SuggestedBlock;
import com.synaptixfit.domain.model.planner.WeekPlanSuggestions;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.PlanningAssistantPort;
import com.synaptixfit.domain.port.output.planner.RoutineDirectoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Sugerencias de planificación semanal: IA (reglas N1-N10 y H1-H5 en el prompt) con saneado de la
 * respuesta y plan heurístico de respaldo si la IA falla o no propone nada válido. La duración máxima
 * de un bloque de estudio es la menor entre la pedida y la que permite la regulación cruzada.
 */
public class PlanningSuggestionService implements SuggestWeekPlanUseCase {

    private static final int ACTIVE_ROUTINES = 5;

    private final PlanningAssistantPort assistant;
    private final SubjectDirectoryPort subjects;
    private final DeadlineRepositoryPort deadlines;
    private final RoutineDirectoryPort routines;
    private final CalendarBlockRepositoryPort blocks;
    private final GetCrossRegulationUseCase crossRegulation;
    private final PlannerZone zone;
    private final Clock clock;
    private final UsageFocusPort focus;

    public PlanningSuggestionService(PlanningAssistantPort assistant, SubjectDirectoryPort subjects,
                                     DeadlineRepositoryPort deadlines, RoutineDirectoryPort routines,
                                     CalendarBlockRepositoryPort blocks, GetCrossRegulationUseCase crossRegulation,
                                     PlannerZone zone, Clock clock) {
        this(assistant, subjects, deadlines, routines, blocks, crossRegulation, zone, clock,
                userId -> UsageFocus.BOTH);
    }

    /**
     * @param crossRegulation regulación cruzada recalculada a hoy (tope de minutos por bloque según el ACWR)
     * @param focus           enfoque de uso: sin estudios no se proponen horas de estudio, y sin deporte
     *                        no se proponen sesiones
     */
    public PlanningSuggestionService(PlanningAssistantPort assistant, SubjectDirectoryPort subjects,
                                     DeadlineRepositoryPort deadlines, RoutineDirectoryPort routines,
                                     CalendarBlockRepositoryPort blocks, GetCrossRegulationUseCase crossRegulation,
                                     PlannerZone zone, Clock clock, UsageFocusPort focus) {
        this.focus = focus;
        this.assistant = assistant;
        this.subjects = subjects;
        this.deadlines = deadlines;
        this.routines = routines;
        this.blocks = blocks;
        this.crossRegulation = crossRegulation;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public WeekPlanSuggestions.Suggestion suggest(Command command) {
        Instant now = clock.instant();
        LocalDate monday = PlannerZone.mondayOf(command.weekStart() == null ? zone.today(now) : command.weekStart());
        Instant weekStart = zone.weekStart(monday);
        Instant weekEnd = zone.weekEnd(monday);
        Instant today = zone.startOfDay(zone.today(now));
        // La fatiga física manda sobre la preferencia del cliente: con el ACWR en riesgo, la regulación
        // cruzada recorta la duración máxima de un bloque de estudio (fórmula 3B).
        int maxStudyBlockMinutes = PlanningInbox.cappedStudyBlockMinutes(command.maxStudyBlockMinutes(),
                crossRegulation.getCrossRegulation(command.userId(), zone.zone().getId()).state().maxStudyMinutes());
        UsageFocus usage = focus.focusOf(command.userId());
        PlanningInbox inbox = new PlanningInbox(monday,
                usage.includesAcademic() ? command.studyHours() : 0,
                usage.includesFitness() ? command.sportSessions() : 0,
                command.minutesPerSportSession(), maxStudyBlockMinutes,
                subjects.findActive(command.userId()),
                deadlines.findAll(command.userId(), new DeadlineRepositoryPort.Query(
                        today.isAfter(weekStart) ? today : weekStart, weekEnd.plus(java.time.Duration.ofDays(7)),
                        null, true)),
                routines.findActive(command.userId(), ACTIVE_ROUTINES),
                blocks.findOverlapping(command.userId(), weekStart, weekEnd, null));
        try {
            List<SuggestedBlock> proposed = assistant.suggestWeek(inbox, zone);
            List<SuggestedBlock> valid = WeekPlanSuggestions.sanitize(proposed, inbox, zone, now);
            if (!valid.isEmpty()) {
                return new WeekPlanSuggestions.Suggestion(valid, WeekPlanSuggestions.Source.AI);
            }
        } catch (ExternalServiceException e) {
            // IA no disponible o sin cuota: se usa el plan heurístico, como en la app antigua.
        }
        return new WeekPlanSuggestions.Suggestion(WeekPlanSuggestions.heuristic(inbox, zone, now),
                WeekPlanSuggestions.Source.HEURISTIC);
    }
}
