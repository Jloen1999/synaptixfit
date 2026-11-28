package com.synaptixfit.application.service.wod;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.port.input.wod.CreateWodUseCase;
import com.synaptixfit.application.port.input.wod.SaveWodResultUseCase;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.wod.WodNotFoundException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.Sport;
import com.synaptixfit.domain.model.planner.TimeRange;
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
import com.synaptixfit.domain.port.output.wod.WodRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * WOD: la pizarra de hoy (mía o de ejemplo), guardar una marca la apunta como actividad con deporte WOD, y la mejor
 * marca de cada WOD y división la decide el servidor.
 */
class WodServiceTest {

    private static final Instant NOW = Instant.parse("2026-11-28T18:00:00Z");
    private static final LocalDate TODAY = LocalDate.of(2026, 11, 28);
    private final UUID user = UUID.randomUUID();

    private final Map<UUID, Wod> wods = new LinkedHashMap<>();
    private final List<WodResult> results = new ArrayList<>();
    private final List<LogPastActivityUseCase.Command> logged = new ArrayList<>();
    private Instant now = NOW;
    private WodService service;

    @BeforeEach
    void setUp() {
        WodRepositoryPort repository = new WodRepositoryPort() {
            @Override
            public Wod save(Wod wod) {
                wods.put(wod.id(), wod);
                return wod;
            }

            @Override
            public Optional<Wod> findOwned(UUID userId, UUID wodId) {
                return Optional.ofNullable(wods.get(wodId)).filter(w -> w.userId().equals(userId));
            }

            @Override
            public Optional<Wod> findOfDay(UUID userId, LocalDate date) {
                return wods.values().stream().filter(w -> w.userId().equals(userId) && w.date().equals(date))
                        .max(Comparator.comparing(Wod::updatedAt));
            }

            @Override
            public void delete(UUID userId, UUID wodId) {
                wods.remove(wodId);
                results.removeIf(r -> r.wodId().equals(wodId));
            }

            @Override
            public WodResult saveResult(WodResult result) {
                results.add(result);
                return result;
            }

            @Override
            public List<WodMark> findMarks(UUID userId) {
                return results.stream().filter(r -> r.userId().equals(userId))
                        .sorted(Comparator.comparing(WodResult::performedAt).reversed())
                        .map(r -> {
                            Wod w = wods.get(r.wodId());
                            return new WodMark(r, w.definition().signature(), w.definition().title(),
                                    w.templateCode(), w.definition().format(), false);
                        }).toList();
            }
        };
        LogPastActivityUseCase logActivity = command -> {
            logged.add(command);
            CalendarBlock block = CalendarBlock.builder()
                    .id(UUID.randomUUID())
                    .userId(command.userId())
                    .range(new TimeRange(command.start(), command.start().plus(Duration.ofMinutes(30))))
                    .dayOfWeek(6)
                    .type(ActivityType.SPORT)
                    .details(new CalendarBlock.Details(null, command.title(), null, Priority.MEDIUM, false, null,
                            null, null, null, null, null, null))
                    .fixed(false)
                    .createdAt(command.start())
                    .build();
            return new SetBlockCompletionUseCase.Result(block, 10);
        };
        Clock clock = new Clock() {
            @Override
            public java.time.ZoneId getZone() {
                return ZoneOffset.UTC;
            }

            @Override
            public Clock withZone(java.time.ZoneId zone) {
                return this;
            }

            @Override
            public Instant instant() {
                return now;
            }
        };
        service = new WodService(repository, logActivity, PlannerZone.of("UTC"), clock);
    }

    private static WodDefinition forTime(String title) {
        return new WodDefinition(title, null, WodFormat.FOR_TIME, 900, 3,
                List.of(new WodMovement(null, "Sentadillas", 20, null, null, null)));
    }

    private SaveWodResultUseCase.Command time(UUID wodId, WodDivision division, int seconds) {
        return new SaveWodResultUseCase.Command(user, wodId, null, null, division, null, seconds, null, false,
                seconds, null);
    }

