import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/game_card_data.dart';
import '../services/ad_service.dart';
import '../services/high_score_service.dart';
import '../services/ranking_service.dart';
import '../services/vibration_service.dart';
import '../widgets/banner_ad_placeholder.dart';
import '../widgets/burst_flight_overlay.dart';
import '../widgets/game_card_tile.dart';

import '../services/bgm_service.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final math.Random _random = math.Random();

  final GlobalKey _stackKey = GlobalKey();
  final List<GlobalKey> _cardKeys = List.generate(4, (_) => GlobalKey());
  final Map<CardColorType, GlobalKey> _scoreKeys = {
    for (final color in CardColorType.values) color: GlobalKey(),
  };

  late List<GameCardData> _cards;
  late Map<CardColorType, int> _colorScores;

  int _turn = 0;
  int _score = 0;
  int _highScore = 0;
  int _lastRecoveryHandledTurn = -1;

  bool _isAnimating = false;
  bool _isGameOver = false;
  bool _isRecoveryTurnPending = false;
  bool _isRecoveryDialogVisible = false;
  bool _isInputLocked = false;

  CardColorType? _highlightedColor;
  bool _scoreHighlighted = false;

  List<BurstEffectData> _activeEffects = const [];
  int? _blockingEffectId;
  int _nextEffectId = 0;

  bool _showPerfectBonus = false;
  String _perfectBonusText = '';
  String _perfectBonusSubText = '';
  CardColorType? _perfectBonusColor;
  int _perfectBonusTicket = 0;

  CardColorType? _perfectResetEffectColor;
  int _perfectResetEffectTicket = 0;

  bool _isRestartingFromRewardAd = false;

  @override
  void initState() {
    super.initState();
    _resetState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final value = await HighScoreService.loadHighScore();
    if (!mounted) return;
    setState(() {
      _highScore = value;
    });
  }

  Future<void> _saveAndSyncHighScore(int score) async {
    await HighScoreService.saveHighScore(score);

    if (!mounted) return;
    setState(() {
      _highScore = score;
    });

    try {
      await RankingService.submitHighScore(score);
    } catch (error, stackTrace) {
      RankingService.debugErrorMessage(error, stackTrace);
    }
  }

  void _resetState() {
    _cards = _generateBoard();
    _colorScores = {
      for (final color in CardColorType.values) color: 0,
    };
    _turn = 0;
    _score = 0;
    _lastRecoveryHandledTurn = -1;
    _isAnimating = false;
    _isGameOver = false;
    _isRecoveryTurnPending = false;
    _isRecoveryDialogVisible = false;
    _isInputLocked = false;
    _highlightedColor = null;
    _scoreHighlighted = false;
    _activeEffects = const [];
    _blockingEffectId = null;
    _nextEffectId = 0;
    _showPerfectBonus = false;
    _perfectBonusText = '';
    _perfectBonusSubText = '';
    _perfectBonusColor = null;
    _perfectBonusTicket = 0;
    _perfectResetEffectColor = null;
    _perfectResetEffectTicket = 0;
    _isRestartingFromRewardAd = false;
  }

  void _restartGame() {
    setState(_resetState);
  }

  Future<void> _restartGameWithRewardAd() async {
    if (_isRestartingFromRewardAd) {
      return;
    }

    setState(() {
      _isRestartingFromRewardAd = true;
    });

    await AdService.instance.showRewardedAd(
      onFinished: () async {
        if (!mounted) return;
        _restartGame();
      },
    );

    if (!mounted) return;
    setState(() {
      _isRestartingFromRewardAd = false;
    });
  }

  List<GameCardData> _generateBoard() {
    final cards = <GameCardData>[];
    while (cards.length < 4) {
      cards.add(_randomCard(existingCards: cards));
    }
    return cards;
  }

  GameCardData _randomCard({List<GameCardData> existingCards = const []}) {
    final hasPurple = existingCards.any((card) => card.isChange);
    final candidates = GameCardData.weightedDeck.where((card) {
      if (card.isChange && hasPurple) {
        return false;
      }
      return true;
    }).toList(growable: false);

    return candidates[_random.nextInt(candidates.length)];
  }

  GameCardData _randomReplacementCard(int replacingIndex, List<GameCardData> source) {
    final otherCards = List<GameCardData>.from(source)..removeAt(replacingIndex);
    return _randomCard(existingCards: otherCards);
  }

  String _colorNameJa(CardColorType colorType) {
    switch (colorType) {
      case CardColorType.red:
        return '赤色';
      case CardColorType.blue:
        return '青色';
      case CardColorType.green:
        return '緑色';
      case CardColorType.yellow:
        return '黄色';
    }
  }

  BurstEffectData? _buildEffectData(int cardIndex, GameCardData selectedCard) {
    if (!selectedCard.isNumber && !selectedCard.isChange) {
      return null;
    }

    final stackContext = _stackKey.currentContext;
    final cardContext = _cardKeys[cardIndex].currentContext;

    if (stackContext == null || cardContext == null) {
      return null;
    }

    final stackBox = stackContext.findRenderObject() as RenderBox?;
    final cardBox = cardContext.findRenderObject() as RenderBox?;

    if (stackBox == null || cardBox == null) {
      return null;
    }

    final cardCenter = cardBox.localToGlobal(
      Offset(cardBox.size.width / 2, cardBox.size.height / 2),
      ancestor: stackBox,
    );

    Offset endCenter = cardCenter;
    if (selectedCard.isNumber && selectedCard.colorType != null) {
      final scoreContext = _scoreKeys[selectedCard.colorType!]?.currentContext;
      final scoreBox = scoreContext?.findRenderObject() as RenderBox?;
      if (scoreBox == null) {
        return null;
      }
      endCenter = scoreBox.localToGlobal(
        Offset(scoreBox.size.width / 2, scoreBox.size.height / 2),
        ancestor: stackBox,
      );
    }

    return BurstEffectData(
      id: _nextEffectId++,
      card: selectedCard,
      startCenter: cardCenter,
      endCenter: endCenter,
      cardSize: cardBox.size,
    );
  }

  int _recoveryGaugeLitCount() {
    final isRecoveryNow = (_isRecoveryTurnPending || _isRecoveryDialogVisible) &&
        _turn > 0 &&
        _turn % 6 == 0;
    if (isRecoveryNow) {
      return 6;
    }
    return _turn % 6;
  }

  Future<void> _onTapCard(int index) async {
    if (_isInputLocked ||
        _isAnimating ||
        _isGameOver ||
        _isRecoveryTurnPending ||
        _isRecoveryDialogVisible) {
      return;
    }

    final selectedCard = _cards[index];
    final effect = (selectedCard.isNumber || selectedCard.isChange)
        ? _buildEffectData(index, selectedCard)
        : null;
    final nextCards = List<GameCardData>.from(_cards);
    final nextTurn = _turn + 1;
    final shouldHoldForRecoveryTap = nextTurn % 6 == 0;
    final shouldBlockUntilEffectCompletes =
        ((selectedCard.isChange || shouldHoldForRecoveryTap) && effect != null);

    if (selectedCard.isChange) {
      unawaited(BgmService.instance.playPurpleSe());
      nextCards
        ..clear()
        ..addAll(_generateBoard());
    } else if (selectedCard.isBlack) {
      unawaited(BgmService.instance.playBlackSe());
      for (var i = 0; i < nextCards.length; i++) {
        if (i == index) continue;
        final card = nextCards[i];
        if (!card.isNumber || card.value == null) continue;

        final nextValue = selectedCard.isBlackUp
            ? math.min(5, card.value! + 1)
            : math.max(1, card.value! - 1);
        nextCards[i] = card.copyWithValue(nextValue);
      }
      nextCards[index] = _randomReplacementCard(index, nextCards);
    } else {
      nextCards[index] = _randomReplacementCard(index, nextCards);
    }

    setState(() {
      _cards = nextCards;
      _turn = nextTurn;
      _highlightedColor = null;
      _scoreHighlighted = false;
      if (effect != null) {
        _activeEffects = [..._activeEffects, effect];
      }
      _isAnimating = shouldBlockUntilEffectCompletes;
      _blockingEffectId = shouldBlockUntilEffectCompletes ? effect?.id : null;
      _isInputLocked = shouldHoldForRecoveryTap || selectedCard.isChange;
    });

    if (selectedCard.isChange) {
      if (!shouldBlockUntilEffectCompletes) {
        await _afterActionTurnEnd();
      }
      return;
    }

    if (selectedCard.isBlack) {
      await _afterActionTurnEnd();
      return;
    }

    await _resolveNumberCardSelection(
      selectedCard,
      waitForRecoveryAnimation: shouldHoldForRecoveryTap && effect != null,
    );
  }

  Future<void> _showScoreBonusBanner({
    required CardColorType colorType,
    required String text,
    required String subText,
  }) async {
    final ticket = ++_perfectBonusTicket;

    await VibrationService.instance.vibrateBonus();

    if (!mounted) return;
    setState(() {
      _showPerfectBonus = true;
      _perfectBonusColor = colorType;
      _perfectBonusText = text;
      _perfectBonusSubText = subText;
    });

    await Future.delayed(const Duration(milliseconds: 980));

    if (!mounted || ticket != _perfectBonusTicket) return;
    setState(() {
      _showPerfectBonus = false;
    });
  }

  Future<void> _showPerfectBonusBanner(CardColorType colorType) {
    return _showScoreBonusBanner(
      colorType: colorType,
      text: '[${_colorNameJa(colorType)}] ぴったりボーナス +10',
      subText: '${_colorNameJa(colorType)}ポイントが 5 に戻る',
    );
  }

  Future<void> _showAll9BonusBanner(CardColorType colorType) {
    return _showScoreBonusBanner(
      colorType: colorType,
      text: 'ALL9ボーナス +999',
      subText: '4色すべてのポイントが 9 でそろった',
    );
  }

  Future<void> _showHalfMaxBonusBanner(CardColorType colorType) {
    return _showScoreBonusBanner(
      colorType: colorType,
      text: 'HALF MAXボーナス +100',
      subText: '4色の合計ポイントが 20 に到達した',
    );
  }

  Future<void> _playPerfectResetEffect(CardColorType colorType) async {
    final ticket = ++_perfectResetEffectTicket;

    if (!mounted) return;
    setState(() {
      _perfectResetEffectColor = colorType;
      _highlightedColor = colorType;
    });

    await Future.delayed(const Duration(milliseconds: 720));

    if (!mounted || ticket != _perfectResetEffectTicket) return;
    setState(() {
      if (_perfectResetEffectColor == colorType) {
        _perfectResetEffectColor = null;
      }
      if (_highlightedColor == colorType) {
        _highlightedColor = null;
      }
    });
  }

  Future<void> _resolveNumberCardSelection(
    GameCardData selectedCard, {
    required bool waitForRecoveryAnimation,
  }) async {
    if (!selectedCard.isNumber || selectedCard.colorType == null) {
      if (!mounted) return;
      setState(() {
        _isAnimating = false;
        _blockingEffectId = null;
        _isInputLocked = false;
      });
      return;
    }

    final colorType = selectedCard.colorType!;
    final selectedValue = selectedCard.value ?? 0;
    final beforeHighScore = _highScore;
    final baseColorScore = _colorScores[colorType] ?? 0;
    final rawNextColorScore = baseColorScore + selectedValue;
    final earnedPerfectBonus = rawNextColorScore == 10;
    final perfectBonusScore = earnedPerfectBonus ? 10 : 0;
    final isGameOver = rawNextColorScore >= 11;
    final displayColorScore = earnedPerfectBonus && !isGameOver ? 5 : rawNextColorScore;

    final nextColorScores = Map<CardColorType, int>.from(_colorScores)
      ..[colorType] = displayColorScore;
    final earnedAll9Bonus =
        !isGameOver && CardColorType.values.every((color) => (nextColorScores[color] ?? 0) == 9);
    final all9BonusScore = earnedAll9Bonus ? 999 : 0;
    final totalColorScore = nextColorScores.values.fold<int>(0, (sum, value) => sum + value);
    final earnedHalfMaxBonus = !isGameOver && totalColorScore == 20;
    final halfMaxBonusScore = earnedHalfMaxBonus ? 100 : 0;
    final nextScore =
        _score + selectedValue + perfectBonusScore + all9BonusScore + halfMaxBonusScore;
    final isNewHighScore = isGameOver && nextScore > beforeHighScore;

    if (!mounted) return;

    setState(() {
      _colorScores[colorType] = displayColorScore;
      _score = nextScore;
      _highlightedColor = colorType;
      _scoreHighlighted = true;
      if (isGameOver) {
        _isGameOver = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (_perfectResetEffectColor == colorType) return;
      setState(() {
        if (_highlightedColor == colorType) {
          _highlightedColor = null;
        }
        _scoreHighlighted = false;
      });
    });

    if (earnedPerfectBonus && !isGameOver) {
      unawaited(_playPerfectResetEffect(colorType));
    }

    final bonusBanners = <Future<void> Function()>[];
    if (earnedPerfectBonus && !isGameOver) {
      bonusBanners.add(() => _showPerfectBonusBanner(colorType));
    }
    if (earnedAll9Bonus) {
      bonusBanners.add(() => _showAll9BonusBanner(colorType));
    }
    if (earnedHalfMaxBonus) {
      bonusBanners.add(() => _showHalfMaxBonusBanner(colorType));
    }
    if (bonusBanners.isNotEmpty) {
      unawaited(() async {
        for (final showBanner in bonusBanners) {
          await showBanner();
          await Future.delayed(const Duration(milliseconds: 80));
        }
      }());
    }

    if (isGameOver) {
      if (isNewHighScore) {
        await _saveAndSyncHighScore(nextScore);
      }

      if (!mounted) return;
      await _showGameOverDialog(
        isNewHighScore: isNewHighScore,
        finalScore: nextScore,
      );
      return;
    }

    if (!waitForRecoveryAnimation) {
      await _afterActionTurnEnd();
    }
  }

  Future<void> _handleEffectCompleted(int effectId) async {
    final wasBlocking = _blockingEffectId == effectId;

    if (!mounted) return;
    setState(() {
      _activeEffects = _activeEffects.where((effect) => effect.id != effectId).toList();
      if (wasBlocking) {
        _isAnimating = false;
        _blockingEffectId = null;
      }
    });

    if (!wasBlocking || _isGameOver) {
      return;
    }

    await _afterActionTurnEnd();
  }

  Future<void> _afterActionTurnEnd() async {
    if (!mounted) return;

    if (_turn % 6 != 0) {
      setState(() {
        _isInputLocked = false;
      });
      return;
    }

    if (_isRecoveryTurnPending || _isRecoveryDialogVisible) {
      return;
    }

    if (_lastRecoveryHandledTurn == _turn) {
      setState(() {
        _isInputLocked = false;
      });
      return;
    }

    setState(() {
      _isRecoveryTurnPending = true;
      _isRecoveryDialogVisible = true;
      _lastRecoveryHandledTurn = _turn;
    });

    await _showRecoveryDialog();
  }

  Widget _buildGlassPanel({
    required Widget child,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(26)),
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double blurSigma = 18,
    List<double> fillOpacities = const [0.16, 0.08],
    double borderOpacity = 0.22,
    double shadowOpacity = 0.22,
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(fillOpacities[0]),
                Colors.white.withOpacity(fillOpacities[1]),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(shadowOpacity),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildRecoveryButton(CardColorType colorType) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorType.color.withOpacity(0.92),
              colorType.darkColor.withOpacity(0.96),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.34),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colorType.color.withOpacity(0.35),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (!_isRecoveryDialogVisible) return;
              setState(() {
                _colorScores[colorType] = 0;
                _isRecoveryTurnPending = false;
                _isInputLocked = false;
              });
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    colorType.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '0 に戻す',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRecoveryDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.16),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildGlassPanel(
            blurSigma: 5.5,
            fillOpacities: const [0.08, 0.03],
            borderOpacity: 0.18,
            shadowOpacity: 0.14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '回復ターン',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '0点に戻す色を選択してください',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _buildRecoveryButton(CardColorType.red),
                    const SizedBox(width: 10),
                    _buildRecoveryButton(CardColorType.blue),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildRecoveryButton(CardColorType.green),
                    const SizedBox(width: 10),
                    _buildRecoveryButton(CardColorType.yellow),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _isRecoveryDialogVisible = false;
      _isRecoveryTurnPending = false;
      _isInputLocked = false;
    });
  }

  Future<void> _showGameOverDialog({
    required bool isNewHighScore,
    required int finalScore,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('GAME OVER'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('スコア：$finalScore'),
              const SizedBox(height: 8),
              Text('ハイスコア：$_highScore'),
              if (isNewHighScore) ...[
                const SizedBox(height: 12),
                const Text(
                  'NEW HIGH SCORE!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isRestartingFromRewardAd
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      await _restartGameWithRewardAd();
                    },
              child: Text(_isRestartingFromRewardAd ? '広告表示中...' : 'もう一度'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).popUntil((route) => route.isFirst);
              },
              child: const Text('タイトルへ'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoreBox(CardColorType colorType) {
    final value = _colorScores[colorType] ?? 0;
    final highlighted = _highlightedColor == colorType;
    final perfectResetActive = _perfectResetEffectColor == colorType;

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: perfectResetActive ? 1.06 : 1.0,
      child: AnimatedContainer(
        key: _scoreKeys[colorType],
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorType.color.withOpacity(highlighted ? 0.98 : 0.9),
              colorType.darkColor.withOpacity(highlighted ? 0.99 : 0.96),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(highlighted ? 0.9 : 0.62),
            width: highlighted ? 2.2 : 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: colorType.color.withOpacity(highlighted ? 0.5 : 0.3),
              blurRadius: highlighted ? 18 : 12,
              spreadRadius: highlighted ? 2 : 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                colorType.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryGauge() {
    const recoveryCycle = 6;
    final litCount = _recoveryGaugeLitCount();
    final isRecoveryNow = litCount == recoveryCycle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            color: isRecoveryNow ? Colors.amberAccent : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
          child: Text(isRecoveryNow ? '回復' : 'あと${recoveryCycle - litCount}'),
        ),
        const SizedBox(height: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(recoveryCycle, (displayIndex) {
            final stepValue = recoveryCycle - displayIndex;
            final isLit = litCount >= stepValue;
            final isTopCell = stepValue == recoveryCycle;

            return Padding(
              padding: EdgeInsets.only(
                bottom: displayIndex == recoveryCycle - 1 ? 0 : 8,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isRecoveryNow && isTopCell ? 28 : 24,
                height: isRecoveryNow && isTopCell ? 28 : 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: isLit
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isRecoveryNow && isTopCell
                              ? [
                                  Colors.amberAccent.withOpacity(0.98),
                                  Colors.deepOrangeAccent.withOpacity(0.94),
                                ]
                              : [
                                  Colors.cyanAccent.withOpacity(0.95),
                                  Colors.blueAccent.withOpacity(0.9),
                                ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.04),
                          ],
                        ),
                  border: Border.all(
                    color: isLit
                        ? Colors.white.withOpacity(0.9)
                        : Colors.white.withOpacity(0.2),
                    width: isRecoveryNow && isTopCell ? 1.8 : 1.2,
                  ),
                  boxShadow: isLit
                      ? [
                          BoxShadow(
                            color: (isRecoveryNow && isTopCell
                                    ? Colors.orangeAccent
                                    : Colors.cyanAccent)
                                .withOpacity(0.55),
                            blurRadius: isRecoveryNow && isTopCell ? 20 : 14,
                            spreadRadius: isRecoveryNow && isTopCell ? 2 : 1,
                          ),
                        ]
                      : [],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPerfectBonusOverlay() {
    final bonusColor = _perfectBonusColor ?? CardColorType.yellow;

    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 260),
            offset: _showPerfectBonus ? Offset.zero : const Offset(0, -0.35),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: _showPerfectBonus ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.only(top: 138),
                child: _buildGlassPanel(
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: bonusColor.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: bonusColor.color.withOpacity(0.65),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _perfectBonusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _perfectBonusSubText,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.82),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canTap = !_isInputLocked &&
        !_isAnimating &&
        !_isGameOver &&
        !_isRecoveryTurnPending &&
        !_isRecoveryDialogVisible;

    return Scaffold(
      backgroundColor: const Color(0xFF11131A),
      body: SafeArea(
        child: Stack(
          key: _stackKey,
          children: [
            Column(
              children: [
                const BannerAdPlaceholder(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildScoreBox(CardColorType.red)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildScoreBox(CardColorType.blue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildScoreBox(CardColorType.green)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildScoreBox(CardColorType.yellow)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: canTap
                              ? () {
                                  Navigator.maybePop(context);
                                }
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 56),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _scoreHighlighted
                                ? Colors.orange.withOpacity(0.18)
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _scoreHighlighted
                                  ? Colors.orange
                                  : Colors.white24,
                            ),
                            boxShadow: _scoreHighlighted
                                ? [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.45),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SCORE：$_score',
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'HIGH SCORE：$_highScore',
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 372),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 48,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _buildRecoveryGauge(),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 0.82,
                                    child: GridView.builder(
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: 4,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                        childAspectRatio: 0.82,
                                      ),
                                      itemBuilder: (context, index) {
                                        return GameCardTile(
                                          card: _cards[index],
                                          cellKey: _cardKeys[index],
                                          onTap: canTap ? () => _onTapCard(index) : null,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            for (final effect in _activeEffects)
              Positioned.fill(
                child: BurstFlightOverlay(
                  key: ValueKey(effect.id),
                  effect: effect,
                  onCompleted: () async {
                    await _handleEffectCompleted(effect.id);
                  },
                ),
              ),
            if (_isAnimating || _isInputLocked || _isRecoveryTurnPending || _isRecoveryDialogVisible)
              const Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: ColoredBox(color: Colors.transparent),
                ),
              ),
            _buildPerfectBonusOverlay(),
          ],
        ),
      ),
    );
  }
}
