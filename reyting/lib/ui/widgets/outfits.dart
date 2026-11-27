import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/content.dart';
import 'face.dart';

/// Kıyafet tarzı: hangi gövde çizimleri ve hangi renkler.
/// Gövde numaraları (Notionists):
///  takım/ceket: 5 ceket, 6 siyah smokin, 13 kruvaze, 16 yakalı ceket, 19-20 gömlek+kravat
///  şık gündelik: 3-4 hırka+gömlek yakası, 14 polo, 21 bluz
///  gündelik: 1 hırka, 7/9/10/18 ceket+tişört, 11/23 kapüşonlu, 12 atkılı kazak, 17 yelek
///  eğlenceli: 15 puantiye, 22 gökkuşağı desen, 24 yıldızlı kapüşonlu
///  üniforma: 25 cepli iş gömleği
class Outfit {
  final List<int> bodies;
  final List<Color> colors;
  const Outfit(this.bodies, this.colors);
}

// ---------------- renk paletleri
const _dark = [Color(0xFF1F2A44), Color(0xFF2B2B33), Color(0xFF3A1E2B), Color(0xFF243B53), Color(0xFF4A4E57)];
const _news = [Color(0xFF1C3D6E), Color(0xFF26324A), Color(0xFF5C1F2E), Color(0xFF2E2E36), Color(0xFF3E5C76)];
const _glam = [Color(0xFF111111), Color(0xFFD4A017), Color(0xFFC2185B), Color(0xFF8E24AA), Color(0xFFB0BEC5), Color(0xFFE53935)];
const _bright = [Color(0xFFFF6B6B), Color(0xFF4DABF7), Color(0xFFFFD43B), Color(0xFF69DB7C), Color(0xFFB197FC), Color(0xFFFFA94D), Color(0xFFF783AC)];
const _showHost = [Color(0xFF6741D9), Color(0xFF1971C2), Color(0xFFC2255C), Color(0xFF0C8599), Color(0xFF212529)];
const _soft = [Color(0xFFADB5BD), Color(0xFF8CA0B3), Color(0xFFB5838D), Color(0xFF6D8B74), Color(0xFFD8C3A5), Color(0xFF7D8597)];
const _home = [Color(0xFF8D6E63), Color(0xFF6D8B74), Color(0xFFE9C46A), Color(0xFF457B9D), Color(0xFFE76F51), Color(0xFFADB5BD), Color(0xFF9C6644)];
const _outdoor = [Color(0xFF6B705C), Color(0xFFA5A58D), Color(0xFF8B6F47), Color(0xFF606C38), Color(0xFFBC8A5F)];
const _royal = [Color(0xFF6A040F), Color(0xFF3C096C), Color(0xFFB08900), Color(0xFF14213D), Color(0xFF7B2CBF)];
const _police = [Color(0xFF1D3557), Color(0xFF14213D), Color(0xFF2B2D42)];
const _team = [Color(0xFFE03131), Color(0xFFFFD43B), Color(0xFF1971C2), Color(0xFF2F9E44), Color(0xFFF8F9FA), Color(0xFF7048E8)];
const _kids = [Color(0xFFFFD43B), Color(0xFFFF8787), Color(0xFF69DB7C), Color(0xFF4DABF7), Color(0xFFDA77F2), Color(0xFFFFA94D)];
const _lab = [Color(0xFFF1F3F5), Color(0xFFE9ECEF), Color(0xFF99E9F2)];
const _scifi = [Color(0xFFCED4DA), Color(0xFF0B7285), Color(0xFF343A40), Color(0xFF66D9E8)];
const _horror = [Color(0xFF343A40), Color(0xFF495057), Color(0xFF5C3D2E), Color(0xFF2F3E46)];
const _romance = [Color(0xFFF783AC), Color(0xFFFFDEEB), Color(0xFFE64980), Color(0xFFF8F0E3), Color(0xFFC92A2A)];

// ---------------- gövde grupları
const _suit = [5, 6, 13, 16, 19, 20];
const _tie = [19, 20, 5, 13];
const _tux = [6, 5, 13];
const _smart = [3, 4, 14, 21, 13, 16];
const _casual = [1, 7, 9, 10, 11, 12, 17, 18, 23];
const _sporty = [7, 10, 18, 11, 23];
const _fun = [15, 22, 24, 11, 23];
const _outdoorB = [12, 1, 17, 25];
const _uniform = [25];

/// Programın sunucusu / ana karakteri (host) ve konuklar / diğer oyuncular
class OutfitStyle {
  final Outfit host;
  final Outfit guest;
  const OutfitStyle(this.host, this.guest);
}

