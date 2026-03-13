import 'package:flutter/material.dart';

enum CardColorType {
  red,
  blue,
  green,
  yellow,
}

enum GameCardKind {
  number,
  change,
  blackUp,
  blackDown,
}

extension CardColorTypeX on CardColorType {
  String get label {
    switch (this) {
      case CardColorType.red:
        return 'RED';
      case CardColorType.blue:
        return 'BLUE';
      case CardColorType.green:
        return 'GREEN';
      case CardColorType.yellow:
        return 'YELLOW';
    }
  }

  Color get color {
    switch (this) {
      case CardColorType.red:
        return Colors.red;
      case CardColorType.blue:
        return Colors.blue;
      case CardColorType.green:
        return Colors.green;
      case CardColorType.yellow:
        return Colors.amber.shade700;
    }
  }

  Color get darkColor {
    switch (this) {
      case CardColorType.red:
        return Colors.red.shade800;
      case CardColorType.blue:
        return Colors.blue.shade800;
      case CardColorType.green:
        return Colors.green.shade800;
      case CardColorType.yellow:
        return Colors.amber.shade900;
    }
  }
}

class GameCardData {
  const GameCardData._({
    required this.kind,
    this.colorType,
    this.value,
  });

  const GameCardData.number({
    required CardColorType colorType,
    required int value,
  }) : this._(
          kind: GameCardKind.number,
          colorType: colorType,
          value: value,
        );

  const GameCardData.change()
      : this._(
          kind: GameCardKind.change,
        );

  const GameCardData.blackUp()
      : this._(
          kind: GameCardKind.blackUp,
        );

  const GameCardData.blackDown()
      : this._(
          kind: GameCardKind.blackDown,
        );

  static const List<GameCardData> weightedDeck = [
    GameCardData.number(colorType: CardColorType.red, value: 1),
    GameCardData.number(colorType: CardColorType.red, value: 2),
    GameCardData.number(colorType: CardColorType.red, value: 3),
    GameCardData.number(colorType: CardColorType.red, value: 4),
    GameCardData.number(colorType: CardColorType.red, value: 5),
    GameCardData.number(colorType: CardColorType.blue, value: 1),
    GameCardData.number(colorType: CardColorType.blue, value: 2),
    GameCardData.number(colorType: CardColorType.blue, value: 3),
    GameCardData.number(colorType: CardColorType.blue, value: 4),
    GameCardData.number(colorType: CardColorType.blue, value: 5),
    GameCardData.number(colorType: CardColorType.green, value: 1),
    GameCardData.number(colorType: CardColorType.green, value: 2),
    GameCardData.number(colorType: CardColorType.green, value: 3),
    GameCardData.number(colorType: CardColorType.green, value: 4),
    GameCardData.number(colorType: CardColorType.green, value: 5),
    GameCardData.number(colorType: CardColorType.yellow, value: 1),
    GameCardData.number(colorType: CardColorType.yellow, value: 2),
    GameCardData.number(colorType: CardColorType.yellow, value: 3),
    GameCardData.number(colorType: CardColorType.yellow, value: 4),
    GameCardData.number(colorType: CardColorType.yellow, value: 5),
    GameCardData.change(),
    GameCardData.blackUp(),
    GameCardData.blackDown(),
  ];

  final GameCardKind kind;
  final CardColorType? colorType;
  final int? value;

  bool get isNumber => kind == GameCardKind.number;
  bool get isChange => kind == GameCardKind.change;
  bool get isBlackUp => kind == GameCardKind.blackUp;
  bool get isBlackDown => kind == GameCardKind.blackDown;
  bool get isBlack => isBlackUp || isBlackDown;
  bool get isSpecial => !isNumber;

  GameCardData copyWithValue(int nextValue) {
    if (!isNumber || colorType == null) {
      return this;
    }
    return GameCardData.number(
      colorType: colorType!,
      value: nextValue.clamp(1, 5),
    );
  }

  Color get displayColor {
    if (isChange) {
      return const Color(0xFFB66CFF);
    }
    if (isBlackUp) {
      return const Color(0xFF353535);
    }
    if (isBlackDown) {
      return const Color(0xFF202020);
    }
    return colorType!.color;
  }

  Color get displayDarkColor {
    if (isChange) {
      return const Color(0xFF5C2EA8);
    }
    if (isBlackUp) {
      return const Color(0xFF6A6A6A);
    }
    if (isBlackDown) {
      return const Color(0xFF4B4B4B);
    }
    return colorType!.darkColor;
  }

  String get topLabel {
    if (isChange) {
      return 'PURPLE';
    }
    if (isBlack) {
      return 'BLACK';
    }
    return colorType!.label;
  }

  String get centerLabel {
    if (isChange) {
      return 'CHANGE';
    }
    if (isBlackUp) {
      return 'UP';
    }
    if (isBlackDown) {
      return 'DOWN';
    }
    return '${value ?? ''}';
  }
}
