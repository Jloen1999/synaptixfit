package com.synaptixfit.infrastructure.adapter.input.rest.academic.dto;

import com.synaptixfit.application.port.input.academic.SendNoteToFriendUseCase;
import com.synaptixfit.application.port.input.academic.ShareNoteOnWallUseCase;
import com.synaptixfit.domain.model.shared.Visibility;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/** DTOs de «Compartir» un apunte (ADR 0064). */
public final class NoteSharingDtos {

    private NoteSharingDtos() {
    }

    public record SendNoteRequest(@NotNull UUID friendId) {
    }

    public record SentNoteResponse(UUID friendId, String friendName) {

        public static SentNoteResponse from(SendNoteToFriendUseCase.SentNote s) {
            return new SentNoteResponse(s.friendId(), s.friendName());
        }
    }

    /** {@code comment}: texto opcional de la publicación (sin él, el título del apunte). */
    public record ShareNoteOnWallRequest(@Size(max = 2000) String comment) {
    }

    /**
     * @param alreadyShared ya estaba en el muro: no se ha publicado otra vez
     * @param visibility    visibilidad del apunte después de publicarlo
     */
    public record WallShareResponse(boolean alreadyShared, Visibility visibility) {

        public static WallShareResponse from(ShareNoteOnWallUseCase.WallShare s) {
            return new WallShareResponse(s.alreadyShared(), s.visibility());
        }
    }
}
