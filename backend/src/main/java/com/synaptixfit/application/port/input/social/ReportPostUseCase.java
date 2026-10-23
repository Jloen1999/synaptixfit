package com.synaptixfit.application.port.input.social;

import java.util.UUID;

/** Reporta una publicación ajena visible para moderación. */
public interface ReportPostUseCase {

    void reportPost(UUID userId, UUID postId);
}
