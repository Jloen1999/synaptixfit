import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/mixins/deferred_commit_mixin.dart';

/// Bloc mínimo que apunta qué se hizo de verdad.
class _Bloc extends Cubit<int> with DeferredCommitMixin<int> {
  _Bloc() : super(0);

  final committed = <String>[];

  @override
  Future<void> commitDeferred(String id) async => committed.add(id);
}

/// Lo quitado con «Deshacer» se hace una sola vez: al confirmarse el aviso o
/// al cerrarse el bloc; deshecho, nunca.
void main() {
  test('defer y release: una sola vez por id', () {
    final bloc = _Bloc();
    expect(bloc.defer('a'), isTrue);
    expect(bloc.defer('a'), isFalse);
    expect(bloc.isDeferred('a'), isTrue);
    expect(bloc.release('a'), isTrue);
    expect(bloc.release('a'), isFalse);
    expect(bloc.isDeferred('a'), isFalse);
  });

  test('al cerrar se hace lo que seguía aplazado, no lo deshecho', () async {
    final bloc = _Bloc()
      ..defer('a')
      ..defer('b');
    bloc.release('b');
    await bloc.close();
    expect(bloc.committed, ['a']);
  });
}
