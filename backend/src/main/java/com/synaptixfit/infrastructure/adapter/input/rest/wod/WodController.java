package com.synaptixfit.infrastructure.adapter.input.rest.wod;

import com.synaptixfit.application.port.input.wod.CreateWodUseCase;
import com.synaptixfit.application.port.input.wod.DeleteWodUseCase;
import com.synaptixfit.application.port.input.wod.GetWodBoardUseCase;
import com.synaptixfit.application.port.input.wod.ListWodMarksUseCase;
import com.synaptixfit.application.port.input.wod.ListWodTemplatesUseCase;
import com.synaptixfit.application.port.input.wod.SaveWodResultUseCase;
import com.synaptixfit.application.port.input.wod.UpdateWodUseCase;
import com.synaptixfit.domain.model.wod.Wod;
import com.synaptixfit.domain.model.wod.WodBoard;
import com.synaptixfit.domain.model.wod.WodDefinition;
import com.synaptixfit.domain.model.wod.WodDivision;
import com.synaptixfit.domain.model.wod.WodFormat;
import com.synaptixfit.domain.model.wod.WodMark;
import com.synaptixfit.domain.model.wod.WodMovement;
import com.synaptixfit.domain.model.wod.WodResult;
import com.synaptixfit.domain.model.wod.WodScoreType;
import com.synaptixfit.domain.model.wod.WodTemplates;
import com.synaptixfit.domain.model.wod.WodUnit;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * WOD (ADR 0069): plantillas de ejemplo, la pizarra de hoy, crear, cambiar y borrar mi WOD, guardar una marca y «Mis
 * marcas». La mejor marca de cada WOD y división la calcula el servidor.
 */
@Tag(name = "Training - WOD")
@RestController
@RequestMapping("/api/v1/training/wods")
public class WodController {

    /**
     * Un movimiento: {@code code} (de una plantilla; el cliente lo nombra) o {@code name}, cantidad (nula = «las que
     * puedas»), unidad ({@code REPS} por defecto) y kilos Rx y adaptado opcionales.
     */
    public record WodMovementDto(@Size(max = 30) String code, @Size(max = 60) String name,
                                 @Min(1) @Max(10000) Integer quantity, WodUnit unit, Double rxKg, Double scaledKg) {
        WodMovement toDomain() {
            return new WodMovement(code, name, quantity, unit, rxKg, scaledKg);
        }

        static WodMovementDto from(WodMovement m) {
            return new WodMovementDto(m.code(), m.name(), m.quantity(), m.unit(), m.rxKg(), m.scaledKg());
        }
    }

    /**
     * La pizarra: título y fuerza opcionales, formato, límite en segundos (obligatorio en AMRAP y EMOM; Tabata son
     * siempre 240), rondas (solo «por tiempo») y de 1 a 12 movimientos. {@code date} por defecto es hoy.
     */
    public record WodRequest(LocalDate date, @Size(max = 30) String templateCode, @Size(max = 80) String title,
                             @Size(max = 300) String strength, @NotNull WodFormat format, Integer timeCapSeconds,
                             Integer rounds, @NotNull @Size(min = 1, max = 12) List<@Valid WodMovementDto> movements) {
        WodDefinition definition() {
            return new WodDefinition(title, strength, format, timeCapSeconds, rounds,
                    movements.stream().map(WodMovementDto::toDomain).toList());
        }
    }

    /** Un WOD de la persona. */
    public record WodResponse(UUID id, LocalDate date, String templateCode, String title, String strength,
                              WodFormat format, Integer timeCapSeconds, Integer rounds,
                              List<WodMovementDto> movements) {
        static WodResponse from(Wod w) {
            WodDefinition d = w.definition();
            return new WodResponse(w.id(), w.date(), w.templateCode(), d.title(), d.strength(), d.format(),
                    d.timeCapSeconds(), d.rounds(), movementDtos(d));
        }
    }

    /** Plantilla de ejemplo: el cliente pone su nombre y el de cada movimiento a partir de los códigos. */
    public record WodTemplateResponse(String code, WodFormat format, Integer timeCapSeconds, Integer rounds,
                                      List<WodMovementDto> movements) {
        static WodTemplateResponse from(WodTemplates.Template t) {
            WodDefinition d = t.definition();
            return new WodTemplateResponse(t.code(), d.format(), d.timeCapSeconds(), d.rounds(), movementDtos(d));
        }
    }

    /**
     * Una marca: {@code value} son segundos ({@code TIME}), rondas ({@code ROUNDS_REPS}, con {@code extraReps}),
     * repeticiones ({@code REPS}) o kg ({@code LOAD}); {@code capped} = se acabó el límite sin terminar.
     */
    public record WodResultResponse(UUID id, UUID wodId, WodDivision division, WodScoreType scoreType, int value,
                                    Integer extraReps, boolean capped, int durationSeconds, UUID blockId,
                                    Instant performedAt) {
        static WodResultResponse from(WodResult r) {
            return r == null ? null : new WodResultResponse(r.id(), r.wodId(), r.division(), r.scoreType(),
                    r.value(), r.extraReps(), r.capped(), r.durationSeconds(), r.blockId(), r.performedAt());
        }
    }

