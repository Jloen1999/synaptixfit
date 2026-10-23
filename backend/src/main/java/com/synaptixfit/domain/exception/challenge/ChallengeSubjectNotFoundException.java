package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** La asignatura indicada no existe o no es del usuario. */
public class ChallengeSubjectNotFoundException extends ResourceNotFoundException {

    public ChallengeSubjectNotFoundException(UUID id) {
        super("CHALLENGE_SUBJECT_NOT_FOUND", "Subject", id);
    }
}