OutfitStyle outfitForProp(Prop p) => switch (p) {
      // haber: takım elbise, kravat, koyu ciddi renkler
      Prop.newsDesk || Prop.globe || Prop.election =>
        const OutfitStyle(Outfit(_tie, _news), Outfit(_suit, _news)),
      Prop.debate => const OutfitStyle(Outfit(_tie, _news), Outfit(_suit, _dark)),
      Prop.field => const OutfitStyle(Outfit([16, 5, 12], _news), Outfit(_casual, _soft)),
      // magazin: gece şıklığı, parlak renkler
      Prop.redCarpet || Prop.awards => const OutfitStyle(Outfit(_tux, _glam), Outfit(_tux, _glam)),
      Prop.gossip || Prop.paparazzi => const OutfitStyle(Outfit([5, 13, 21, 15], _glam), Outfit([13, 21, 15, 6], _glam)),
      // talk show
      Prop.morning => const OutfitStyle(Outfit([14, 21, 3, 13], _bright), Outfit(_smart, _soft)),
      Prop.nightShow => const OutfitStyle(Outfit(_suit, _dark), Outfit(_smart, _soft)),
      Prop.standup => const OutfitStyle(Outfit([17, 9, 10, 18], _dark), Outfit(_casual, _soft)),
      Prop.sketch => const OutfitStyle(Outfit(_fun, _bright), Outfit(_fun, _bright)),
      Prop.newYear => const OutfitStyle(Outfit(_tux, _glam), Outfit([13, 21, 6, 15], _glam)),
      // yarışma: şık sunucu, gündelik yarışmacı
      Prop.quiz || Prop.wheel || Prop.couples =>
        const OutfitStyle(Outfit(_suit, _showHost), Outfit(_casual, _bright)),
      Prop.voice || Prop.talent => const OutfitStyle(Outfit(_tux, _glam), Outfit([17, 18, 9, 21, 15], _bright)),
      Prop.island => const OutfitStyle(Outfit(_outdoorB, _outdoor), Outfit([7, 10, 12, 11], _outdoor)),
      // dizi
      Prop.palace || Prop.epic => const OutfitStyle(Outfit([6, 13, 5], _royal), Outfit([13, 21, 3], _royal)),
      Prop.police => const OutfitStyle(Outfit(_uniform, _police), Outfit([17, 8, 12], _dark)),
      Prop.livingRoom || Prop.neighborhood => const OutfitStyle(Outfit([3, 4, 12, 14, 21], _home), Outfit([1, 7, 11, 12, 23], _home)),
      Prop.sitcom => const OutfitStyle(Outfit([15, 7, 14, 11], _bright), Outfit([22, 1, 23, 10], _bright)),
      // belgesel: arazi kıyafeti
      Prop.nature || Prop.ocean || Prop.history || Prop.space =>
        const OutfitStyle(Outfit(_outdoorB, _outdoor), Outfit(_outdoorB, _outdoor)),
      // spor: spiker şık, diğerleri forma renkleri
      Prop.sportsDesk => const OutfitStyle(Outfit(_suit, _news), Outfit(_sporty, _team)),
      Prop.football || Prop.basketball || Prop.derby || Prop.tournament =>
        const OutfitStyle(Outfit(_sporty, _team), Outfit(_sporty, _team)),
      // çocuk
      Prop.cartoon || Prop.puppet || Prop.kidsStage => const OutfitStyle(Outfit(_fun, _kids), Outfit(_fun, _kids)),
      Prop.lab => const OutfitStyle(Outfit([16, 13], _lab), Outfit(_fun, _kids)),
      // diğer
      Prop.film || Prop.filmSet || Prop.studio => const OutfitStyle(Outfit(_smart, _soft), Outfit(_casual, _home)),
    };

/// Film türüne göre kostüm
OutfitStyle outfitForFilm(FilmGenre g) => switch (g) {
      FilmGenre.aksiyon => const OutfitStyle(Outfit([17, 8, 9], _dark), Outfit([17, 18, 12], _dark)),
      FilmGenre.komedi => const OutfitStyle(Outfit(_fun, _bright), Outfit([7, 10, 15, 22], _bright)),
      FilmGenre.dram => const OutfitStyle(Outfit([3, 4, 12, 13], _soft), Outfit([12, 21, 3, 1], _soft)),
      FilmGenre.korku => const OutfitStyle(Outfit([12, 2, 4, 1], _horror), Outfit([12, 11, 23], _horror)),
      FilmGenre.romantik => const OutfitStyle(Outfit([21, 13, 5, 15], _romance), Outfit([13, 5, 21, 3], _romance)),
      FilmGenre.bilimKurgu => const OutfitStyle(Outfit([25, 8, 6], _scifi), Outfit([25, 16, 8], _scifi)),
      FilmGenre.animasyon => const OutfitStyle(Outfit([24, 22, 15], _kids), Outfit([24, 22, 15, 11], _kids)),
    };

/// Kişiyi verilen tarza göre giydir (aynı kişi aynı programda hep aynı kıyafet)
FaceSpec dress(FaceSpec f, Outfit o, int seed) {
  final r = Random(seed * 31 + 7);
  return f.copyWith(
    body: o.bodies[r.nextInt(o.bodies.length)],
    cloth: o.colors[r.nextInt(o.colors.length)],
  );
}
