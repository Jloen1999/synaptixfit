package com.synaptixfit.infrastructure.adapter.input.rest.together;

import com.synaptixfit.application.port.input.together.AcceptFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.CreateFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.CreateWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.DeclineFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.DeclineFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.DeclineWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.EndFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.FindWorkoutTogetherBySessionUseCase;
import com.synaptixfit.application.port.input.together.GetTogetherLimitsUseCase;
import com.synaptixfit.application.port.input.together.GetFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.GetWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.JoinFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.JoinWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.LeaveFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.LeaveWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.ListFriendChallengeTemplatesUseCase;
import com.synaptixfit.application.port.input.together.ListTogetherUseCase;
import com.synaptixfit.application.port.input.together.NudgeFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.ProposeFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.ReactFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.RemoveFriendChallengeReactionUseCase;
import com.synaptixfit.application.port.input.together.StartWorkoutTogetherUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ChallengeTemplateResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ChallengeRuleResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.CreateFriendChallengeRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.CreateWorkoutTogetherRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.FriendChallengeResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.FriendStreakRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.FriendStreakResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.ReactionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.TogetherLimitsResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.TogetherOverviewResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.WorkoutTogetherResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.WorkoutTogetherStartResponse;
import com.synaptixfit.infrastructure.i18n.RequestLanguage;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
 * «Con amigos» asíncrono (ADR 0044): retos privados entre amigos con su tablón de reacciones fijas, rachas con un
 * amigo, «Entrenamos juntos» y los topes de todo (ADR 0045). Solo entre amigos mutuos; lo ajeno se trata como
 * inexistente (404).
 */
@Tag(name = "Social - Together")
@RestController
@RequestMapping("/api/v1/together")
public class TogetherController {

    private final ListTogetherUseCase overview;
    private final GetTogetherLimitsUseCase limits;
    private final ListFriendChallengeTemplatesUseCase templates;
    private final CreateFriendChallengeUseCase createChallenge;
    private final GetFriendChallengeUseCase getChallenge;
    private final JoinFriendChallengeUseCase joinChallenge;
    private final DeclineFriendChallengeUseCase declineChallenge;
    private final LeaveFriendChallengeUseCase leaveChallenge;
    private final ReactFriendChallengeUseCase react;
    private final RemoveFriendChallengeReactionUseCase removeReaction;
    private final ProposeFriendStreakUseCase proposeStreak;
    private final AcceptFriendStreakUseCase acceptStreak;
    private final DeclineFriendStreakUseCase declineStreak;
    private final EndFriendStreakUseCase endStreak;
    private final NudgeFriendStreakUseCase nudgeStreak;
    private final CreateWorkoutTogetherUseCase createWorkout;
    private final GetWorkoutTogetherUseCase getWorkout;
    private final FindWorkoutTogetherBySessionUseCase workoutBySession;
    private final JoinWorkoutTogetherUseCase joinWorkout;
    private final DeclineWorkoutTogetherUseCase declineWorkout;
    private final LeaveWorkoutTogetherUseCase leaveWorkout;
    private final StartWorkoutTogetherUseCase startWorkout;

