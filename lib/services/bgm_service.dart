import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BgmService {
  BgmService._();

  static final BgmService instance = BgmService._();

  static const String _bgmEnabledKey = 'four_color_game_bgm_enabled';
  static const String _seEnabledKey = 'four_color_game_se_enabled';

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _purpleSePlayer = AudioPlayer();
  final AudioPlayer _blackSePlayer = AudioPlayer();

  bool _initialized = false;
  bool _isEnabled = true;
  bool _isSeEnabled = true;
  bool _sourcePrepared = false;
  bool _pluginAvailable = true;

  bool get isEnabled => _isEnabled;
  bool get isSeEnabled => _isSeEnabled;
  bool get isAvailable => _pluginAvailable;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_bgmEnabledKey) ?? true;
    _isSeEnabled = prefs.getBool(_seEnabledKey) ?? true;

    try {
      await _configureAudioContext();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _purpleSePlayer.setReleaseMode(ReleaseMode.stop);
      await _blackSePlayer.setReleaseMode(ReleaseMode.stop);

      if (!kIsWeb) {
        await _purpleSePlayer.setPlayerMode(PlayerMode.lowLatency);
        await _blackSePlayer.setPlayerMode(PlayerMode.lowLatency);
      }

      await _prepareSource();

      if (_isEnabled) {
        await _bgmPlayer.resume();
      }
    } on MissingPluginException catch (e, st) {
      _pluginAvailable = false;
      debugPrint('BGM plugin is not available: $e');
      debugPrintStack(stackTrace: st);
    } catch (e, st) {
      debugPrint('BGM init failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _configureAudioContext() async {
    if (kIsWeb) return;

    // iPhone / iPad のサイレントスイッチを尊重しつつ、
    // BGM と SE が同じアプリ内で共存しやすい設定にする。
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          respectSilence: true,
          stayAwake: false,
        ).build(),
      );
    }
  }

  Future<void> _prepareSource() async {
    if (_sourcePrepared || !_pluginAvailable) return;
    await _bgmPlayer.setSource(AssetSource('BGM.mp3'));
    _sourcePrepared = true;
  }

  Future<void> _resumeBgmAfterSe(Duration delay) async {
    if (!_pluginAvailable || !_isEnabled) {
      return;
    }

    await Future<void>.delayed(delay);

    if (!_pluginAvailable || !_isEnabled) {
      return;
    }

    try {
      await _prepareSource();
      await _bgmPlayer.resume();
    } on MissingPluginException catch (e, st) {
      _pluginAvailable = false;
      debugPrint('BGM resume after SE failed (plugin missing): $e');
      debugPrintStack(stackTrace: st);
    } catch (e, st) {
      debugPrint('BGM resume after SE failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _playSeAsset(
    AudioPlayer player,
    String assetName, {
    required String debugLabel,
    required Duration bgmResumeDelay,
  }) async {
    try {
      await init();
      if (!_pluginAvailable || !_isSeEnabled) return;

      await player.stop();
      await player.play(AssetSource(assetName));

      unawaited(_resumeBgmAfterSe(bgmResumeDelay));
    } on MissingPluginException catch (e, st) {
      _pluginAvailable = false;
      debugPrint('$debugLabel plugin is not available: $e');
      debugPrintStack(stackTrace: st);
    } catch (e, st) {
      debugPrint('$debugLabel failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> playPurpleSe() async {
    await _playSeAsset(
      _purpleSePlayer,
      'purple.wav',
      debugLabel: 'Purple SE',
      bgmResumeDelay: const Duration(milliseconds: 220),
    );
  }

  Future<void> playBlackSe() async {
    await _playSeAsset(
      _blackSePlayer,
      'TAP.wav',
      debugLabel: 'Black SE',
      bgmResumeDelay: const Duration(milliseconds: 80),
    );
  }

  Future<void> setSeEnabled(bool enabled) async {
    _isSeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seEnabledKey, enabled);
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = enabled;
    await prefs.setBool(_bgmEnabledKey, enabled);

    if (!_pluginAvailable) return;

    try {
      if (enabled) {
        await _prepareSource();
        await _bgmPlayer.resume();
      } else {
        await _bgmPlayer.pause();
      }
    } on MissingPluginException catch (e, st) {
      _pluginAvailable = false;
      debugPrint('BGM plugin is not available on toggle: $e');
      debugPrintStack(stackTrace: st);
    } catch (e, st) {
      debugPrint('BGM toggle failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> handleLifecycleChange(AppLifecycleState state) async {
    if (!_initialized || !_isEnabled || !_pluginAvailable) return;

    try {
      switch (state) {
        case AppLifecycleState.resumed:
          await _prepareSource();
          await _bgmPlayer.resume();
          break;
        case AppLifecycleState.inactive:
        case AppLifecycleState.hidden:
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
          await _bgmPlayer.pause();
          break;
      }
    } catch (e, st) {
      debugPrint('BGM lifecycle handling failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> dispose() async {
    if (!_pluginAvailable) return;
    try {
      await _bgmPlayer.dispose();
    } catch (_) {}
    try {
      await _purpleSePlayer.dispose();
    } catch (_) {}
    try {
      await _blackSePlayer.dispose();
    } catch (_) {}
  }
}
