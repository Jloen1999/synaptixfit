import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/comment_dto.dart';
import 'dto/friendship_dto.dart';
import 'dto/like_status_dto.dart';
import 'dto/page_dto.dart';
import 'dto/post_dto.dart';
import 'dto/public_profile_dto.dart';
import 'dto/user_card_dto.dart';

/// Endpoints del muro, comentarios, usuarios y amistades (`/api/v1/social`).
///
/// El usuario autenticado lo resuelve el servidor a partir del token.
class SocialRemoteDataSource {
  SocialRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/social';

  Future<PageDto<PostDto>> feed({
    required String period,
    DateTime? since,
    String? authorId,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/posts',
      queryParameters: {
        'period': period,
        if (since != null) 'since': since.toUtc().toIso8601String(),
        'authorId': ?authorId,
        'page': page,
        'size': size,
      },
    );
    return PageDto.fromJson(response.data!, _post);
  }

  Future<PostDto> post(String postId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/posts/$postId',
    );
    return PostDto.fromJson(response.data!);
  }

  Future<PostDto> createPost({
    required String type,
    required String description,
    String? imageUrl,
    Map<String, Object?>? metadata,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/posts',
      data: {
        'type': type,
        'description': description,
        'imageUrl': ?imageUrl,
        'metadata': ?metadata,
      },
    );
    return PostDto.fromJson(response.data!);
  }

  /// Una [imageUrl] vacía quita la imagen.
  Future<PostDto> editPost(
    String postId, {
    required String description,
    required String imageUrl,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/posts/$postId',
      data: {'description': description, 'imageUrl': imageUrl},
    );
    return PostDto.fromJson(response.data!);
  }

  Future<void> deletePost(String postId) =>
      _dio.delete<void>('$_base/posts/$postId');

  Future<void> reportPost(String postId) =>
      _dio.post<void>('$_base/posts/$postId/report');

  Future<LikeStatusDto> like(String postId) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/posts/$postId/like',
    );
    return LikeStatusDto.fromJson(response.data!);
  }

  Future<LikeStatusDto> unlike(String postId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '$_base/posts/$postId/like',
    );
    return LikeStatusDto.fromJson(response.data!);
  }

  Future<PageDto<CommentDto>> comments(
    String postId, {
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/posts/$postId/comments',
      queryParameters: {'page': page, 'size': size},
    );
    return PageDto.fromJson(
      response.data!,
      (json) => CommentDto.fromJson(json! as Map<String, dynamic>),
    );
  }

  Future<CommentDto> addComment(String postId, String text) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/posts/$postId/comments',
      data: {'text': text},
    );
    return CommentDto.fromJson(response.data!);
  }

  Future<CommentDto> editComment(String commentId, String text) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/comments/$commentId',
      data: {'text': text},
    );
    return CommentDto.fromJson(response.data!);
  }

  Future<void> deleteComment(String commentId) =>
      _dio.delete<void>('$_base/comments/$commentId');

  Future<void> reportComment(String commentId) =>
      _dio.post<void>('$_base/comments/$commentId/report');

  Future<PageDto<UserCardDto>> searchUsers(
    String query, {
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/users/search',
      queryParameters: {'q': query, 'page': page, 'size': size},
    );
    return PageDto.fromJson(
      response.data!,
      (json) => UserCardDto.fromJson(json! as Map<String, dynamic>),
    );
  }

  Future<PublicProfileDto> profile(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/users/$userId',
    );
    return PublicProfileDto.fromJson(response.data!);
  }

  Future<PageDto<FriendshipDto>> friendships({
    required String kind,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/friends',
      queryParameters: {'kind': kind, 'page': page, 'size': size},
    );
    return PageDto.fromJson(
      response.data!,
      (json) => FriendshipDto.fromJson(json! as Map<String, dynamic>),
    );
  }

  Future<FriendshipDto> sendRequest(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/friends/requests',
      data: {'userId': userId},
    );
    return FriendshipDto.fromJson(response.data!);
  }

  Future<FriendshipDto> accept(String friendshipId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/friends/$friendshipId/accept',
    );
    return FriendshipDto.fromJson(response.data!);
  }

  Future<FriendshipDto> reject(String friendshipId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/friends/$friendshipId/reject',
    );
    return FriendshipDto.fromJson(response.data!);
  }

  Future<FriendshipDto> block(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/friends/blocks',
      data: {'userId': userId},
    );
    return FriendshipDto.fromJson(response.data!);
  }

  Future<void> removeFriendship(String friendshipId) =>
      _dio.delete<void>('$_base/friends/$friendshipId');

  static PostDto _post(Object? json) =>
      PostDto.fromJson(json! as Map<String, dynamic>);
}