    @SuppressWarnings("java:S107")
    public TogetherController(ListTogetherUseCase overview, GetTogetherLimitsUseCase limits,
                              ListFriendChallengeTemplatesUseCase templates,
                              CreateFriendChallengeUseCase createChallenge, GetFriendChallengeUseCase getChallenge,
                              JoinFriendChallengeUseCase joinChallenge, DeclineFriendChallengeUseCase declineChallenge,
                              LeaveFriendChallengeUseCase leaveChallenge, ReactFriendChallengeUseCase react,
                              RemoveFriendChallengeReactionUseCase removeReaction,
                              ProposeFriendStreakUseCase proposeStreak, AcceptFriendStreakUseCase acceptStreak,
                              DeclineFriendStreakUseCase declineStreak, EndFriendStreakUseCase endStreak,
                              NudgeFriendStreakUseCase nudgeStreak, CreateWorkoutTogetherUseCase createWorkout,
                              GetWorkoutTogetherUseCase getWorkout,
                              FindWorkoutTogetherBySessionUseCase workoutBySession,
                              JoinWorkoutTogetherUseCase joinWorkout, DeclineWorkoutTogetherUseCase declineWorkout,
                              LeaveWorkoutTogetherUseCase leaveWorkout, StartWorkoutTogetherUseCase startWorkout) {
        this.overview = overview;
        this.limits = limits;
        this.templates = templates;
        this.createChallenge = createChallenge;
        this.getChallenge = getChallenge;
        this.joinChallenge = joinChallenge;
        this.declineChallenge = declineChallenge;
        this.leaveChallenge = leaveChallenge;
        this.react = react;
        this.removeReaction = removeReaction;
        this.proposeStreak = proposeStreak;
        this.acceptStreak = acceptStreak;
        this.declineStreak = declineStreak;
        this.endStreak = endStreak;
        this.nudgeStreak = nudgeStreak;
        this.createWorkout = createWorkout;
        this.getWorkout = getWorkout;
        this.workoutBySession = workoutBySession;
        this.joinWorkout = joinWorkout;
        this.declineWorkout = declineWorkout;
        this.leaveWorkout = leaveWorkout;
        this.startWorkout = startWorkout;
    }

    @GetMapping
    public TogetherOverviewResponse overview(@CurrentUserId UUID userId) {
        return TogetherOverviewResponse.from(overview.overview(userId, RequestLanguage.code()));
    }

    /** Topes para los selectores del cliente (amigos por reto, entreno o sala; rachas; rondas). */
    @GetMapping("/limits")
    public TogetherLimitsResponse limits() {
        return TogetherLimitsResponse.from(limits.limits());
    }

    // ------------------------------------------------------------------ retos

    /** Plantillas que valen para un reto con amigos (nunca las de bienestar); sin XP: el reto con amigos no da. */
    @GetMapping("/challenges/templates")
    public List<ChallengeTemplateResponse> templates(@CurrentUserId UUID userId) {
        return templates.friendTemplates(userId, RequestLanguage.code()).stream()
                .map(t -> new ChallengeTemplateResponse(t.id(), t.code(), t.title(), t.goal(), t.type(),
                        t.difficulty(), 0, t.days(), ChallengeRuleResponse.of(t.rule(), 0), false))
                .toList();
    }

    @PostMapping("/challenges")
    @ResponseStatus(HttpStatus.CREATED)
    public FriendChallengeResponse createChallenge(@CurrentUserId UUID userId,
                                                   @Valid @RequestBody CreateFriendChallengeRequest request) {
        return FriendChallengeResponse.from(createChallenge.create(new CreateFriendChallengeUseCase.Command(userId,
                request.templateId(), request.days(), request.mode(), request.friendIds()), RequestLanguage.code()));
    }

    @GetMapping("/challenges/{challengeId}")
    public FriendChallengeResponse challenge(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        return FriendChallengeResponse.from(getChallenge.get(userId, challengeId, RequestLanguage.code()));
    }

    /** Acepta la invitación (o vuelve tras salir: «Deshacer»). */
    @PostMapping("/challenges/{challengeId}/join")
    public FriendChallengeResponse joinChallenge(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        return FriendChallengeResponse.from(joinChallenge.join(userId, challengeId, RequestLanguage.code()));
    }

    @PostMapping("/challenges/{challengeId}/decline")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void declineChallenge(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        declineChallenge.decline(userId, challengeId);
    }

    @PostMapping("/challenges/{challengeId}/leave")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void leaveChallenge(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        leaveChallenge.leave(userId, challengeId);
    }

    @PutMapping("/challenges/{challengeId}/reactions")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void react(@CurrentUserId UUID userId, @PathVariable UUID challengeId,
                      @Valid @RequestBody ReactionRequest request) {
        react.react(userId, challengeId, request.recipientId(), request.day(), request.reaction());
    }

