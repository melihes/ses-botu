import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/engine/live_script.dart';

void main() {
  test('her tür ve format için canlı akış üretilir, skor tutarlı', () {
    for (final g in Genre.values) {
      for (final f in genreFormats[g]!) {
        final s = LiveScript(genre: g, prop: f.prop, host: 'Kerem', guest: 'Derin', cast: ['Ece', 'Can']);
        for (int i = 0; i < 400; i++) {
          final b = s.next();
          expect(b.text.trim(), isNotEmpty);
          expect(b.side, inInclusiveRange(0, 2));
          expect(b.reaction, inInclusiveRange(0, 3));
          final bd = s.board;
          if (bd != null) {
            expect(bd.left, greaterThanOrEqualTo(0));
            expect(bd.right, greaterThanOrEqualTo(0));
          }
        }
      }
    }
  });
  test('ada yarışmasında skor 5\'i geçmez ve yarışmacılar sunucudan farklı', () {
    final s = LiveScript(genre: Genre.yarisma, prop: Prop.island, host: 'Kerem', guest: 'Derin', cast: ['Kerem']);
    final names = <String>{};
    for (int i = 0; i < 500; i++) {
      final b = s.next();
      if (b.side == 1 && !b.who.contains('takım')) names.add(b.who);
      expect(s.board!.left, lessThanOrEqualTo(5));
      expect(s.board!.right, lessThanOrEqualTo(5));
    }
    expect(names.contains('Kerem'), isFalse);
  });
}
