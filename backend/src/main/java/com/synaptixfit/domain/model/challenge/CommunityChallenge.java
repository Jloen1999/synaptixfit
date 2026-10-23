package com.synaptixfit.domain.model.challenge;

/** Reto visible para otro usuario, con el nombre de su autor. */
public record CommunityChallenge(Challenge challenge, String ownerName) {
}