    @DeleteMapping("/challenges/{challengeId}/reactions")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeReaction(@CurrentUserId UUID userId, @PathVariable UUID challengeId,
                               @RequestParam UUID recipientId, @RequestParam LocalDate day) {
        removeReaction.removeReaction(userId, challengeId, recipientId, day);
    }

    // ------------------------------------------------------------------ rachas

    @PostMapping("/streaks")
    @ResponseStatus(HttpStatus.CREATED)
    public FriendStreakResponse proposeStreak(@CurrentUserId UUID userId,
                                              @Valid @RequestBody FriendStreakRequest request) {
        return FriendStreakResponse.from(proposeStreak.propose(userId, request.friendId()));
    }

    @PostMapping("/streaks/{streakId}/accept")
    public FriendStreakResponse acceptStreak(@CurrentUserId UUID userId, @PathVariable UUID streakId) {
        return FriendStreakResponse.from(acceptStreak.accept(userId, streakId));
    }

    @PostMapping("/streaks/{streakId}/decline")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void declineStreak(@CurrentUserId UUID userId, @PathVariable UUID streakId) {
        declineStreak.decline(userId, streakId);
    }

    /** Termina la racha (o retira la propuesta). */
    @DeleteMapping("/streaks/{streakId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void endStreak(@CurrentUserId UUID userId, @PathVariable UUID streakId) {
        endStreak.end(userId, streakId);
    }

    @PostMapping("/streaks/{streakId}/nudge")
    public FriendStreakResponse nudgeStreak(@CurrentUserId UUID userId, @PathVariable UUID streakId) {
        return FriendStreakResponse.from(nudgeStreak.nudge(userId, streakId));
    }

    // ------------------------------------------------------------------ entrenar juntos

    @PostMapping("/workouts")
    @ResponseStatus(HttpStatus.CREATED)
    public WorkoutTogetherResponse createWorkout(@CurrentUserId UUID userId,
                                                 @Valid @RequestBody CreateWorkoutTogetherRequest request) {
        return WorkoutTogetherResponse.from(createWorkout.create(new CreateWorkoutTogetherUseCase.Command(userId,
                request.routineId(), request.dayId(), request.friendIds())));
    }

    @GetMapping("/workouts/{workoutId}")
    public WorkoutTogetherResponse workout(@CurrentUserId UUID userId, @PathVariable UUID workoutId) {
        return WorkoutTogetherResponse.from(getWorkout.get(userId, workoutId));
    }

    /** El de una sesión propia; 204 sin cuerpo si la sesión no es de entrenar juntos (es lo normal, no un error). */
    @GetMapping("/workouts/by-session/{sessionId}")
    public ResponseEntity<WorkoutTogetherResponse> workoutBySession(@CurrentUserId UUID userId,
                                                                    @PathVariable UUID sessionId) {
        return workoutBySession.bySession(userId, sessionId).map(WorkoutTogetherResponse::from)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @PostMapping("/workouts/{workoutId}/join")
    public WorkoutTogetherResponse joinWorkout(@CurrentUserId UUID userId, @PathVariable UUID workoutId) {
        return WorkoutTogetherResponse.from(joinWorkout.join(userId, workoutId));
    }

    @PostMapping("/workouts/{workoutId}/decline")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void declineWorkout(@CurrentUserId UUID userId, @PathVariable UUID workoutId) {
        declineWorkout.decline(userId, workoutId);
    }

    @PostMapping("/workouts/{workoutId}/leave")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void leaveWorkout(@CurrentUserId UUID userId, @PathVariable UUID workoutId) {
        leaveWorkout.leave(userId, workoutId);
    }

    /** Empieza (o retoma) mi sesión para entrenar juntos. */
    @PostMapping("/workouts/{workoutId}/start")
    public WorkoutTogetherStartResponse startWorkout(@CurrentUserId UUID userId, @PathVariable UUID workoutId) {
        return new WorkoutTogetherStartResponse(startWorkout.start(userId, workoutId));
    }
}
