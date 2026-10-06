import 'package:flutter_test/flutter_test.dart';
import 'package:hisabkhata/format.dart';
import 'package:hisabkhata/models.dart';

void main() {
  group('format', () {
    test('taka', () {
      expect(taka(1234), '৳1,234');
      expect(taka(499.5), '৳499.50');
      expect(taka(0), '৳0');
      expect(taka(-1.99), '-৳1.99');
      expect(formatAmount(-1234.5), '-1,234.50');
    });

    test('meals', () {
      expect(formatNum(62), '62');
      expect(formatNum(58.5), '58.5');
      expect(formatNum(1.25), '1.25');
    });

    test('months', () {
      expect(shiftMonth('2026-01', -1), '2025-12');
      expect(shiftMonth('2026-12', 1), '2027-01');
      expect(daysInMonth('2026-02'), 28);
      expect(daysInMonth('2028-02'), 29);
      expect(monthName('2026-09', true), 'সেপ্টেম্বর 2026');
      expect(monthName('2026-09', false), 'September 2026');
    });

    test('amount input', () {
      expect(parseAmount('1,200'), 1200);
      expect(parseAmount(' ৳ 99.5 '), 99.5);
      expect(parseAmount(''), null);
      expect(parseAmount('abc'), null);
    });
  });

  test('month stats: typed totals replace day sums; deleted members still count', () {
    final data = MonthData.fromJson({
      'month': '2026-09',
      'days': 30,
      'members': [
        {'id': 1, 'name': 'Miraz', 'joinedOn': '2026-01-01', 'leftOn': null},
        {'id': 2, 'name': 'Masud', 'nameBn': 'মাসুদ', 'joinedOn': '2026-01-01', 'leftOn': null},
      ],
      'bazar': [
        {'id': 1, 'memberId': 1, 'date': '2026-09-02', 'amount': 600, 'items': ['Rice'], 'note': null},
        {'id': 2, 'memberId': null, 'date': '2026-09-03', 'amount': 300, 'items': [], 'note': null},
      ],
      'meals': {
        'cells': [
          {'memberId': 1, 'date': '2026-09-01', 'meals': 2},
          {'memberId': 1, 'date': '2026-09-02', 'meals': 1.5},
          {'memberId': 2, 'date': '2026-09-01', 'meals': 3},
          {'memberId': null, 'date': '2026-09-01', 'meals': 2.5},
        ],
        'totals': [
          {'memberId': 2, 'meals': 5},
        ],
      },
      'bills': [],
      'summary': {'month': '2026-09', 'mealMonth': '2026-08', 'rows': [], 'charges': []},
    });

    expect(data.totalBazar, 900);
    expect(data.mealsOf(1), 3.5);
    expect(data.mealsOf(2), 5); // typed total wins over the day cell (3)
    expect(data.totalMeals, 11); // 3.5 + 5 + 2.5 deleted
    expect(data.mealRate, closeTo(900 / 11, 1e-9));
    expect(data.members[1].display(true), 'মাসুদ');
    expect(data.members[0].display(true), 'Miraz');
  });
}
