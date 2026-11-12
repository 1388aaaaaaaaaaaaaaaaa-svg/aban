class UnitInfo {
  final String id;
  final String label;
  final String residentName;
  final String? phone;
  final String? accessCode;

  UnitInfo({
    required this.id,
    required this.label,
    required this.residentName,
    this.phone,
    this.accessCode,
  });

  factory UnitInfo.fromJson(Map<String, dynamic> j) => UnitInfo(
        id: j['id'].toString(),
        label: (j['label'] ?? '').toString(),
        residentName: (j['resident_name'] ?? '').toString(),
        phone: j['phone']?.toString(),
        accessCode: j['access_code']?.toString(),
      );
}

class BillRow {
  final String periodTitle;
  final String? publishedAt;
  final String? dueDate;
  final num amountDue;
  final num paidAmount;
  final num balance;
  final String paymentStatus;
  final String? verificationCode;

  BillRow({
    required this.periodTitle,
    this.publishedAt,
    this.dueDate,
    required this.amountDue,
    required this.paidAmount,
    required this.balance,
    required this.paymentStatus,
    this.verificationCode,
  });

  bool get isPaid => paymentStatus == 'paid';

  factory BillRow.fromJson(Map<String, dynamic> j) => BillRow(
        periodTitle: (j['period_title'] ?? '').toString(),
        publishedAt: j['published_at']?.toString(),
        dueDate: j['due_date']?.toString(),
        amountDue: (j['amount_due'] ?? 0) as num,
        paidAmount: (j['paid_amount'] ?? 0) as num,
        balance: (j['balance'] ?? 0) as num,
        paymentStatus: (j['payment_status'] ?? '').toString(),
        verificationCode: j['verification_code']?.toString(),
      );
}
