import 'dart:async';

import 'package:piecemeal/piecemeal.dart';
import 'char_code.dart';

class Color {
  static const black = Color(0, 0, 0);
  static const white = Color(255, 255, 255);

  static const lightGray = Color(192, 192, 192);
  static const gray = Color(128, 128, 128);
  static const darkGray = Color(64, 64, 64);

  static const lightRed = Color(255, 160, 160);
  static const red = Color(220, 0, 0);
  static const darkRed = Color(100, 0, 0);

  static const lightOrange = Color(255, 200, 170);
  static const orange = Color(255, 128, 0);
  static const darkOrange = Color(128, 64, 0);

  static const lightGold = Color(255, 230, 150);
  static const gold = Color(255, 192, 0);
  static const darkGold = Color(128, 96, 0);

  static const lightYellow = Color(255, 255, 150);
  static const yellow = Color(255, 255, 0);
  static const darkYellow = Color(128, 128, 0);

  static const lightGreen = Color(130, 255, 90);
  static const green = Color(0, 128, 0);
  static const darkGreen = Color(0, 64, 0);

  static const lightAqua = Color(128, 255, 255);
  static const aqua = Color(0, 255, 255);
  static const darkAqua = Color(0, 128, 128);

  static const lightBlue = Color(128, 160, 255);
  static const blue = Color(0, 64, 255);
  static const darkBlue = Color(0, 37, 168);

  static const lightPurple = Color(200, 140, 255);
  static const purple = Color(128, 0, 255);
  static const darkPurple = Color(64, 0, 128);

  static const lightBrown = Color(190, 150, 100);
  static const brown = Color(160, 110, 60);
  static const darkBrown = Color(100, 64, 32);

  final int r;
  final int g;
  final int b;

  String get cssColor => "rgb($r, $g, $b)";

  const Color(this.r, this.g, this.b);

  int get hashCode => r.hashCode ^ g.hashCode ^ b.hashCode;

  bool operator ==(Object other) {
    if (other is Color) {
      return r == other.r && g == other.g && b == other.b;
    }

    return false;
  }

  Color add(Color other, [double? fractionOther]) {
    fractionOther ??= 1.0;
    return Color(
        (r + other.r * fractionOther).clamp(0, 255).toInt(),
        (g + other.g * fractionOther).clamp(0, 255).toInt(),
        (b + other.b * fractionOther).clamp(0, 255).toInt());
  }

  Color blend(Color other, double fractionOther) {
    var fractionThis = 1.0 - fractionOther;
    return Color(
        (r * fractionThis + other.r * fractionOther).toInt(),
        (g * fractionThis + other.g * fractionOther).toInt(),
        (b * fractionThis + other.b * fractionOther).toInt());
  }

  Color blendPercent(Color other, int percentOther) =>
      blend(other, percentOther / 100);
}

class TriPhaseColor {
  Color back;
  Color fore;
  Color complete;

  static const defaultBack = Color.darkRed;
  static const defaultFore = Color.red;
  static const defaultComplete = Color.green;

  TriPhaseColor({Color? back, Color? fore, Color? complete})
      : fore = fore ?? defaultFore,
        back = back ?? defaultBack,
        complete = complete ?? defaultComplete;
}

class Glyph {
  final Color fore;
  final Color back;

  static const defaultBack = Color.black;
  static const defaultFore = Color.white;

  const Glyph({Color? fore, Color? back})
      : fore = fore != null ? fore : defaultFore,
        back = back != null ? back : defaultBack;

  Glyph replaceBackground(Color newBack) {
    return Glyph(back: newBack, fore: fore);
  }
}

// A [Glyph] that represents a colored symbol via utf-16 code point.
class CharGlyph extends Glyph {
  /// The empty glyph: a clear glyph using the default background color
  /// [Color.BLACK].
  static const clear = CharGlyph.fromCharCode(CharCode.space);

  final int char;

  CharGlyph(String char, [Color? fore, Color? back])
      : char = char.codeUnits[0],
        super(fore: fore, back: back);

  const CharGlyph.fromCharCode(this.char, [Color? fore, Color? back])
      : super(fore: fore, back: back);

  int get hashCode => char.hashCode ^ fore.hashCode ^ back.hashCode;

  factory CharGlyph.fromDynamic(Object charOrCharCode,
      [Color? fore, Color? back]) {
    if (charOrCharCode is String) return CharGlyph(charOrCharCode, fore, back);
    return CharGlyph.fromCharCode(charOrCharCode as int, fore, back);
  }

  @override
  CharGlyph replaceBackground(Color newBack) {
    return CharGlyph.fromCharCode(char, fore, newBack);
  }

  operator ==(Object other) {
    if (other is CharGlyph) {
      return char == other.char && fore == other.fore && back == other.back;
    }

    return false;
  }
}

/// A [Glyph] that represents a colored symbol based on its coordinates in a
/// tilesheet provided by the terminal used to render it.
class VecGlyph extends Glyph {
  final Vec vec;

  VecGlyph(String char, [Color? fore, Color? back])
      : vec = Vec(0, 0),
        super(fore: fore, back: back);

  const VecGlyph.fromVec(this.vec, [Color? fore, Color? back])
      : super(fore: fore, back: back);

  @override
  VecGlyph replaceBackground(Color newBack) {
    return VecGlyph.fromVec(vec, fore, newBack);
  }

  int get hashCode => vec.hashCode ^ fore.hashCode ^ back.hashCode;

  operator ==(Object other) {
    if (other is VecGlyph) {
      return vec == other.vec && fore == other.fore && back == other.back;
    }

    return false;
  }
}
