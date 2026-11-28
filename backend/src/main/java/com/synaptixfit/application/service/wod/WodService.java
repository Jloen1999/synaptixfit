package com.synaptixfit.application.service.wod;

import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.port.input.wod.CreateWodUseCase;
import com.synaptixfit.application.port.input.wod.DeleteWodUseCase;
import com.synaptixfit.application.port.input.wod.GetWodBoardUseCase;
import com.synaptixfit.application.port.input.wod.ListWodMarksUseCase;
import com.synaptixfit.application.port.input.wod.ListWodTemplatesUseCase;
import com.synaptixfit.application.port.input.wod.SaveWodResultUseCase;
import com.synaptixfit.application.port.input.wod.UpdateWodUseCase;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.wod.WodNotFoundException;
import com.synaptixfit.domain.model.planner.ActivitySource;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.PastActivity;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.Sport;
import com.synaptixfit.domain.model.planner.SportDetails;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.wod.Wod;
import com.synaptixfit.domain.model.wod.WodBoard;
import com.synaptixfit.domain.model.wod.WodDefinition;
import com.synaptixfit.domain.model.wod.WodDivision;
import com.synaptixfit.domain.model.wod.WodFormat;
import com.synaptixfit.domain.model.wod.WodMark;
import com.synaptixfit.domain.model.wod.WodResult;
import com.synaptixfit.domain.model.wod.WodScoreType;
import com.synaptixfit.domain.model.wod.WodTemplates;
import com.synaptixfit.domain.port.output.wod.WodRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Implementa los WOD (ADR 0069): plantillas, la pizarra de hoy, crear, cambiar, borrar, guardar una marca y «Mis
 * marcas». Guardar una marca apunta la actividad con {@link LogPastActivityUseCase} (el contrato del planificador),
 * así la racha, la XP, la carga y los retos no tienen reglas aparte.
 */
