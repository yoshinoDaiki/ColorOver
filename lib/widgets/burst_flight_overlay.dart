import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/game_card_data.dart';
import 'game_card_tile.dart';

class BurstEffectData {
  const BurstEffectData({
    required this.id,
    required this.card,
    required this.startCenter,
    required this.endCenter,
    required this.cardSize,
  });

  final int id;
  final GameCardData card;
  final Offset startCenter;
  final Offset endCenter;
  final Size cardSize;
}

class BurstFlightOverlay extends StatefulWidget {
  const BurstFlightOverlay({
    super.key,
    required this.effect,
    required this.onCompleted,
  });

  final BurstEffectData effect;
  final VoidCallback onCompleted;

  @override
  State<BurstFlightOverlay> createState() => _BurstFlightOverlayState();
}

class _BurstFlightOverlayState extends State<BurstFlightOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.effect.card.isChange ? 720 : 650),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _lerpOffset(Offset a, Offset b, double t) {
    return Offset(
      a.dx + (b.dx - a.dx) * t,
      a.dy + (b.dy - a.dy) * t,
    );
  }

  Widget _buildNumberEffect(BurstEffectData effect, double t) {
    final flyT = Curves.easeInOutCubic.transform(t);
    final vanishT = Curves.easeOutQuart.transform(t);

    final orbCenter = _lerpOffset(
      effect.startCenter,
      effect.endCenter,
      flyT,
    );

    final cardOpacity = (1 - (vanishT * 1.8)).clamp(0.0, 1.0);
    final cardScale = 1 - (vanishT * 0.28);

    final ringOpacity = (1 - (t * 2.2)).clamp(0.0, 1.0);
    final ringSize = (effect.cardSize.shortestSide * (0.65 + t * 0.9));

    return Stack(
      children: [
        Positioned(
          left: effect.startCenter.dx - effect.cardSize.width / 2,
          top: effect.startCenter.dy - effect.cardSize.height / 2,
          width: effect.cardSize.width,
          height: effect.cardSize.height,
          child: Transform.scale(
            scale: cardScale,
            child: Opacity(
              opacity: cardOpacity,
              child: GameCardTile(card: effect.card),
            ),
          ),
        ),
        Positioned(
          left: effect.startCenter.dx - ringSize / 2,
          top: effect.startCenter.dy - ringSize / 2,
          width: ringSize,
          height: ringSize,
          child: Opacity(
            opacity: ringOpacity,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: effect.card.displayColor.withOpacity(0.95),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: effect.card.displayColor.withOpacity(0.55),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        for (int i = 0; i < 6; i++)
          Positioned(
            left: effect.startCenter.dx +
                math.cos((math.pi / 3) * i) * (10 + 26 * t) -
                4,
            top: effect.startCenter.dy +
                math.sin((math.pi / 3) * i) * (10 + 26 * t) -
                4,
            width: 8,
            height: 8,
            child: Opacity(
              opacity: (1 - t * 2).clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: effect.card.displayColor.withOpacity(0.7),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          left: orbCenter.dx - 16,
          top: orbCenter.dy - 16,
          width: 32,
          height: 32,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: effect.card.displayColor.withOpacity(0.95),
                  blurRadius: 22,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effect.card.displayColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurpleEffect(BurstEffectData effect, double t) {
    final startLeft = effect.startCenter.dx - effect.cardSize.width / 2;
    final startTop = effect.startCenter.dy - effect.cardSize.height / 2;
    final fadeOut = (1 - Curves.easeInQuart.transform(t)).clamp(0.0, 1.0);
    final split = Curves.easeOutCubic.transform(t) * (effect.cardSize.width * 0.22);
    final verticalScatter = Curves.easeOutCubic.transform(t) * 10;
    final shake = math.sin(t * math.pi * 18) * (1 - t) * 8;
    final flashOpacity = (1 - (t * 1.35)).clamp(0.0, 1.0);
    final glowScale = 1 + (t * 0.45);

    return Stack(
      children: [
        Positioned(
          left: startLeft - 16,
          top: startTop - 16,
          width: effect.cardSize.width + 32,
          height: effect.cardSize.height + 32,
          child: IgnorePointer(
            child: Transform.scale(
              scale: glowScale,
              child: Opacity(
                opacity: flashOpacity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.30),
                        const Color(0xFFE5D4FF).withOpacity(0.24),
                        effect.card.displayColor.withOpacity(0.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: effect.card.displayColor.withOpacity(0.50),
                        blurRadius: 28,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: startLeft,
          top: startTop,
          width: effect.cardSize.width,
          height: effect.cardSize.height,
          child: Opacity(
            opacity: fadeOut,
            child: Stack(
              children: [
                Transform.translate(
                  offset: Offset(-split + shake, -verticalScatter * 0.28),
                  child: ClipPath(
                    clipper: _PurpleLeftShardClipper(),
                    child: GameCardTile(card: effect.card),
                  ),
                ),
                Transform.translate(
                  offset: Offset(split + shake, verticalScatter * 0.18),
                  child: ClipPath(
                    clipper: _PurpleRightShardClipper(),
                    child: GameCardTile(card: effect.card),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PurpleElectricPainter(
                      progress: t,
                      color: effect.card.displayColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        for (int i = 0; i < 12; i++)
          Positioned(
            left: effect.startCenter.dx +
                math.cos((math.pi * 2 / 12) * i + t * 1.8) *
                    (16 + 44 * Curves.easeOutCubic.transform(t)) -
                3,
            top: effect.startCenter.dy +
                math.sin((math.pi * 2 / 12) * i + t * 1.3) *
                    (12 + 32 * Curves.easeOutCubic.transform(t)) -
                3,
            width: 6,
            height: 6,
            child: Opacity(
              opacity: (1 - t * 1.7).clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: i.isEven ? Colors.white : const Color(0xFFE5D4FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: effect.card.displayColor.withOpacity(0.65),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effect = widget.effect;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            children: [
              if (effect.card.isChange)
                _buildPurpleEffect(effect, t)
              else
                _buildNumberEffect(effect, t),
            ],
          );
        },
      ),
    );
  }
}

class _PurpleLeftShardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.54, 0)
      ..lineTo(size.width * 0.47, size.height * 0.16)
      ..lineTo(size.width * 0.56, size.height * 0.31)
      ..lineTo(size.width * 0.44, size.height * 0.48)
      ..lineTo(size.width * 0.54, size.height * 0.66)
      ..lineTo(size.width * 0.40, size.height * 0.84)
      ..lineTo(size.width * 0.48, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PurpleRightShardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(size.width * 0.54, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.48, size.height)
      ..lineTo(size.width * 0.60, size.height * 0.84)
      ..lineTo(size.width * 0.50, size.height * 0.66)
      ..lineTo(size.width * 0.62, size.height * 0.48)
      ..lineTo(size.width * 0.52, size.height * 0.31)
      ..lineTo(size.width * 0.60, size.height * 0.16)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PurpleElectricPainter extends CustomPainter {
  const _PurpleElectricPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final glowOpacity = (1 - progress * 1.15).clamp(0.0, 1.0);
    if (glowOpacity <= 0) return;

    final crackPoints = <Offset>[
      Offset(size.width * 0.52, 0),
      Offset(size.width * 0.46, size.height * 0.14),
      Offset(size.width * 0.56, size.height * 0.28),
      Offset(size.width * 0.45, size.height * 0.45),
      Offset(size.width * 0.58, size.height * 0.63),
      Offset(size.width * 0.43, size.height * 0.81),
      Offset(size.width * 0.50, size.height),
    ];

    final crackPath = Path()..moveTo(crackPoints.first.dx, crackPoints.first.dy);
    for (final point in crackPoints.skip(1)) {
      crackPath.lineTo(point.dx, point.dy);
    }

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lerpDouble(10, 4, progress)!
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withOpacity(glowOpacity * 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lerpDouble(3.6, 2.2, progress)!
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withOpacity(glowOpacity * 0.92);

    final hotPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lerpDouble(1.8, 1.1, progress)!
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withOpacity(glowOpacity * 0.95);

    canvas.drawPath(crackPath, glowPaint);
    canvas.drawPath(crackPath, corePaint);
    canvas.drawPath(crackPath, hotPaint);

    final branches = <List<Offset>>[
      [
        Offset(size.width * 0.48, size.height * 0.18),
        Offset(size.width * 0.30, size.height * 0.11),
        Offset(size.width * 0.22, size.height * 0.20),
      ],
      [
        Offset(size.width * 0.55, size.height * 0.30),
        Offset(size.width * 0.73, size.height * 0.22),
        Offset(size.width * 0.82, size.height * 0.32),
      ],
      [
        Offset(size.width * 0.47, size.height * 0.56),
        Offset(size.width * 0.26, size.height * 0.62),
        Offset(size.width * 0.18, size.height * 0.74),
      ],
      [
        Offset(size.width * 0.56, size.height * 0.70),
        Offset(size.width * 0.75, size.height * 0.63),
        Offset(size.width * 0.86, size.height * 0.76),
      ],
    ];

    for (final branch in branches) {
      final path = Path()..moveTo(branch.first.dx, branch.first.dy);
      for (final point in branch.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, corePaint);
      canvas.drawPath(path, hotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PurpleElectricPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
