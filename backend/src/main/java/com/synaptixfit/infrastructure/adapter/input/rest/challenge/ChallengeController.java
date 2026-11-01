package com.synaptixfit.infrastructure.adapter.input.rest.challenge;

import com.synaptixfit.application.port.input.challenge.ChallengeView;
import com.synaptixfit.application.port.input.challenge.CloneChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.CompleteChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.CompleteMilestoneUseCase;
import com.synaptixfit.application.port.input.challenge.CreateChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.DeleteChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.GetChallengeSummaryUseCase;
import com.synaptixfit.application.port.input.challenge.GetChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.ListChallengeProgressUseCase;
import com.synaptixfit.application.port.input.challenge.ListCommunityChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.ListMyChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.ListPendingMilestonesUseCase;
import com.synaptixfit.application.port.input.challenge.RecordChallengeProgressUseCase;
import com.synaptixfit.application.port.input.challenge.ReorderMilestonesUseCase;
import com.synaptixfit.application.port.input.challenge.ReplaceMilestonesUseCase;
import com.synaptixfit.application.port.input.challenge.UncompleteChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.UncompleteMilestoneUseCase;
import com.synaptixfit.application.port.input.challenge.UpdateChallengeUseCase;
import com.synaptixfit.domain.model.challenge.ChallengeQuery;
import com.synaptixfit.domain.model.challenge.ChallengeStatus;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ChallengeOutcomeResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ChallengeResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ChallengeSummaryResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.CreateChallengeRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.MilestoneRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.PendingMilestoneResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ProgressEntryResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.RecordProgressRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ReorderMilestonesRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ReplaceMilestonesRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.ResponseTime;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.UpdateChallengeRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.Clock;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Retos con tareas opcionales: alta, edición, progreso, comunidad y clonado. */
@Tag(name = "Challenges")
@RestController
@RequestMapping("/api/v1/challenges")
public class ChallengeController {

    /** Filtro de tareas en el listado. */
    public enum TasksFilter { WITH, WITHOUT }

    private final CreateChallengeUseCase create;
    private final GetChallengeUseCase get;
    private final ListMyChallengesUseCase listMine;
    private final GetChallengeSummaryUseCase summary;
    private final ListCommunityChallengesUseCase community;
    private final ListPendingMilestonesUseCase pending;
    private final UpdateChallengeUseCase update;
    private final DeleteChallengeUseCase delete;
    private final CloneChallengeUseCase cloneChallenge;
    private final ListChallengeProgressUseCase listProgress;
    private final CompleteChallengeUseCase complete;
    private final UncompleteChallengeUseCase uncomplete;
    private final ReplaceMilestonesUseCase replaceMilestones;
    private final ReorderMilestonesUseCase reorderMilestones;
    private final CompleteMilestoneUseCase completeMilestone;
    private final UncompleteMilestoneUseCase uncompleteMilestone;
    private final RecordChallengeProgressUseCase recordProgress;
    private final Clock clock;
    private final ZoneId zone;

