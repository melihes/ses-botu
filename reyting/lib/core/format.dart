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
