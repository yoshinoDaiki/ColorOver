import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../services/high_score_service.dart';
import '../services/ranking_service.dart';
import 'game_page.dart';
import 'rule_page.dart';
import 'settings_page.dart';

class TitlePage extends StatefulWidget {
  const TitlePage({super.key});

  @override
  State<TitlePage> createState() => _TitlePageState();
}

class _TitlePageState extends State<TitlePage> {
  bool _isStartingGame = false;
  bool _isLoadingInfo = true;

  int _localHighScore = 0;
  int _userId = 0;
  int? _myRank;
  String? _rankingError;

  @override
  void initState() {
    super.initState();
    _loadTitleInfo();
  }

  Future<void> _goTo(BuildContext context, Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (!mounted) return;
    await _loadTitleInfo();
  }

  Future<void> _loadTitleInfo() async {
    setState(() {
      _isLoadingInfo = true;
      _rankingError = null;
    });

    final localHighScore = await HighScoreService.loadHighScore();
    final localUserId = await HighScoreService.loadUserId();

    int resolvedUserId = localUserId;
    int? resolvedRank;
    String? resolvedError;

    try {
      final ranking = await RankingService.fetchMyRanking();
      resolvedUserId = ranking.userId;
      resolvedRank = ranking.rank;
    } catch (error, stackTrace) {
      resolvedError = RankingService.debugErrorMessage(error, stackTrace);
    }

    if (!mounted) return;
    setState(() {
      _localHighScore = localHighScore;
      _userId = resolvedUserId;
      _myRank = resolvedRank;
      _rankingError = resolvedError;
      _isLoadingInfo = false;
    });
  }

  String _rankLabel() {
    if (_isLoadingInfo) {
      return '取得中...';
    }
    if (_rankingError != null) {
      return '取得失敗';
    }
    if (_userId == 0) {
      return '未登録';
    }
    if (_myRank == null) {
      return '圏外 / 未反映';
    }
    return '${_myRank}位';
  }

  Future<void> _startGameWithReward() async {
    if (_isStartingGame) return;

    setState(() {
      _isStartingGame = true;
    });

    await AdService.instance.showRewardedAd(
      onFinished: () async {
        if (!mounted) return;
        await _goTo(context, const GamePage());
      },
    );

    if (!mounted) return;
    setState(() {
      _isStartingGame = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/title.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: const Text(
                  'assets/title.png を読み込めませんでした。\n'
                  'ファイル配置と pubspec.yaml の assets 設定を確認してください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 700;
                final compactWidth = constraints.maxWidth < 380;
                final compact = compactHeight || compactWidth;

                final titleWidth = compact
                    ? (constraints.maxWidth * 0.76).clamp(230.0, 360.0)
                    : (constraints.maxWidth * 0.84).clamp(300.0, 460.0);
                final topSpacing = compact ? 12.0 : constraints.maxHeight * 0.045;
                final horizontalPadding = compact ? 18.0 : 24.0;
                final buttonSpacing = compact ? 10.0 : 16.0;
                final bottomSpacing = compact ? 12.0 : 24.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topSpacing),
                        Center(
                          child: Image.asset(
                            'assets/title_str.png',
                            width: titleWidth,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        SizedBox(
                          height: compact
                              ? constraints.maxHeight * 0.22
                              : constraints.maxHeight * 0.34,
                        ),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 340),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _HighScoreStatusCard(
                                  highScore: _localHighScore,
                                  rankLabel: _rankLabel(),
                                  compact: compact,
                                ),
                                SizedBox(height: buttonSpacing),
                                _GlassMenuButton(
                                  label: _isStartingGame ? 'AD LOADING...' : 'GAME START',
                                  onTap: _isStartingGame ? null : _startGameWithReward,
                                  compact: compact,
                                ),
                                SizedBox(height: buttonSpacing),
                                _GlassMenuButton(
                                  label: 'RULE',
                                  onTap: () => _goTo(context, const RulePage()),
                                  compact: compact,
                                ),
                                SizedBox(height: buttonSpacing),
                                _GlassMenuButton(
                                  label: 'SETTINGS',
                                  onTap: () => _goTo(context, const SettingsPage()),
                                  compact: compact,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: bottomSpacing),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HighScoreStatusCard extends StatelessWidget {
  const _HighScoreStatusCard({
    required this.highScore,
    required this.rankLabel,
    required this.compact,
  });

  final int highScore;
  final String rankLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18,
            vertical: compact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.26),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.08),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'HIGH SCORE  $highScore',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                'RANKING  $rankLabel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassMenuButton extends StatelessWidget {
  const _GlassMenuButton({
    required this.label,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return SizedBox(
      width: double.infinity,
      height: compact ? 56 : 66,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.white.withValues(alpha: disabled ? 0.08 : 0.12),
            child: InkWell(
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: disabled ? 0.18 : 0.30),
                    width: 1.2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: disabled ? 0.12 : 0.20),
                      Colors.white.withValues(alpha: disabled ? 0.04 : 0.08),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: disabled ? Colors.white70 : Colors.white,
                      fontSize: compact ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
