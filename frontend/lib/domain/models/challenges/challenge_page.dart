import 'package:freezed_annotation/freezed_annotation.dart';

import 'challenge.dart';

part 'challenge_page.freezed.dart';

/// Página de retos devuelta por un listado paginado.
@freezed
abstract class ChallengePage with _$ChallengePage {
  const factory ChallengePage({
    required List<Challenge> items,
    required int page,
    required int totalPages,
    required int totalItems,
  }) = _ChallengePage;

  const ChallengePage._();

  bool get hasMore => page + 1 < totalPages;
}
