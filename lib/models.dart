// Plain data classes for the API's JSON (see HisabKhata docs/API.md).

num _n(dynamic v) => v is num ? v : num.tryParse('${v ?? 0}') ?? 0;
num? _nn(dynamic v) => v == null ? null : _n(v);
int? _id(dynamic v) => v == null ? null : (v is int ? v : int.tryParse('$v'));

class User {
  User({required this.id, required this.username, required this.email, this.isSuperAdmin = false});
  final int id;
  final String username;
  final String email;
  final bool isSuperAdmin;

  factory User.fromJson(Map j) => User(
        id: _id(j['id'])!,
        username: '${j['username'] ?? ''}',
        email: '${j['email'] ?? ''}',
        isSuperAdmin: j['isSuperAdmin'] == true,
      );
}

class Mess {
  Mess({required this.id, this.name, required this.role, this.plan});
  final int id;
  final String? name;
  final String role; // OWNER | MANAGER | VIEWER
  final String? plan;

  bool get canWrite => role == 'OWNER' || role == 'MANAGER';

  factory Mess.fromJson(Map j) => Mess(
        id: _id(j['id'])!,
        name: (j['name'] as String?)?.trim().isEmpty == true ? null : j['name'] as String?,
        role: '${j['role'] ?? 'VIEWER'}',
        plan: j['plan'] as String?,
      );
}

class Member {
  Member({required this.id, required this.name, this.nameBn, required this.joinedOn, this.leftOn, this.records = 0});
  final int id;
  final String name;
  final String? nameBn;
  final String joinedOn;
  final String? leftOn;
  final int records;

  String display(bool bn) => bn && (nameBn?.trim().isNotEmpty ?? false) ? nameBn! : name;

  /// Was a member on this day (YYYY-MM-DD)?
  bool isOn(String date) => joinedOn.compareTo(date) <= 0 && (leftOn == null || leftOn!.compareTo(date) >= 0);

  factory Member.fromJson(Map j) => Member(
        id: _id(j['id'])!,
        name: '${j['name'] ?? ''}',
        nameBn: j['nameBn'] as String?,
        joinedOn: '${j['joinedOn'] ?? ''}',
        leftOn: j['leftOn'] as String?,
        records: _id(j['records']) ?? 0,
      );
}

class BazarEntry {
  BazarEntry({required this.id, this.memberId, required this.date, required this.amount, required this.items, this.note});
  final int id;
  final int? memberId; // null = deleted member
  final String date;
  final num amount;
  final List<String> items;
  final String? note;

  factory BazarEntry.fromJson(Map j) => BazarEntry(
        id: _id(j['id'])!,
        memberId: _id(j['memberId']),
        date: '${j['date']}',
        amount: _n(j['amount']),
        items: ((j['items'] as List?) ?? const []).map((e) => '$e').toList(),
        note: j['note'] as String?,
      );
}

class MealCell {
  MealCell(this.memberId, this.date, this.meals);
  final int? memberId;
  final String date;
  final num meals;
  factory MealCell.fromJson(Map j) => MealCell(_id(j['memberId']), '${j['date']}', _n(j['meals']));
}

class MealTotal {
  MealTotal(this.memberId, this.meals);
  final int? memberId;
  final num meals;
  factory MealTotal.fromJson(Map j) => MealTotal(_id(j['memberId']), _n(j['meals']));
}

class SharedBill {
  SharedBill({required this.id, required this.name, required this.amount});
  final int id;
  final String name;
  final num amount;
  factory SharedBill.fromJson(Map j) => SharedBill(id: _id(j['id'])!, name: '${j['name']}', amount: _n(j['amount']));
}

class Charge {
  Charge({required this.billTypeId, required this.name, required this.amount, this.fromMonth});
  final int billTypeId;
  final String name;
  final num amount;
  final String? fromMonth;
  factory Charge.fromJson(Map j) => Charge(
        billTypeId: _id(j['billTypeId'])!,
        name: '${j['name']}',
        amount: _n(j['amount']),
        fromMonth: j['fromMonth'] as String?,
      );
}

class SummaryRow {
  SummaryRow({
    required this.memberId,
    required this.name,
    required this.meals,
    required this.mealCost,
    required this.charges,
    required this.billShare,
    required this.total,
    required this.bazarPaid,
    required this.balance,
  });
  final int memberId; // 0 = deleted members
  final String name;
  final num meals, mealCost, charges, billShare, total, bazarPaid, balance;

  factory SummaryRow.fromJson(Map j) => SummaryRow(
        memberId: _id(j['memberId']) ?? 0,
        name: '${j['name']}',
        meals: _n(j['meals']),
        mealCost: _n(j['mealCost']),
        charges: _n(j['charges']),
        billShare: _n(j['billShare']),
        total: _n(j['total']),
        bazarPaid: _n(j['bazarPaid']),
        balance: _n(j['balance']),
      );
}

