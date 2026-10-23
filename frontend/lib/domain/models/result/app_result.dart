import '../../errors/app_error.dart';
import 'result.dart';

/// Resultado estándar de la aplicación.
typedef AppResult<T> = Result<T, AppError>;
