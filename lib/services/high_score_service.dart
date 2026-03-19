import 'package:shared_preferences/shared_preferences.dart';

class PlayCountResult {
  const PlayCountResult({
    required this.shouldShowRewardAd,
    required this.nextPlayCount,
  });

  final bool shouldShowRewardAd;
  final int nextPlayCount;
}

class HighScoreService {
  static const String _keyHighScore = 'four_color_game_high_score';
  static const String _keyUserId = 'four_color_game_user_id';
  static const String _keyPlayCount = 'four_color_game_play_count';

  static Future<int> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyHighScore) ?? 0;
  }

  static Future<void> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHighScore, score);
  }

  static Future<int> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId) ?? 0;
  }

  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  static Future<int> loadPlayCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPlayCount) ?? 0;
  }

  static Future<void> savePlayCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPlayCount, count);
  }

  static Future<PlayCountResult> registerPlayAndCheckRewardAd() async {
    final currentCount = await loadPlayCount();

    if (currentCount == 3) {
      await savePlayCount(1);
      return const PlayCountResult(
        shouldShowRewardAd: true,
        nextPlayCount: 1,
      );
    }

    final nextCount = currentCount + 1;
    await savePlayCount(nextCount);
    return PlayCountResult(
      shouldShowRewardAd: false,
      nextPlayCount: nextCount,
    );
  }
}