public class WodService implements ListWodTemplatesUseCase, GetWodBoardUseCase, CreateWodUseCase, UpdateWodUseCase,
        DeleteWodUseCase, SaveWodResultUseCase, ListWodMarksUseCase {

    /** Un WOD se hace fuerte: si no se dice el esfuerzo, cuenta como 7 de 10 para la carga física. */
    static final int DEFAULT_EFFORT = 7;
    /** Sin cronómetro ni límite de tiempo, la actividad cuenta 10 minutos. */
    static final int DEFAULT_SECONDS = 600;
    static final int MAX_DURATION_SECONDS = PastActivity.MAX_MINUTES * 60;
    static final String DEFAULT_TITLE = "WOD";

    private final WodRepositoryPort wods;
    private final LogPastActivityUseCase logActivity;
    private final PlannerZone zone;
    private final Clock clock;

    public WodService(WodRepositoryPort wods, LogPastActivityUseCase logActivity, PlannerZone zone, Clock clock) {
        this.wods = wods;
        this.logActivity = logActivity;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public List<WodTemplates.Template> listTemplates() {
        return WodTemplates.ALL;
    }

    @Override
    public WodBoard board(UUID userId, String templateCode) {
        LocalDate today = zone.today(clock.instant());
        List<WodMark> marks = wods.findMarks(userId);
        boolean asked = templateCode != null && !templateCode.isBlank();
        Wod mine = asked ? null : wods.findOfDay(userId, today).orElse(null);
        if (mine != null) {
            WodResult todayResult = marks.stream().map(WodMark::result)
                    .filter(r -> r.wodId().equals(mine.id()) && zone.localDate(r.performedAt()).equals(today))
                    .findFirst().orElse(null);
            String signature = mine.definition().signature();
            return new WodBoard(mine.id(), mine.date(), mine.templateCode(), mine.definition(), false,
                    best(marks, signature, WodDivision.RX), best(marks, signature, WodDivision.SCALED), todayResult);
        }
        WodTemplates.Template template = asked ? template(templateCode) : WodTemplates.ofDay(today);
        String signature = template.definition().signature();
        return new WodBoard(null, today, template.code(), template.definition(), true,
                best(marks, signature, WodDivision.RX), best(marks, signature, WodDivision.SCALED), null);
    }

    @Override
    public Wod createWod(CreateWodUseCase.Command command) {
        return wods.save(newWod(command.userId(), command.date(), command.templateCode(), command.definition()));
    }

    @Override
    public Wod updateWod(UpdateWodUseCase.Command command) {
        Wod current = owned(command.userId(), command.wodId());
        return wods.save(current.changed(command.date(), Guard.notNull(command.definition(), "definition"),
                clock.instant()));
    }

    @Override
    public void deleteWod(UUID userId, UUID wodId) {
        wods.delete(userId, owned(userId, wodId).id());
    }

    @Override
    public WodMark saveResult(SaveWodResultUseCase.Command command) {
        Instant now = clock.instant();
        Wod wod = command.wodId() != null ? owned(command.userId(), command.wodId())
                : wods.save(newWod(command.userId(), null, command.templateCode(), command.definition()));
        WodDefinition definition = wod.definition();
        if (command.capped() && definition.format() != WodFormat.FOR_TIME) {
            throw new FieldValidationException("capped", "INVALID", "only a for-time WOD can hit its time cap");
        }
        WodScoreType expected = definition.format().scoreType(command.capped());
        WodScoreType scoreType = command.scoreType() == null ? expected : command.scoreType();
        if (scoreType != expected && scoreType != WodScoreType.LOAD) {
            throw new FieldValidationException("scoreType", "INVALID", "this WOD is scored as " + expected);
        }
        Integer cap = definition.timeCapSeconds();
        if (scoreType == WodScoreType.TIME && cap != null && command.value() > cap) {
            throw new FieldValidationException("value", "OUT_OF_RANGE", "the time is over the time cap");
        }
        int seconds = durationSeconds(command, scoreType, cap);
        // La actividad dura al menos lo que admite el planificador (10 min) y acaba ahora.
        int minutes = Math.clamp((int) Math.ceil(seconds / 60.0), PastActivity.MIN_SPORT_MINUTES,
                PastActivity.MAX_MINUTES);
        String title = definition.title() == null ? DEFAULT_TITLE : definition.title();
        int effort = command.effort() == null ? DEFAULT_EFFORT : command.effort();
        // Primero se valida la marca: si no vale, no queda una actividad apuntada sin ella.
        WodResult draft = new WodResult(UUID.randomUUID(), wod.id(), command.userId(), command.division(), scoreType,
                command.value(), command.extraReps(), command.capped(), seconds, null, now);
        SetBlockCompletionUseCase.Result logged = logActivity.logPastActivity(new LogPastActivityUseCase.Command(
                command.userId(), now.minus(Duration.ofMinutes(minutes)), minutes, title, effort, ActivityType.SPORT,
                null, null, null, ActivitySource.MANUAL, null, null, SportDetails.of(Sport.WOD)));
        WodResult result = wods.saveResult(new WodResult(draft.id(), draft.wodId(), draft.userId(), draft.division(),
                draft.scoreType(), draft.value(), draft.extraReps(), draft.capped(), draft.durationSeconds(),
                logged.block().id(), now));
        return listMarks(command.userId()).stream().filter(m -> m.result().id().equals(result.id())).findFirst()
                .orElseGet(() -> new WodMark(result, definition.signature(), definition.title(), wod.templateCode(),
                        definition.format(), false));
    }

    @Override
    public List<WodMark> listMarks(UUID userId) {
        List<WodMark> marks = wods.findMarks(userId);
        Set<UUID> bestIds = new HashSet<>();
        marks.stream()
                .collect(Collectors.groupingBy(m -> m.signature() + "|" + m.result().division(),
                        Collectors.mapping(WodMark::result, Collectors.toList())))
                .values().forEach(group -> WodResult.best(group).ifPresent(r -> bestIds.add(r.id())));
        return marks.stream().map(m -> m.asBest(bestIds.contains(m.result().id()))).toList();
    }

    private int durationSeconds(SaveWodResultUseCase.Command command, WodScoreType scoreType, Integer cap) {
        if (command.durationSeconds() != null) {
            return Guard.range(command.durationSeconds(), "durationSeconds", 1, MAX_DURATION_SECONDS);
        }
        if (scoreType == WodScoreType.TIME) {
            return Math.clamp(command.value(), 1, MAX_DURATION_SECONDS);
        }
        return cap != null ? cap : DEFAULT_SECONDS;
    }

    private Wod newWod(UUID userId, LocalDate date, String templateCode, WodDefinition definition) {
        Guard.notNull(definition, "wod");
        String code = templateCode == null || templateCode.isBlank() ? null : template(templateCode).code();
        Instant now = clock.instant();
        return new Wod(UUID.randomUUID(), userId, date == null ? zone.today(now) : date, code, definition, now, now);
    }

    private static WodTemplates.Template template(String code) {
        return WodTemplates.find(code).orElseThrow(
                () -> new FieldValidationException("templateCode", "INVALID", "unknown WOD template"));
    }

    private static WodResult best(List<WodMark> marks, String signature, WodDivision division) {
        return WodResult.best(marks.stream()
                .filter(m -> m.signature().equals(signature) && m.result().division() == division)
                .map(WodMark::result).toList()).orElse(null);
    }

    private Wod owned(UUID userId, UUID wodId) {
        return wods.findOwned(userId, wodId).orElseThrow(() -> new WodNotFoundException(wodId));
    }
}
