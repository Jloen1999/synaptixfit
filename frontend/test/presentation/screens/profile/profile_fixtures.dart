import 'package:synaptixfit/domain/enums/profile/activity_level.dart';
import 'package:synaptixfit/domain/enums/profile/fitness_goal.dart';
import 'package:synaptixfit/domain/enums/profile/onboarding_step.dart';
import 'package:synaptixfit/domain/enums/profile/sex.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/domain/models/profile/academic_profile.dart';
import 'package:synaptixfit/domain/models/profile/catalog.dart';
import 'package:synaptixfit/domain/models/profile/onboarding_status.dart';
import 'package:synaptixfit/domain/models/profile/profile_summary.dart';
import 'package:synaptixfit/domain/models/profile/wellness_profile.dart';

/// Datos de prueba compartidos por los tests del módulo profile.
const testAccount = Account(
  id: 'u1',
  email: 'ana@uni.es',
  fullName: 'Ana',
  level: 3,
  levelXp: 40,
  levelThreshold: 300,
  streak: 5,
  privacy: Visibility.friends,
  role: UserRole.user,
  hasPassword: true,
  googleLinked: false,
);

const testWellness = WellnessProfile(
  age: 21,
  sex: Sex.female,
  weightKg: 60,
  heightCm: 165,
  bmi: 22,
  activityLevel: ActivityLevel.moderate,
  primaryGoal: FitnessGoal.mobility,
  availableDays: [1, 3, 5],
  minutesPerSession: 45,
);

const testDraft = WellnessProfileDraft(
  age: 21,
  sex: Sex.female,
  weightKg: 60,
  heightCm: 165,
  activityLevel: ActivityLevel.moderate,
  primaryGoal: FitnessGoal.mobility,
  equipment: ['mancuerna'],
  availableDays: [1, 3, 5],
  minutesPerSession: 45,
);

const testAcademic = AcademicProfile(
  university: 'Universidad de Granada',
  degree: 'Grado en Informática',
  semester: 3,
);

const testDegree = Degree(
  id: 'd1',
  name: 'Grado en Informática',
  universityId: 'uni1',
  universityName: 'Universidad de Granada',
);

const testSummary = ProfileSummary(
  wellness: testWellness,
  academic: testAcademic,
  degrees: [UserDegree(degree: testDegree)],
  onboarding: OnboardingStatus(completed: true),
);

const emptySummary = ProfileSummary(
  onboarding: OnboardingStatus(
    completed: false,
    pendingSteps: [
      OnboardingStep.wellnessProfile,
      OnboardingStep.academicProfile,
    ],
  ),
);
