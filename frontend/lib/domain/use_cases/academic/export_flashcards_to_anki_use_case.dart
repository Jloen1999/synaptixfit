import '../../models/academic/anki_export.dart';
import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/file_export_repository_contract.dart';

/// Guarda las tarjetas como mazo de texto que importa Anki (anverso: la
/// pregunta; reverso: la respuesta y su explicación). `false` si se cancela.
abstract interface class ExportFlashcardsToAnkiUseCaseContract {
  Future<AppResult<bool>> call({
    required String deck,
    required List<Question> cards,
  });
}

class ExportFlashcardsToAnkiUseCase
    implements ExportFlashcardsToAnkiUseCaseContract {
  const ExportFlashcardsToAnkiUseCase(this._files);

  final FileExportRepositoryContract _files;

  @override
  Future<AppResult<bool>> call({
    required String deck,
    required List<Question> cards,
  }) => _files.saveText(
    fileName: AnkiExport.fileName(deck),
    content: AnkiExport.text(deck, [
      for (final c in cards)
        (
          c.statement,
          c.explanation == null || c.explanation!.trim().isEmpty
              ? c.correctAnswer
              : '${c.correctAnswer}\n\n${c.explanation}',
        ),
    ]),
    mimeType: 'text/plain',
    extension: 'txt',
  );
}
