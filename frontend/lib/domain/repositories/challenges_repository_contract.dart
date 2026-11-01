import '../enums/challenge_type.dart';
import '../models/challenges/challenge.dart';
import '../models/challenges/challenge_draft.dart';
import '../models/challenges/challenge_outcome.dart';
import '../models/challenges/challenge_page.dart';
import '../models/challenges/challenge_progress_entry.dart';
import '../models/challenges/challenge_query.dart';
import '../models/challenges/challenge_summary.dart';
import '../models/challenges/pending_milestone.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Retos del usuario, comunidad, tareas y progreso (`/api/v1/challenges`).
abstract interface class ChallengesRepositoryContract {
  Future<AppResult<ChallengePage>> listMine({
    required ChallengeQuery query,
    required int page,
    required int size,
  });

  Future<AppResult<ChallengeSummary>> summary();

  Future<AppResult<ChallengePage>> community({
    ChallengeType? type,
    String? search,
    required int page,
    required int size,
  });

  Future<AppResult<List<PendingMilestone>>> pendingMilestones();

  Future<AppResult<Challenge>> get(String challengeId);

  Future<AppResult<Challenge>> create(ChallengeDraft draft);

  Future<AppResult<Challenge>> update(
    String challengeId,
    ChallengeChanges changes,
  );

  Future<AppResult<Unit>> delete(String challengeId);

  Future<AppResult<Challenge>> clone(String challengeId);

  Future<AppResult<ChallengeOutcome>> setCompleted(
    String challengeId, {
    required bool completed,
  });

  Future<AppResult<ChallengeOutcome>> setMilestoneCompleted(
    String challengeId,
    String milestoneId, {
    required bool completed,
  });

  Future<AppResult<ChallengeOutcome>> recordProgress(
    String challengeId, {
    String? milestoneId,
    required double value,
  });

  Future<AppResult<List<ChallengeProgressEntry>>> progressHistory(
    String challengeId,
  );

  Future<AppResult<ChallengeOutcome>> replaceMilestones(
    String challengeId,
    List<MilestoneDraft> milestones,
  );

  Future<AppResult<Challenge>> reorderMilestones(
    String challengeId,
    List<String> milestoneIds,
  );
}
