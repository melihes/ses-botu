import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/notionists_parts.dart';

/// Karakter yüzleri: "Notionists" çizim parçalarından (Zoish, CC0) birleştirilir,
/// ten / saç / kıyafet renkleriyle boyanır. Aynı tohum her zaman aynı kişiyi verir.
///
/// İfade (ağız, göz kırpma, kaş) değiştirilebildiği için canlı yayında
/// konuşma ve tepki animasyonları yapılabilir.
enum FaceMood { neutral, smile, talk, laugh, surprised, sad, angry }

class FaceSpec {
  final int hair, body, brows, eyes, nose, lips;
  final int? beard, glasses;
  final Color skin, hairColor, cloth;
  final bool female;

  const FaceSpec({
    required this.hair,
    required this.body,
    required this.brows,
    required this.eyes,
    required this.nose,
    required this.lips,
    required this.beard,
    required this.glasses,
    required this.skin,
    required this.hairColor,
    required this.cloth,
    required this.female,
  });

  // ---- Parça havuzları (gözle seçildi) ----
  static const femaleHair = [2, 4, 8, 10, 23, 28, 29, 36, 37, 39, 41, 43, 45, 46, 47, 48, 57, 58, 59, 62, 63];
  static const maleHair = [
    1, 3, 5, 6, 7, 9, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 24, 25, 26, 27, //
    30, 31, 32, 33, 34, 35, 38, 40, 44, 49, 52, 53, 54, 55, 56, 60,
  ];
  static const youngMaleHair = [50, 51, 53, 26, 32, 56];
  static const oldMaleHair = [60, 64, 5, 13, 16, 49];
  static const calmLips = [3, 4, 13, 14, 21, 22, 23, 17, 24];
  static const calmBrows = [1, 4, 5, 6, 8, 9, 10, 12];
  static const calmEyes = [1, 2, 5];
  static const beards = [1, 2, 3, 5, 6, 7, 9, 10, 11, 12];
  static const clearGlasses = [3, 8, 11];
  static const sunGlasses = [1, 2, 4, 5, 6, 7, 9, 10];

  static const skins = [
    Color(0xFFF7D7C4), Color(0xFFF2C29B), Color(0xFFE8B48F), Color(0xFFDDA07A), //
    Color(0xFFC98D66), Color(0xFFB07650), Color(0xFF8D5A3B), Color(0xFF6E4430),
  ];
  static const _skinWeights = [10, 22, 22, 16, 12, 8, 6, 4];
  static const hairColors = [
    Color(0xFF1A1412), Color(0xFF2B1D14), Color(0xFF3E2A1C), Color(0xFF5A3A22), //
    Color(0xFF7A4A28), Color(0xFFB07A3A), Color(0xFFD8B26A), Color(0xFFA3412A),
  ];
  static const _hairWeights = [22, 26, 18, 12, 8, 6, 4, 4];
  static const greys = [Color(0xFF9A9A9A), Color(0xFFBDBDBD), Color(0xFFDADADA), Color(0xFF7D7D7D)];
  static const clothes = [
    Color(0xFFFF6B6B), Color(0xFF4DABF7), Color(0xFFFFD43B), Color(0xFF69DB7C), //
    Color(0xFFB197FC), Color(0xFFFFA94D), Color(0xFFF783AC), Color(0xFF38D9A9),
    Color(0xFF495057), Color(0xFF1C7ED6), Color(0xFFE64980), Color(0xFF2F9E44),
    Color(0xFFF1F3F5), Color(0xFF343A40), Color(0xFF845EF7), Color(0xFFFD7E14),
  ];

  static T _weighted<T>(Random r, List<T> items, List<int> w) {
    final total = w.fold(0, (a, b) => a + b);
    var x = r.nextInt(total);
    for (int i = 0; i < items.length; i++) {
      x -= w[i];
      if (x < 0) return items[i];
    }
    return items.last;
  }

  /// Tohumdan kişi: [female] cinsiyet, [age] yaş (yaşlılarda kır saç).
  factory FaceSpec.of(int seed, {bool female = false, int age = 30, bool star = false}) {
    final r = Random(seed * 7919 + 17);
    T pick<T>(List<T> l) => l[r.nextInt(l.length)];
    final old = age >= 52;
    final young = age < 23;
    int hair;
    if (female) {
      hair = pick(femaleHair);
    } else if (old && r.nextDouble() < 0.6) {
      hair = pick(oldMaleHair);
    } else if (young && r.nextDouble() < 0.4) {
      hair = pick(youngMaleHair);
    } else {
      hair = pick(maleHair);
    }
    Color hc = _weighted(r, hairColors, _hairWeights);
    if (old) {
      hc = pick(greys);
    } else if (age >= 42 && r.nextDouble() < 0.35) {
      hc = Color.lerp(hc, greys[0], 0.5)!;
    }
    int? beard;
    if (!female && !young && r.nextDouble() < (old ? 0.5 : 0.38)) beard = pick(beards);
    int? glasses;
    final g = r.nextDouble();
    if (star && g < 0.18) {
      glasses = pick(sunGlasses);
    } else if (g < (old ? 0.45 : 0.2)) {
      glasses = pick(clearGlasses);
    }
    return FaceSpec(
      hair: hair,
      body: 1 + r.nextInt(25),
      brows: pick(calmBrows),
      eyes: pick(calmEyes),
      nose: 1 + r.nextInt(20),
      lips: pick(calmLips),
      beard: beard,
      glasses: glasses,
      skin: _weighted(r, skins, _skinWeights),
      hairColor: hc,
      cloth: pick(clothes),
      female: female,
    );
  }

