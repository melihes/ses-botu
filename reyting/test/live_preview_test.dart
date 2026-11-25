// Geliştirme aracı: canlı yayın sahnelerini türe/formata göre önizler.
// LIVE=1 flutter test test/live_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/engine/live_script.dart';
import 'package:reyting/ui/screens/live_stage.dart';
import 'package:reyting/ui/widgets/face.dart';

import 'ui_monkey_test.dart' show loadFonts;

const out = '/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/live';

void main() {
  setUpAll(loadFonts);
  final props = Platform.environment['PROPS']?.split(',') ?? const [];
  final cases = <(Genre, Prop, List<LiveBeat>)>[
    (Genre.talkShow, Prop.nightShow, const [LiveBeat(0, 'Cemre', 'x'), LiveBeat(0, 'Cemre', 'Bu akşam çok özel bir konuğumuz var!'), LiveBeat(1, 'Rıza', 'Merhaba!', reaction: 2)]),
    (Genre.yarisma, Prop.quiz, const [LiveBeat(0, 'Cemre', 'x'), LiveBeat(2, 'Anlatıcı', 'Soru ekranda…'), LiveBeat(1, 'Rıza', 'Cevabım B!', reaction: 1)]),
    (Genre.yarisma, Prop.island, const [LiveBeat(0, 'Cemre', 'x'), LiveBeat(2, 'Anlatıcı', 'Takımlar sahada'), LiveBeat(0, 'Cemre', 'Dokunulmazlık oyunu başlıyor!')]),
    (Genre.dizi, Prop.livingRoom, const [LiveBeat(0, 'Cemre', 'x'), LiveBeat(2, 'Anlatıcı', 'Konakta gergin bir akşam…'), LiveBeat(1, 'Rıza', 'Bunu bana nasıl yaparsın?', reaction: 3)]),
    (Genre.haber, Prop.newsDesk, const [LiveBeat(0, 'Cemre', 'x'), LiveBeat(2, 'Anlatıcı', 'Ana haber'), LiveBeat(1, 'Rıza', 'Olay yerindeyim…')]),
    (Genre.spor, Prop.football, const [LiveBeat(0, 'Cemre', 'x'), LiveBeat(2, 'Anlatıcı', 'Maç başladı'), LiveBeat(0, 'Cemre', 'GOOOL!', reaction: 2)]),
    (Genre.belgesel, Prop.ocean, const [LiveBeat(0, 'Cemre', 'x'), LiveBeat(2, 'Anlatıcı', 'Okyanusun derinliklerinde…'), LiveBeat(0, 'Cemre', 'Bu türün nesli tehlikede.')]),
    (Genre.cocuk, Prop.cartoon, const [LiveBeat(0, 'Cemre', 'x'), LiveBeat(2, 'Anlatıcı', 'Bir varmış bir yokmuş'), LiveBeat(0, 'Cemre', 'Hep birlikte sayalım!', reaction: 2)]),
    (Genre.magazin, Prop.redCarpet, const [LiveBeat(0, 'Cemre', 'x'), LiveBeat(2, 'Anlatıcı', 'Kırmızı halı'), LiveBeat(1, 'Rıza', 'Bu elbise çok konuşulacak!')]),
  ];
  for (final (gi, c) in cases.indexed) {
    if (props.isNotEmpty && !props.contains(c.$2.name)) continue;
    testWidgets('canlı ${c.$2.name}', (t) async {
      if (Platform.environment['LIVE'] != '1') return;
      t.view.physicalSize = const Size(640, 360);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final host = LivePerson('Cemre', FaceSpec.of(11, female: true), 11);
      final guest = LivePerson('Rıza', FaceSpec.of(22), 22);
      final crowd = [for (int i = 0; i < 14; i++) FaceSpec.of(100 + i, female: i.isOdd, age: 20 + i * 3)];
      for (int b = 0; b < c.$3.length; b++) {
        final key = GlobalKey();
        // her karede yeni bir widget: aynı state içinde beatId ilerlesin
        Widget stage(int beatId) => MaterialApp(
              theme: ThemeData(fontFamily: 'Roboto'),
              home: RepaintBoundary(
                key: key,
                child: LiveStage(
                  genre: c.$1,
                  prop: c.$2,
                  title: 'Gece Yarısı',
                  channel: 'Kanal 9',
                  channelLogo: const ColoredBox(color: Colors.orange),
                  color: const Color(0xFFFF4F8B),
                  beat: c.$3[beatId],
                  beatId: beatId,
                  ticker: 'Gündem haberleri',
                  board: null,
                  host: host,
                  guest: guest,
                  people: {'Cemre': host, 'Rıza': guest},
                  crowd: crowd,
                  seed: 7,
                ),
              ),
            );
        for (int k = 0; k <= b; k++) {
          await t.pumpWidget(stage(k));
          await t.pump(const Duration(milliseconds: 1600));
        }
        await t.runAsync(() => Future.delayed(const Duration(milliseconds: 1200)));
        await t.pump(const Duration(milliseconds: 50));
        await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
        await t.pump(const Duration(milliseconds: 50));
        await t.runAsync(() async {
          final r = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await r.toImage();
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          Directory(out).createSync(recursive: true);
          File('$out/${gi}_${c.$2.name}_$b.png').writeAsBytesSync(data!.buffer.asUint8List());
        });
      }
    });
  }
}