    @Test
    void withoutMyOwnWodTheBoardShowsTheExampleOfTheDay() {
        WodBoard board = service.board(user, null);

        assertThat(board.example()).isTrue();
        assertThat(board.wodId()).isNull();
        assertThat(board.templateCode()).isEqualTo(WodTemplates.ofDay(TODAY).code());
        assertThat(service.board(user, "LONG_LIST").templateCode()).isEqualTo("LONG_LIST");
        assertThatThrownBy(() -> service.board(user, "NOPE")).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void myWodOfTodayIsTheBoardWithItsBestAndTodayMarks() {
        Wod wod = service.createWod(new CreateWodUseCase.Command(user, null, null, forTime("Lunes")));
        service.saveResult(time(wod.id(), WodDivision.RX, 600));
        now = NOW.plusSeconds(3600);
        WodMark second = service.saveResult(time(wod.id(), WodDivision.RX, 540));

        WodBoard board = service.board(user, null);

        assertThat(board.example()).isFalse();
        assertThat(board.wodId()).isEqualTo(wod.id());
        assertThat(board.bestRx().value()).isEqualTo(540);
        assertThat(board.bestScaled()).isNull();
        assertThat(board.todayResult().id()).isEqualTo(second.result().id());
        assertThat(second.best()).isTrue();
    }

    @Test
    void savingAMarkLogsAWodActivityThatEndsNow() {
        Wod wod = service.createWod(new CreateWodUseCase.Command(user, null, null, forTime("Lunes")));

        WodMark mark = service.saveResult(time(wod.id(), WodDivision.SCALED, 432));

        assertThat(logged).singleElement().satisfies(c -> {
            assertThat(c.sport().sport()).isEqualTo(Sport.WOD);
            assertThat(c.title()).isEqualTo("Lunes");
            // 7 min 12 s reales: la actividad cuenta el mínimo del planificador, 10 minutos.
            assertThat(c.minutes()).isEqualTo(10);
            assertThat(c.start()).isEqualTo(NOW.minus(Duration.ofMinutes(10)));
            assertThat(c.effort()).isEqualTo(WodService.DEFAULT_EFFORT);
            assertThat(c.type()).isEqualTo(ActivityType.SPORT);
        });
        assertThat(mark.result().scoreType()).isEqualTo(WodScoreType.TIME);
        assertThat(mark.result().durationSeconds()).isEqualTo(432);
        assertThat(mark.result().blockId()).isNotNull();
        assertThat(mark.best()).isTrue();
    }

    @Test
    void aMarkOfAnExampleCreatesMyWodAndSharesBestWithTheSameWodAnotherDay() {
        WodTemplates.Template template = WodTemplates.find("TWELVE_NONSTOP").orElseThrow();
        SaveWodResultUseCase.Command first = new SaveWodResultUseCase.Command(user, null, template.code(),
                template.definition().titled("Doce sin parar"), WodDivision.RX, null, 5, 12, false, 720, 8);
        WodMark mark = service.saveResult(first);
        assertThat(wods).hasSize(1);
        assertThat(wods.get(mark.result().wodId()).templateCode()).isEqualTo("TWELVE_NONSTOP");
        assertThat(mark.result().scoreType()).isEqualTo(WodScoreType.ROUNDS_REPS);
        assertThat(logged.get(0).effort()).isEqualTo(8);
        assertThat(logged.get(0).minutes()).isEqualTo(12);

        // Otro día, en otro idioma: es el mismo WOD (misma huella), así que la marca peor no es la mejor.
        now = NOW.plus(Duration.ofDays(3));
        WodMark worse = service.saveResult(new SaveWodResultUseCase.Command(user, null, template.code(),
                template.definition().titled("Twelve non-stop"), WodDivision.RX, null, 5, 2, false, 720, null));
        assertThat(worse.best()).isFalse();
        assertThat(service.listMarks(user)).extracting(WodMark::best).containsExactly(false, true);
        // La plantilla enseña ya la mejor marca aunque hoy no haya WOD mío.
        now = NOW.plus(Duration.ofDays(9));
        WodBoard board = service.board(user, "TWELVE_NONSTOP");
        assertThat(board.example()).isTrue();
        assertThat(board.bestRx().extraReps()).isEqualTo(12);
    }

    @Test
    void aMarkMustMatchItsWod() {
        Wod wod = service.createWod(new CreateWodUseCase.Command(user, null, null, forTime(null)));

        // Fuera del límite de 15 min no es un tiempo: es «no terminé» con repeticiones.
        assertThatThrownBy(() -> service.saveResult(time(wod.id(), WodDivision.RX, 901)))
                .isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> service.saveResult(new SaveWodResultUseCase.Command(user, wod.id(), null, null,
                WodDivision.RX, WodScoreType.ROUNDS_REPS, 3, 2, false, null, null)))
                .isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> service.saveResult(time(UUID.randomUUID(), WodDivision.RX, 300)))
                .isInstanceOf(WodNotFoundException.class);
        assertThat(logged).isEmpty();

        WodMark capped = service.saveResult(new SaveWodResultUseCase.Command(user, wod.id(), null, null,
                WodDivision.RX, null, 48, null, true, null, null));
        assertThat(capped.result().scoreType()).isEqualTo(WodScoreType.REPS);
        assertThat(capped.result().durationSeconds()).isEqualTo(900);
        assertThat(logged.get(0).title()).isEqualTo(WodService.DEFAULT_TITLE);
        assertThat(logged.get(0).minutes()).isEqualTo(15);
    }

    @Test
    void anotherPersonsWodDoesNotExistForMe() {
        Wod wod = service.createWod(new CreateWodUseCase.Command(user, null, null, forTime("Lunes")));
        UUID stranger = UUID.randomUUID();

        assertThatThrownBy(() -> service.deleteWod(stranger, wod.id())).isInstanceOf(WodNotFoundException.class);
        service.deleteWod(user, wod.id());
        assertThat(wods).isEmpty();
    }
}
