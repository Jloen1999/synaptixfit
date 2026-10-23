import 'package:freezed_annotation/freezed_annotation.dart';

part 'mind_map.freezed.dart';

/// Mapa mental: idea central y ramas anidadas.
@freezed
abstract class MindMap with _$MindMap {
  const factory MindMap({
    required String central,
    @Default(<MindMapNode>[]) List<MindMapNode> branches,
  }) = _MindMap;
}

/// Nodo de un mapa mental.
@freezed
abstract class MindMapNode with _$MindMapNode {
  const factory MindMapNode({
    required String title,
    @Default(<MindMapNode>[]) List<MindMapNode> children,
  }) = _MindMapNode;
}
