package com.synaptixfit.infrastructure.adapter.input.rest.social;

import com.synaptixfit.application.port.input.social.GetPublicProfileUseCase;
import com.synaptixfit.application.port.input.social.SearchUsersUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.PublicProfileResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.UserCardResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Búsqueda de usuarios y perfiles públicos. */
@Tag(name = "Social - Users")
@RestController
@RequestMapping("/api/v1/social/users")
public class SocialUserController {

    private final SearchUsersUseCase searchUsers;
    private final GetPublicProfileUseCase getProfile;

    public SocialUserController(SearchUsersUseCase searchUsers, GetPublicProfileUseCase getProfile) {
        this.searchUsers = searchUsers;
        this.getProfile = getProfile;
    }

    @GetMapping("/search")
    public PageResponse<UserCardResponse> search(@CurrentUserId UUID userId, @RequestParam String q,
                                                 @RequestParam(defaultValue = "0") int page,
                                                 @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(searchUsers.search(userId, q, new PageRequest(page, size)), UserCardResponse::from);
    }

    @GetMapping("/{targetUserId}")
    public PublicProfileResponse profile(@CurrentUserId UUID userId, @PathVariable UUID targetUserId) {
        return PublicProfileResponse.from(getProfile.getProfile(userId, targetUserId));
    }
}
