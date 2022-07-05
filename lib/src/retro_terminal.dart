import 'dart:html' as html;

import 'package:piecemeal/piecemeal.dart';

import 'char_code.dart';
import 'glyph.dart';
import 'display.dart';
import 'terminal.dart';
import 'unicode_map.dart';

/// A [RenderableTerminal] that draws to a canvas using the old school DOS
/// [code page 437][font] font.
///
/// [font]: http://en.wikipedia.org/wiki/Code_page_437
class RetroTerminal extends RenderableTerminal {
  final Display _display;

  final html.CanvasRenderingContext2D _context;
  final html.ImageElement _font;

  /// A cache of the tinted font images. Each key is a color, and the image
  /// will is the font in that color.
  final Map<Color, html.CanvasElement> _fontColorCache = {};

  /// The drawing scale, used to adapt to Retina displays.
  final int _scale;

  /// The zoom applied to the terminal. Displays glyphs at [zoom] x their actual
  /// pixel size. E.g. a 16x16 tilesheet will display tiles at 32x32.
  final int _zoom;

  bool _imageLoaded = false;

  final int _charWidth;
  final int _charHeight;

  int get width => _display.width;
  int get height => _display.height;
  Vec get size => _display.size;

  /// Creates a new terminal using a built-in DOS-like font.
  factory RetroTerminal.dos(int width, int height,
          [html.CanvasElement? canvas]) =>
      RetroTerminal(width, height, "packages/malison/dos.png",
          canvas: canvas, charWidth: 9, charHeight: 16);

  /// Creates a new terminal using a short built-in DOS-like font.
  factory RetroTerminal.shortDos(int width, int height,
          [html.CanvasElement? canvas]) =>
      RetroTerminal(width, height, "packages/malison/dos-short.png",
          canvas: canvas, charWidth: 9, charHeight: 13);

  /// Creates a new terminal using a font image at [imageUrl].
  factory RetroTerminal(int width, int height, String imageUrl,
      {html.CanvasElement? canvas,
      required int charWidth,
      required int charHeight,
      int? scale,
      int? zoom}) {
    scale ??= html.window.devicePixelRatio.toInt();
    zoom ??= 1;

    // If not given a canvas, create one, automatically size it, and add it to
    // the page.
    if (canvas == null) {
      canvas = html.CanvasElement();
      var canvasWidth = charWidth * width;
      var canvasHeight = charHeight * height;
      canvas.width = canvasWidth * scale;
      canvas.height = canvasHeight * scale;
      canvas.style.width = '${canvasWidth}px';
      canvas.style.height = '${canvasHeight}px';

      html.document.body!.append(canvas);
    }

    width = width ~/ zoom;
    height = height ~/ zoom;

    var display = Display(width, height);

    return RetroTerminal._(display, charWidth, charHeight, canvas,
        html.ImageElement(src: imageUrl), scale, zoom);
  }

  RetroTerminal._(this._display, this._charWidth, this._charHeight,
      html.CanvasElement canvas, this._font, this._scale, this._zoom)
      : _context = canvas.context2D {
    _font.onLoad.listen((_) {
      _imageLoaded = true;
      render();
    });
  }

  void drawGlyph(int x, int y, Glyph glyph) {
    _display.setGlyph(x, y, glyph);
  }

  void render() {
    if (!_imageLoaded) return;

    _display.render((x, y, glyph) {
      int? sx;
      int? sy;
      if (glyph is CharGlyph) {
        var char = glyph.char;

        // Remap it if it's a Unicode character.
        char = unicodeMap[char] ?? char;

        sx = (char % 32) * _charWidth;
        sy = (char ~/ 32) * _charHeight;
      } else if (glyph is VecGlyph) {
        sx = glyph.vec.x * _charWidth;
        sy = glyph.vec.y * _charHeight;
      }

      if (sx == null || sy == null) {
        // TODO: Give exception type
        throw 'No coordinates provided for symbol to render.';
      }

      // Fill the background.
      _context.fillStyle = glyph.back.cssColor;
      _context.fillRect(
          x * _charWidth * _scale * _zoom,
          y * _charHeight * _scale * _zoom,
          _charWidth * _scale * _zoom,
          _charHeight * _scale * _zoom);

      // File the foreground glyph.
      var color = _getColorFont(glyph.fore);
      _context.imageSmoothingEnabled = false;
      _context.drawImageScaledFromSource(
          color,
          sx,
          sy,
          _charWidth,
          _charHeight,
          x * _charWidth * _scale * _zoom,
          y * _charHeight * _scale * _zoom,
          _charWidth * _scale * _zoom,
          _charHeight * _scale * _zoom);
    });
  }

  Vec pixelToChar(Vec pixel) =>
      Vec(pixel.x ~/ _charWidth, pixel.y ~/ _charHeight);

  html.CanvasElement _getColorFont(Color color) {
    var cached = _fontColorCache[color];
    if (cached != null) return cached;

    // Create a font using the given color.
    var tint = html.CanvasElement(width: _font.width, height: _font.height);
    var context = tint.context2D;

    // Draw the font.
    context.drawImage(_font, 0, 0);

    // Tint it by filling in the existing alpha with the color.
    context.globalCompositeOperation = 'source-atop';
    context.fillStyle = color.cssColor;
    context.fillRect(0, 0, _font.width!, _font.height!);

    _fontColorCache[color] = tint;
    return tint;
  }
}
