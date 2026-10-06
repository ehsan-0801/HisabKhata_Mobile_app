// Formatting that matches the web app: Latin digits 0–9 in both languages,
// taka as ৳1,234 or ৳1,234.50, Bangla month names when the app is in Bangla.

const _enMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _enShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _bnMonths = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
const _bnShort = ['জানু', 'ফেব', 'মার্চ', 'এপ্রি', 'মে', 'জুন', 'জুল', 'আগ', 'সেপ', 'অক্টো', 'নভে', 'ডিসে'];
const _enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _bnDays = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];

String _group(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

/// 1234 → "1,234"; 1234.5 → "1,234.50"
String formatAmount(num amount) {
  final cents = (amount * 100).round();
  final sign = cents < 0 ? '-' : '';
  final whole = cents.abs() ~/ 100;
  final frac = cents.abs() % 100;
  return frac == 0 ? '$sign${_group(whole)}' : '$sign${_group(whole)}.${frac.toString().padLeft(2, '0')}';
}

String taka(num amount) => amount < 0 ? '-৳${formatAmount(-amount)}' : '৳${formatAmount(amount)}';

/// Meals: up to 2 decimals, trailing zeros trimmed (62, 58.5, 1.25).
String formatNum(num n) {
  final r = (n * 100).round() / 100;
  if (r == r.roundToDouble()) return _group(r.toInt());
  var s = r.toStringAsFixed(2);
  if (s.endsWith('0')) s = s.substring(0, s.length - 1);
  return s;
}

/// Today's date in Asia/Dhaka (UTC+6, no DST), as a date-only DateTime.
DateTime dhakaToday() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 6));
  return DateTime(now.year, now.month, now.day);
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseIso(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p.length > 2 ? p[2] : 1);
}

/// "YYYY-MM"
String monthKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
String thisMonth() => monthKey(dhakaToday());
String shiftMonth(String month, int by) {
  final d = parseIso(month);
  return monthKey(DateTime(d.year, d.month + by, 1));
}

int daysInMonth(String month) {
  final d = parseIso(month);
  return DateTime(d.year, d.month + 1, 0).day;
}

String monthName(String month, bool bn, {bool short = false}) {
  final d = parseIso(month);
  final names = bn ? (short ? _bnShort : _bnMonths) : (short ? _enShort : _enMonths);
  return short ? names[d.month - 1] : '${names[d.month - 1]} ${d.year}';
}

/// "7 Oct" / "7 অক্টো"
String formatDate(String iso, bool bn) {
  final d = parseIso(iso);
  return '${d.day} ${(bn ? _bnShort : _enShort)[d.month - 1]}';
}

String weekday(String iso, bool bn) => (bn ? _bnDays : _enDays)[parseIso(iso).weekday - 1];

/// Accepts "850", "499.5", "1,200" → number, or null when it isn't a valid amount.
num? parseAmount(String text) {
  final t = text.replaceAll(',', '').replaceAll('৳', '').trim();
  if (t.isEmpty) return null;
  return num.tryParse(t);
}
