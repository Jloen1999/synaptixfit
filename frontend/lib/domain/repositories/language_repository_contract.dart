import '../enums/app_language.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Idioma elegido en este dispositivo.
abstract interface class LanguageRepositoryContract {
  Future<AppResult<AppLanguage>> getLanguage();

  Future<AppResult<Unit>> setLanguage(AppLanguage language);
}
