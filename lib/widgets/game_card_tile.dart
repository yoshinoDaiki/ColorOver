import 'package:flutter/material.dart';

import '../models/game_card_data.dart';

class GameCardTile extends StatelessWidget {
  const GameCardTile({
    super.key,
    required this.card,
    this.onTap,
    this.cellKey,
  });

  final GameCardData card;
  final VoidCallback? onTap;
  final Key? cellKey;

  @override
  Widget build(BuildContext context) {
    final isChange = card.isChange;
    final isBlack = card.isBlack;
    final isSpecial = card.isSpecial;

    return SizedBox(
      key: cellKey,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  card.displayColor.withOpacity(0.97),
                  card.displayDarkColor.withOpacity(0.97),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: card.displayColor.withOpacity(isSpecial ? 0.42 : 0.35),
                  blurRadius: isSpecial ? 18 : 14,
                  spreadRadius: isSpecial ? 3 : 2,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(isSpecial ? 0.82 : 0.7),
                width: isSpecial ? 2.2 : 2,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(isSpecial ? 0.18 : 0.12),
                            Colors.transparent,
                            Colors.black.withOpacity(isSpecial ? 0.09 : 0.04),
                          ],
                          stops: const [0.0, 0.54, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                if (isSpecial)
                  Positioned(
                    top: -18,
                    right: -14,
                    child: IgnorePointer(
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(isBlack ? 0.08 : 0.14),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Text(
                    card.topLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSpecial ? 13 : 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: isSpecial ? 1.15 : 1.0,
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      card.centerLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSpecial ? 28 : 54,
                        fontWeight: FontWeight.bold,
                        height: 1,
                        letterSpacing: isSpecial ? 0.8 : 0,
                      ),
                    ),
                  ),
                ),
                if (isBlack)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Text(
                      card.isBlackUp ? '+1' : '-1',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