    public ChallengeController(CreateChallengeUseCase create, GetChallengeUseCase get,
                               ListMyChallengesUseCase listMine, GetChallengeSummaryUseCase summary,
                               ListCommunityChallengesUseCase community, ListPendingMilestonesUseCase pending,
                               UpdateChallengeUseCase update, DeleteChallengeUseCase delete,
                               CloneChallengeUseCase cloneChallenge, ListChallengeProgressUseCase listProgress,
                               CompleteChallengeUseCase complete, UncompleteChallengeUseCase uncomplete,
                               ReplaceMilestonesUseCase replaceMilestones, ReorderMilestonesUseCase reorderMilestones,
                               CompleteMilestoneUseCase completeMilestone,
                               UncompleteMilestoneUseCase uncompleteMilestone,
                               RecordChallengeProgressUseCase recordProgress, Clock clock,
                               @Value("${synaptixfit.gamification.zone:Europe/Madrid}") String zone) {
        this.create = create;
        this.get = get;
        this.listMine = listMine;
        this.summary = summary;
        this.community = community;
        this.pending = pending;
        this.update = update;
        this.delete = delete;
        this.cloneChallenge = cloneChallenge;
        this.listProgress = listProgress;
        this.complete = complete;
        this.uncomplete = uncomplete;
        this.replaceMilestones = replaceMilestones;
        this.reorderMilestones = reorderMilestones;
        this.completeMilestone = completeMilestone;
        this.uncompleteMilestone = uncompleteMilestone;
        this.recordProgress = recordProgress;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    /** Instante y día de gamificación de la respuesta (estado del reto y racha vigente). */
    private ResponseTime time() {
        return ResponseTime.of(clock, zone);
    }

    // ---------------------------------------------------------------- retos

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ChallengeResponse create(@CurrentUserId UUID userId, @Valid @RequestBody CreateChallengeRequest request) {
        return ChallengeResponse.own(create.createChallenge(new CreateChallengeUseCase.Command(userId,
                request.toDetails(clock.instant()), request.toDrafts())), time());
    }

    @GetMapping
    public PageResponse<ChallengeResponse> listMine(@CurrentUserId UUID userId,
                                                    @RequestParam(required = false) ChallengeStatus status,
                                                    @RequestParam(required = false) ChallengeType type,
                                                    @RequestParam(required = false) TasksFilter tasks,
                                                    @RequestParam(required = false) String q,
                                                    @RequestParam(defaultValue = "0") int page,
                                                    @RequestParam(defaultValue = "20") int size) {
        Boolean withTasks = tasks == null ? null : tasks == TasksFilter.WITH;
        return PageResponse.from(listMine.listMyChallenges(userId, new ChallengeQuery(status, type, withTasks, q),
                new PageRequest(page, size)), c -> ChallengeResponse.own(c, time()));
    }

    @GetMapping("/summary")
    public ChallengeSummaryResponse summary(@CurrentUserId UUID userId) {
        return ChallengeSummaryResponse.from(summary.getChallengeSummary(userId));
    }

    @GetMapping("/community")
    public PageResponse<ChallengeResponse> community(@CurrentUserId UUID userId,
                                                     @RequestParam(required = false) ChallengeType type,
                                                     @RequestParam(required = false) String q,
                                                     @RequestParam(defaultValue = "0") int page,
                                                     @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(community.listCommunityChallenges(userId, type, q, new PageRequest(page, size)),
                cc -> ChallengeResponse.from(cc.challenge(), false, cc.ownerName(), time()));
    }

    @GetMapping("/milestones/pending")
    public List<PendingMilestoneResponse> pendingMilestones(@CurrentUserId UUID userId) {
        return pending.listPendingMilestones(userId).stream().map(PendingMilestoneResponse::from).toList();
    }

    @GetMapping("/{challengeId}")
    public ChallengeResponse get(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        ChallengeView view = get.getChallenge(userId, challengeId);
        return ChallengeResponse.from(view.challenge(), view.owned(), view.ownerName(), time());
    }

    @PatchMapping("/{challengeId}")
    public ChallengeResponse update(@CurrentUserId UUID userId, @PathVariable UUID challengeId,
                                    @Valid @RequestBody UpdateChallengeRequest r) {
        return ChallengeResponse.own(update.updateChallenge(new UpdateChallengeUseCase.Command(userId, challengeId,
                r.title(), r.type(), r.goal(), r.visibility(), r.difficulty(), r.startAt(), r.endAt(), r.subjectId(),
                Boolean.TRUE.equals(r.clearSubject()), r.linkedEntityType(), r.linkedEntityId(),
                Boolean.TRUE.equals(r.clearLink()), r.sessionTarget(), Boolean.TRUE.equals(r.clearSessionTarget()))),
                time());
    }

    @DeleteMapping("/{challengeId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        delete.deleteChallenge(userId, challengeId);
    }

    @PostMapping("/{challengeId}/clone")
    @ResponseStatus(HttpStatus.CREATED)
    public ChallengeResponse cloneChallenge(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        return ChallengeResponse.own(cloneChallenge.cloneChallenge(userId, challengeId), time());
    }

    @PostMapping("/{challengeId}/complete")
    public ChallengeOutcomeResponse complete(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        return ChallengeOutcomeResponse.from(complete.completeChallenge(userId, challengeId), time());
    }

    @PostMapping("/{challengeId}/uncomplete")
    public ChallengeOutcomeResponse uncomplete(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        return ChallengeOutcomeResponse.from(uncomplete.uncompleteChallenge(userId, challengeId), time());
    }

    // ---------------------------------------------------------------- progreso

    @PostMapping("/{challengeId}/progress")
    public ChallengeOutcomeResponse recordProgress(@CurrentUserId UUID userId, @PathVariable UUID challengeId,
                                                   @Valid @RequestBody RecordProgressRequest r) {
        return ChallengeOutcomeResponse.from(recordProgress.recordProgress(new RecordChallengeProgressUseCase.Command(
                userId, challengeId, r.milestoneId(), r.amount(), r.value(), r.recordedAt())), time());
    }

    @GetMapping("/{challengeId}/progress")
    public List<ProgressEntryResponse> progress(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        return listProgress.listProgress(userId, challengeId).stream().map(ProgressEntryResponse::from).toList();
    }

    // ---------------------------------------------------------------- tareas

    @PutMapping("/{challengeId}/milestones")
    public ChallengeOutcomeResponse replaceMilestones(@CurrentUserId UUID userId, @PathVariable UUID challengeId,
                                                      @Valid @RequestBody ReplaceMilestonesRequest r) {
        return ChallengeOutcomeResponse.from(replaceMilestones.replaceMilestones(new ReplaceMilestonesUseCase.Command(
                userId, challengeId, r.milestones().stream().map(MilestoneRequest::toDraft).toList())),
                time());
    }

    @PutMapping("/{challengeId}/milestones/order")
    public ChallengeResponse reorderMilestones(@CurrentUserId UUID userId, @PathVariable UUID challengeId,
                                               @Valid @RequestBody ReorderMilestonesRequest r) {
        return ChallengeResponse.own(reorderMilestones.reorderMilestones(userId, challengeId, r.milestoneIds()),
                time());
    }

    @PostMapping("/{challengeId}/milestones/{milestoneId}/complete")
    public ChallengeOutcomeResponse completeMilestone(@CurrentUserId UUID userId, @PathVariable UUID challengeId,
                                                      @PathVariable UUID milestoneId) {
        return ChallengeOutcomeResponse.from(completeMilestone.completeMilestone(userId, challengeId, milestoneId),
                time());
    }

    @PostMapping("/{challengeId}/milestones/{milestoneId}/uncomplete")
    public ChallengeOutcomeResponse uncompleteMilestone(@CurrentUserId UUID userId, @PathVariable UUID challengeId,
                                                        @PathVariable UUID milestoneId) {
        return ChallengeOutcomeResponse.from(uncompleteMilestone.uncompleteMilestone(userId, challengeId, milestoneId),
                time());
    }
}
