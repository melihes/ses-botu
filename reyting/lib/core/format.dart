/// Türkçe sayı/para biçimlendirme yardımcıları.
String _group(String digits) {
  final b = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write('.');
    b.write(digits[i]);
  }
  return b.toString();
}

/// 3507617548 -> "3.507.617.548 ₺"
String fmtFull(num v) {
  final neg = v < 0;
  return '${neg ? '-' : ''}${_group(v.abs().round().toString())} ₺';
}

/// Ondalık ayırıcı virgül: 9.1 -> "9,1"
String fmtDec(num v, [int digits = 1]) {
  var s = v.toStringAsFixed(digits).replaceAll('.', ',');
  if (digits > 0 && s.endsWith(',${'0' * digits}')) {
    s = s.substring(0, s.length - digits - 1);
  }
  return s;
}

/// Kısa para: 25900000 -> "25,9 M ₺", 3.5e9 -> "3,5 Mr ₺"
String fmtShort(num v) {
  final neg = v < 0;
  final a = v.abs();
  String body;
  if (a >= 1e15) {
    body = '${fmtDec(a / 1e15)} Ktr';
  } else if (a >= 1e12) {
    body = '${fmtDec(a / 1e12)} Tn';
  } else if (a >= 1e9) {
    body = '${fmtDec(a / 1e9)} Mr';
  } else if (a >= 1e6) {
    body = '${fmtDec(a / 1e6)} M';
  } else if (a >= 1e4) {
    body = '${fmtDec(a / 1e3, 0)} B';
  } else {
    body = _group(a.round().toString());
  }
  return '${neg ? '-' : ''}$body ₺';
}

/// İşaretli kısa para: "+1,2 M ₺" / "-300 B ₺"
String fmtSigned(num v) => v >= 0 ? '+${fmtShort(v)}' : fmtShort(v);

String fmtInt(num v) => _group(v.abs().round().toString());

String fmtPct(num v, [int digits = 1]) => '%${fmtDec(v, digits)}';

const weekdays = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

String weekdayOf(int day) => weekdays[(day - 1) % 7];

/// Türkçe ek: özel isme ünlü uyumuna göre ek getirir ("Gece Yarısı" → "Gece Yarısı'nın").
/// kind: gen (-ın), acc (-ı), dat (-a), loc (-da), abl (-dan), cop (-dı), lockI (-daki)
String trEk(String w, String kind) {
  const vowels = 'aeıioöuüAEIİOÖUÜ';
  const back = 'aıouAIOU';
  const hard = 'fstkçşhpFSTKÇŞHP';
  final t = w.trim();
  // sayıyla bitiyorsa okunuşuna göre (9 → dokuz → 9'un)
  const digitWords = ['sıfır', 'bir', 'iki', 'üç', 'dört', 'beş', 'altı', 'yedi', 'sekiz', 'dokuz'];
  final lastCh = t.isEmpty ? '' : t[t.length - 1];
  final dg = int.tryParse(lastCh);
  final probe = dg != null ? digitWords[dg] : t;
  String? lastV;
  for (int i = probe.length - 1; i >= 0; i--) {
    if (vowels.contains(probe[i])) {
      lastV = probe[i];
      break;
    }
  }
  final lv = switch (lastV ?? 'e') {
    'I' => 'ı',
    'İ' => 'i',
    final v => v.toLowerCase(),
  };
  final isBack = back.contains(lv);
  final four = switch (lv) {
    'a' || 'ı' => 'ı',
    'e' || 'i' => 'i',
    'o' || 'u' => 'u',
    _ => 'ü',
  };
  final two = isBack ? 'a' : 'e';
  final last = probe.isEmpty ? 'e' : probe[probe.length - 1];
  final endsV = vowels.contains(last);
  final endsHard = hard.contains(last);
  final d = endsHard ? 't' : 'd';
  final ek = switch (kind) {
    'gen' => endsV ? 'n${four}n' : '$four' 'n',
    'acc' => endsV ? 'y$four' : four,
    'dat' => endsV ? 'y$two' : two,
    'loc' => '$d$two',
    'abl' => '$d${two}n',
    'cop' => endsV ? 'yd$four' : '$d$four',
    'lockI' => '$d${two}ki',
    _ => '',
  };
  return "$t'$ek";
}

/// Türkçe büyük harf: "dizi" → "DİZİ" (Dart'ın toUpperCase'i "DIZI" yapar)
String trUpper(String s) => s.replaceAll('i', 'İ').toUpperCase();