  /// Aynı kişi, başka kıyafetle
  FaceSpec copyWith({int? body, Color? cloth}) => FaceSpec(
        hair: hair,
        body: body ?? this.body,
        brows: brows,
        eyes: eyes,
        nose: nose,
        lips: lips,
        beard: beard,
        glasses: glasses,
        skin: skin,
        hairColor: hairColor,
        cloth: cloth ?? this.cloth,
        female: female,
      );

  static String _v(int n) => 'variant${n.toString().padLeft(2, '0')}';
  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static String _replaceFirst(String s, String from, String to) {
    final i = s.indexOf(from);
    return i < 0 ? s : s.replaceRange(i, i + from.length, to);
  }

  /// Ruh haline göre ağız ve kaş
  (int lips, int brows, int eyes) _expr(FaceMood m, bool alt) => switch (m) {
        FaceMood.neutral => (lips, brows, eyes),
        FaceMood.smile => (alt ? 22 : 3, brows, eyes),
        FaceMood.talk => (alt ? 25 : 10, brows, eyes),
        FaceMood.laugh => (alt ? 11 : 25, 11, eyes),
        FaceMood.surprised => (15, 13, 4),
        FaceMood.sad => (alt ? 19 : 18, 13, eyes),
        FaceMood.angry => (alt ? 26 : 19, 2, eyes),
      };

  /// SVG metni. [crop]: yalnız baş-omuz (portre). [gesture]: el hareketi.
  String svg({
    FaceMood mood = FaceMood.neutral,
    bool blink = false,
    bool alt = false,
    bool crop = true,
    String? gesture,
  }) {
    final (l, b, e) = _expr(mood, alt);
    final skinHex = _hex(skin), hairHex = _hex(hairColor), clothHex = _hex(cloth);
    String part(String kind, int? n) => n == null ? '' : (notionParts[kind]?[_v(n)] ?? '');

    final base = _replaceFirst(part('base', 1), 'fill="#fff"', 'fill="$skinHex"');
    final bodySvg = _replaceFirst(part('body', body), 'fill="#fff"', 'fill="$clothHex"');
    final hairSvg = part('hair', hair).replaceAll(
        'fill="#000"', 'fill="$hairHex" stroke="#141014" stroke-width="10"');
    final beardSvg = part('beard', beard).replaceAll(
        'fill="#000"', 'fill="$hairHex" stroke="#141014" stroke-width="7"');
    final gestureSvg =
        gesture == null ? '' : (notionParts['gesture']?[gesture] ?? '').replaceAll('fill="#fff"', 'fill="$skinHex"');
    final eyesG = blink
        ? '<g transform="translate(610 735) scale(1 0.08) translate(0 -55)">'
        : '<g transform="translate(610 680)">';
    final vb = crop ? '300 170 1150 1150' : '0 0 1744 1744';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$vb" fill="none">'
        '<g transform="translate(531 487)">$base</g>'
        '<g transform="translate(178 1057)">$bodySvg</g>'
        '<ellipse cx="760" cy="905" rx="38" ry="22" fill="#ff7a8a" fill-opacity=".33"/>'
        '<ellipse cx="1010" cy="905" rx="38" ry="22" fill="#ff7a8a" fill-opacity=".33"/>'
        '<g transform="translate(266 207)">$hairSvg</g>'
        '<g transform="translate(791 871)">${part('lips', l)}</g>'
        '<g transform="translate(653 805)">$beardSvg</g>'
        '<g transform="translate(901 668)">${part('nose', nose)}</g>'
        '$eyesG${part('eyes', e)}</g>'
        '<g transform="translate(610 680)">${part('glasses', glasses)}</g>'
        '<g transform="translate(774 657)">${part('brows', b)}</g>'
        '<g transform="translate(0 559)">$gestureSvg</g>'
        '</svg>';
  }
}

/// Bellek: aynı kişi + ifade bir kez üretilir
final Map<String, String> _svgCache = {};

String faceSvg(FaceSpec f, int key,
    {FaceMood mood = FaceMood.neutral, bool blink = false, bool alt = false, bool crop = true, String? gesture}) {
  // kişinin görünüşü de anahtarda: aynı numaralı iki farklı kişi/kıyafet karışmasın
  final k = '$key|${Object.hash(f.hair, f.body, f.cloth.toARGB32(), f.skin.toARGB32(), f.hairColor.toARGB32(), f.beard, f.glasses, f.eyes)}'
      '|${mood.index}|$blink|$alt|$crop|$gesture';
  if (_svgCache.length > 600) _svgCache.clear();
  return _svgCache.putIfAbsent(
      k, () => f.svg(mood: mood, blink: blink, alt: alt, crop: crop, gesture: gesture));
}

/// Yüz çizimi (arka plansız). Canlı yayın sahneleri ve portreler kullanır.
class FaceView extends StatelessWidget {
  final FaceSpec spec;
  final int cacheKey;
  final FaceMood mood;
  final bool blink, alt, crop;
  final String? gesture;
  final double size;
  const FaceView({
    super.key,
    required this.spec,
    required this.cacheKey,
    this.mood = FaceMood.neutral,
    this.blink = false,
    this.alt = false,
    this.crop = true,
    this.gesture,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        faceSvg(spec, cacheKey, mood: mood, blink: blink, alt: alt, crop: crop, gesture: gesture),
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
}
