import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'high_score_service.dart';

class RankingInfo {
  const RankingInfo({
    required this.userId,
    required this.rank,
    required this.score,
    required this.isRegistered,
  });

  final int userId;
  final int? rank;
  final int score;
  final bool isRegistered;
}

class RankingService {
  RankingService._();

  static const String _publishableKey =
      'sb_publishable__OSLf6Nh2KQcV4uzD_XCog_z8INrljB';
  static final Uri _getRankingUri = Uri.parse(
    'https://yrdjaoaiucicrlplsxjx.supabase.co/functions/v1/get-ranking',
  );
  static final Uri _updateRankingUri = Uri.parse(
    'https://yrdjaoaiucicrlplsxjx.supabase.co/functions/v1/update-ranking',
  );

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_publishableKey',
        'apikey': _publishableKey,
      };

  static Future<RankingInfo> fetchMyRanking() async {
    final userId = await HighScoreService.loadUserId();
    if (userId <= 0) {
      return const RankingInfo(
        userId: 0,
        rank: null,
        score: 0,
        isRegistered: false,
      );
    }

    final body = await _postJson(
      _getRankingUri,
      <String, dynamic>{
        'id': userId,
        'userId': userId,
        'user_id': userId,
      },
    );

    final resolvedUserId = _readInt(
          body,
          const ['id', 'userId', 'user_id'],
        ) ??
        userId;
    final rank = _readInt(
      body,
      const ['rank', 'myRank', 'my_rank', 'ranking'],
    );
    final score = _readInt(
          body,
          const ['score', 'highScore', 'high_score'],
        ) ??
        0;
    final isRegistered =
        _readBool(body, const ['registered', 'isRegistered', 'exists']) ??
            (rank != null || score > 0);

    if (resolvedUserId > 0 && resolvedUserId != userId) {
      await HighScoreService.saveUserId(resolvedUserId);
    }

    return RankingInfo(
      userId: resolvedUserId,
      rank: rank,
      score: score,
      isRegistered: isRegistered,
    );
  }

  static Future<RankingInfo> submitHighScore(int score) async {
    final currentUserId = await HighScoreService.loadUserId();

    final body = await _postJson(
      _updateRankingUri,
      <String, dynamic>{
        'id': currentUserId,
        'userId': currentUserId,
        'user_id': currentUserId,
        'score': score,
        'highScore': score,
        'high_score': score,
      },
    );

    final resolvedUserId =
        _readInt(body, const ['id', 'userId', 'user_id']) ?? currentUserId;
    final resolvedRank = _readInt(
      body,
      const ['rank', 'myRank', 'my_rank', 'ranking'],
    );
    final resolvedScore = _readInt(
          body,
          const ['score', 'highScore', 'high_score'],
        ) ??
        score;

    if (resolvedUserId > 0) {
      await HighScoreService.saveUserId(resolvedUserId);
    }

    return RankingInfo(
      userId: resolvedUserId,
      rank: resolvedRank,
      score: resolvedScore,
      isRegistered: resolvedUserId > 0,
    );
  }

  static Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final response = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Ranking API failed (${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{'data': decoded};
  }

  static int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
      if (value is num) {
        return value != 0;
      }
    }
    return null;
  }

  static String debugErrorMessage(Object error, [StackTrace? stackTrace]) {
    debugPrint('RankingService error: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
    return error.toString();
  }
}
