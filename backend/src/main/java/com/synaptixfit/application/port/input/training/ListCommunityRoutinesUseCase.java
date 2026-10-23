package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.VisibleRoutine;
import java.util.UUID;

/** Rutinas públicas (y de amigos) de otros usuarios. */
public interface ListCommunityRoutinesUseCase {

    PageResult<VisibleRoutine> listCommunity(UUID userId, String text, TrainingGoal goal, PageRequest page);
}
