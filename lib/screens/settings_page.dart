import 'package:flutter/material.dart';

import '../services/bgm_service.dart';
import '../services/vibration_service.dart';
import 'privacy_policy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool soundOn = true;
  bool seOn = true;
  bool vibrationOn = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await BgmService.instance.init();
    final enabled = await VibrationService.instance.isEnabled();
    if (!mounted) return;
    setState(() {
      soundOn = BgmService.instance.isEnabled;
      seOn = BgmService.instance.isSeEnabled;
      vibrationOn = enabled;
    });
  }

  Future<void> _toggleBgm(bool value) async {
    setState(() {
      soundOn = value;
    });

    await BgmService.instance.setEnabled(value);
  }

  Future<void> _toggleSe(bool value) async {
    setState(() {
      seOn = value;
    });

    await BgmService.instance.setSeEnabled(value);
  }

  Future<void> _toggleVibration(bool value) async {
    setState(() {
      vibrationOn = value;
    });

    await VibrationService.instance.setEnabled(value);
  }

  Future<void> _goToPrivacyPolicy() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgmAvailable = BgmService.instance.isAvailable;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.maybePop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'BGM',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        bgmAvailable
                            ? 'ゲーム全体のBGMを再生します'
                            : '現在の実行環境では音声プラグインを利用できません',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      value: soundOn,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: bgmAvailable ? _toggleBgm : null,
                    ),
                    SwitchListTile(
                      title: const Text(
                        'SE',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        '紫カードと黒カードの効果音を再生します',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: seOn,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: bgmAvailable ? _toggleSe : null,
                    ),
                    SwitchListTile(
                      title: const Text(
                        'バイブレーション',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'ボーナス獲得時に短く振動します',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: vibrationOn,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: _toggleVibration,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _goToPrivacyPolicy,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'プライバシーポリシー',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
