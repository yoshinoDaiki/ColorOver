import 'package:shared_preferences/shared_preferences.dart';

class HighScoreService {
  static const String _keyHighScore = 'four_color_game_high_score';
  static const String _keyUserId = 'four_color_game_user_id';

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
}
