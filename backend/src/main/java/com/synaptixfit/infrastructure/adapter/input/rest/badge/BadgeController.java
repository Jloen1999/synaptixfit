package com.synaptixfit.infrastructure.adapter.input.rest.badge;

import com.synaptixfit.application.port.input.badge.ChangeBadgeVisibilityUseCase;
import com.synaptixfit.application.port.input.badge.EvaluateBadgesUseCase;
import com.synaptixfit.application.port.input.badge.GetBadgeCatalogUseCase;
import com.synaptixfit.application.port.input.badge.ListMyBadgesUseCase;
import com.synaptixfit.application.port.input.badge.ListUnnotifiedBadgesUseCase;
import com.synaptixfit.application.port.input.badge.MarkBadgesNotifiedUseCase;
import com.synaptixfit.domain.model.badge.BadgeCategory;
import com.synaptixfit.infrastructure.adapter.input.rest.badge.dto.BadgeEvaluationResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.badge.dto.BadgeResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.badge.dto.BadgeVisibilityRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.badge.dto.MarkBadgesNotifiedRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Catálogo de insignias, insignias del usuario y evaluación de criterios. */
@Tag(name = "Badges")
@RestController
@RequestMapping("/api/v1/badges")
public class BadgeController {

    private final GetBadgeCatalogUseCase catalog;
    private final ListMyBadgesUseCase mine;
    private final EvaluateBadgesUseCase evaluate;
    private final ListUnnotifiedBadgesUseCase unnotified;
    private final MarkBadgesNotifiedUseCase markNotified;
    private final ChangeBadgeVisibilityUseCase visibility;

    public BadgeController(GetBadgeCatalogUseCase catalog, ListMyBadgesUseCase mine, EvaluateBadgesUseCase evaluate,
                           ListUnnotifiedBadgesUseCase unnotified, MarkBadgesNotifiedUseCase markNotified,
                           ChangeBadgeVisibilityUseCase visibility) {
        this.catalog = catalog;
        this.mine = mine;
        this.evaluate = evaluate;
        this.unnotified = unnotified;
        this.markNotified = markNotified;
        this.visibility = visibility;
    }

    @GetMapping
    public List<BadgeResponse> catalog(@CurrentUserId UUID userId,
                                       @RequestParam(required = false) BadgeCategory category,
                                       @RequestParam(required = false) String zone) {
        return catalog.getBadgeCatalog(userId, category, zone).stream().map(BadgeResponse::from).toList();
    }

    @GetMapping("/mine")
    public List<BadgeResponse> mine(@CurrentUserId UUID userId,
                                    @RequestParam(defaultValue = "false") boolean includeHidden) {
        return mine.listMyBadges(userId, includeHidden).stream().map(BadgeResponse::from).toList();
    }

    @GetMapping("/unnotified")
    public List<BadgeResponse> unnotified(@CurrentUserId UUID userId) {
        return unnotified.listUnnotifiedBadges(userId).stream().map(BadgeResponse::from).toList();
    }

    @PostMapping("/evaluate")
    public BadgeEvaluationResponse evaluate(@CurrentUserId UUID userId,
                                            @RequestParam(required = false) String zone) {
        return BadgeEvaluationResponse.from(evaluate.evaluateBadges(userId, zone));
    }

    @PostMapping("/notified")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markNotified(@CurrentUserId UUID userId, @Valid @RequestBody MarkBadgesNotifiedRequest request) {
        markNotified.markBadgesNotified(userId, request.badgeIds());
    }

    @PatchMapping("/{badgeId}")
    public BadgeResponse changeVisibility(@CurrentUserId UUID userId, @PathVariable UUID badgeId,
                                          @Valid @RequestBody BadgeVisibilityRequest request) {
        return BadgeResponse.from(visibility.changeBadgeVisibility(userId, badgeId, request.visible()));
    }
}