class Summary {
  Summary({
    required this.month,
    required this.mealMonth,
    required this.memberCount,
    required this.totalBazar,
    required this.totalMeals,
    this.mealRate,
    required this.totalCharges,
    required this.totalBills,
    required this.billPerMember,
    required this.rows,
    required this.charges,
  });
  final String month, mealMonth;
  final int memberCount;
  final num totalBazar, totalMeals, totalCharges, totalBills, billPerMember;
  final num? mealRate;
  final List<SummaryRow> rows;
  final Map<int, List<Charge>> charges;

  factory Summary.fromJson(Map j) {
    final charges = <int, List<Charge>>{};
    for (final c in (j['charges'] as List?) ?? const []) {
      charges[_id(c['memberId']) ?? 0] = ((c['items'] as List?) ?? const []).map((e) => Charge.fromJson(e as Map)).toList();
    }
    return Summary(
      month: '${j['month']}',
      mealMonth: '${j['mealMonth']}',
      memberCount: _id(j['memberCount']) ?? 0,
      totalBazar: _n(j['totalBazar']),
      totalMeals: _n(j['totalMeals']),
      mealRate: _nn(j['mealRate']),
      totalCharges: _n(j['totalCharges']),
      totalBills: _n(j['totalBills']),
      billPerMember: _n(j['billPerMember']),
      rows: ((j['rows'] as List?) ?? const []).map((e) => SummaryRow.fromJson(e as Map)).toList(),
      charges: charges,
    );
  }
}

/// Everything for one month: GET /months/:month
class MonthData {
  MonthData({
    required this.month,
    required this.days,
    required this.members,
    required this.bazar,
    required this.cells,
    required this.totals,
    required this.bills,
    required this.summary,
  });
  final String month;
  final int days;
  final List<Member> members;
  final List<BazarEntry> bazar;
  final List<MealCell> cells;
  final List<MealTotal> totals;
  final List<SharedBill> bills;
  final Summary summary;

  factory MonthData.fromJson(Map j) {
    final meals = (j['meals'] as Map?) ?? const {};
    final bills = j['bills'];
    return MonthData(
      month: '${j['month']}',
      days: _id(j['days']) ?? 30,
      members: ((j['members'] as List?) ?? const []).map((e) => Member.fromJson(e as Map)).toList(),
      bazar: ((j['bazar'] as List?) ?? const []).map((e) => BazarEntry.fromJson(e as Map)).toList(),
      cells: ((meals['cells'] as List?) ?? const []).map((e) => MealCell.fromJson(e as Map)).toList(),
      totals: ((meals['totals'] as List?) ?? const []).map((e) => MealTotal.fromJson(e as Map)).toList(),
      bills: ((bills is Map ? bills['bills'] : bills) as List? ?? const []).map((e) => SharedBill.fromJson(e as Map)).toList(),
      summary: Summary.fromJson((j['summary'] as Map?) ?? const {}),
    );
  }

  // ---- This month's own bazar, meals and rate (the Expense and Meal tabs).

  num get totalBazar => bazar.fold<num>(0, (s, e) => s + e.amount);

  num? typedTotal(int? memberId) {
    for (final t in totals) {
      if (t.memberId == memberId) return t.meals;
    }
    return null;
  }

  num daySum(int? memberId) => cells.where((c) => c.memberId == memberId).fold<num>(0, (s, c) => s + c.meals);

  /// A member's meals this month: the typed total when there is one, otherwise the sum of their days.
  num mealsOf(int? memberId) => typedTotal(memberId) ?? daySum(memberId);

  /// Meals of deleted members (memberId null) still count.
  num get totalMeals => members.fold<num>(0, (s, m) => s + mealsOf(m.id)) + mealsOf(null);

  num? get mealRate => totalMeals > 0 ? totalBazar / totalMeals : null;

  num cell(int memberId, String date) {
    for (final c in cells) {
      if (c.memberId == memberId && c.date == date) return c.meals;
    }
    return 0;
  }
}

class Item {
  Item({required this.id, required this.name, this.nameBn, this.usage = 0});
  final int id;
  final String name;
  final String? nameBn;
  final int usage;
  String display(bool bn) => bn && (nameBn?.trim().isNotEmpty ?? false) ? nameBn! : name;
  factory Item.fromJson(Map j) => Item(id: _id(j['id'])!, name: '${j['name']}', nameBn: j['nameBn'] as String?, usage: _id(j['usage']) ?? 0);
}

class BillType {
  BillType({required this.id, required this.name, this.members = 0, this.used = false});
  final int id;
  final String name;
  final int members;
  final bool used;
  factory BillType.fromJson(Map j) => BillType(
        id: _id(j['id'])!,
        name: '${j['name']}',
        members: _id(j['members']) ?? 0,
        used: j['used'] == true || (_id(j['used']) ?? 0) > 0,
      );
}

class MemberCharges {
  MemberCharges({required this.memberId, required this.name, required this.charges, required this.total});
  final int memberId;
  final String name;
  final List<Charge> charges;
  final num total;
  factory MemberCharges.fromJson(Map j) => MemberCharges(
        memberId: _id(j['memberId'])!,
        name: '${j['name']}',
        charges: ((j['charges'] as List?) ?? const []).map((e) => Charge.fromJson(e as Map)).toList(),
        total: _n(j['total']),
      );
}