    /**
     * La pizarra de hoy. {@code example}: es una plantilla de ejemplo ({@code wodId} nulo), no un WOD de la persona.
     * {@code bestRx} y {@code bestScaled}: mejor marca de este mismo WOD en cada división; {@code todayResult}: la de
     * hoy.
     */
    public record WodBoardResponse(UUID wodId, LocalDate date, String templateCode, boolean example, String title,
                                   String strength, WodFormat format, Integer timeCapSeconds, Integer rounds,
                                   List<WodMovementDto> movements, WodResultResponse bestRx,
                                   WodResultResponse bestScaled, WodResultResponse todayResult) {
        static WodBoardResponse from(WodBoard b) {
            WodDefinition d = b.definition();
            return new WodBoardResponse(b.wodId(), b.date(), b.templateCode(), b.example(), d.title(), d.strength(),
                    d.format(), d.timeCapSeconds(), d.rounds(), movementDtos(d), WodResultResponse.from(b.bestRx()),
                    WodResultResponse.from(b.bestScaled()), WodResultResponse.from(b.todayResult()));
        }
    }

    /**
     * Guardar una marca: de un WOD mío ({@code wodId}) o de la pizarra que se manda ({@code wod}, p. ej. una
     * plantilla de ejemplo: se crea mi WOD con ella). {@code scoreType} es opcional (el del formato, o {@code LOAD});
     * {@code capped} por defecto es falso; {@code durationSeconds}, lo que marcó el cronómetro; {@code effort}
     * (1-10), opcional.
     */
    public record WodResultRequest(UUID wodId, @Valid WodRequest wod, @NotNull WodDivision division,
                                   WodScoreType scoreType, @NotNull @Min(0) @Max(100000) Integer value,
                                   @Min(0) @Max(100000) Integer extraReps, Boolean capped,
                                   @Min(1) @Max(18000) Integer durationSeconds, @Min(1) @Max(10) Integer effort) {
    }

    /** Una marca de «Mis marcas», con su WOD; {@code best}: es la mejor de ese WOD en su división. */
    public record WodMarkResponse(WodResultResponse result, String title, String templateCode, WodFormat format,
                                  boolean best) {
        static WodMarkResponse from(WodMark m) {
            return new WodMarkResponse(WodResultResponse.from(m.result()), m.title(), m.templateCode(), m.format(),
                    m.best());
        }
    }

    private final ListWodTemplatesUseCase templates;
    private final GetWodBoardUseCase board;
    private final CreateWodUseCase create;
    private final UpdateWodUseCase update;
    private final DeleteWodUseCase delete;
    private final SaveWodResultUseCase saveResult;
    private final ListWodMarksUseCase marks;

    public WodController(ListWodTemplatesUseCase templates, GetWodBoardUseCase board, CreateWodUseCase create,
                         UpdateWodUseCase update, DeleteWodUseCase delete, SaveWodResultUseCase saveResult,
                         ListWodMarksUseCase marks) {
        this.templates = templates;
        this.board = board;
        this.create = create;
        this.update = update;
        this.delete = delete;
        this.saveResult = saveResult;
        this.marks = marks;
    }

    @GetMapping("/templates")
    public List<WodTemplateResponse> templates() {
        return templates.listTemplates().stream().map(WodTemplateResponse::from).toList();
    }

    /** El WOD de hoy; con {@code templateCode}, esa plantilla de ejemplo en vez de la que toca. */
    @GetMapping("/today")
    public WodBoardResponse today(@CurrentUserId UUID userId, @RequestParam(required = false) String templateCode) {
        return WodBoardResponse.from(board.board(userId, templateCode));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public WodResponse create(@CurrentUserId UUID userId, @Valid @RequestBody WodRequest r) {
        return WodResponse.from(create.createWod(
                new CreateWodUseCase.Command(userId, r.date(), r.templateCode(), r.definition())));
    }

    @PutMapping("/{id}")
    public WodResponse update(@CurrentUserId UUID userId, @PathVariable UUID id, @Valid @RequestBody WodRequest r) {
        return WodResponse.from(update.updateWod(new UpdateWodUseCase.Command(userId, id, r.date(), r.definition())));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID id) {
        delete.deleteWod(userId, id);
    }

    @PostMapping("/results")
    @ResponseStatus(HttpStatus.CREATED)
    public WodMarkResponse saveResult(@CurrentUserId UUID userId, @Valid @RequestBody WodResultRequest r) {
        WodRequest wod = r.wod();
        return WodMarkResponse.from(saveResult.saveResult(new SaveWodResultUseCase.Command(userId, r.wodId(),
                wod == null ? null : wod.templateCode(), wod == null ? null : wod.definition(), r.division(),
                r.scoreType(), r.value(), r.extraReps(), Boolean.TRUE.equals(r.capped()), r.durationSeconds(),
                r.effort())));
    }

    /** «Mis marcas», de la más reciente a la más antigua. */
    @GetMapping("/results")
    public List<WodMarkResponse> marks(@CurrentUserId UUID userId) {
        return marks.listMarks(userId).stream().map(WodMarkResponse::from).toList();
    }

    private static List<WodMovementDto> movementDtos(WodDefinition d) {
        return d.movements().stream().map(WodMovementDto::from).toList();
    }
}
