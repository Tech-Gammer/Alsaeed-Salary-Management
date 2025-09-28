class ReplacementRecord {
  final String id;
  final String oldEmployeeId;
  final String newEmployeeId;
  final String? oldEmployeeName;
  final String? newEmployeeName;
  final String reason;
  final String replacementDate;
  final String? previousReplacementId; // Track the previous replacement in chain
  final String? nextReplacementId; // Track the next replacement in chain

  ReplacementRecord({
    required this.id,
    required this.oldEmployeeId,
    required this.newEmployeeId,
    this.oldEmployeeName,
    this.newEmployeeName,
    required this.reason,
    required this.replacementDate,
    this.previousReplacementId,
    this.nextReplacementId,
  });

  factory ReplacementRecord.fromJson(Map<String, dynamic> json) {
    return ReplacementRecord(
      id: json['id'].toString(),
      oldEmployeeId: json['oldEmployeeId'].toString(),
      newEmployeeId: json['newEmployeeId'].toString(),
      oldEmployeeName: json['oldEmployeeName'],
      newEmployeeName: json['newEmployeeName'],
      reason: json['reason'] ?? '',
      replacementDate: json['replacementDate'] ?? '',
      previousReplacementId: json['previousReplacementId']?.toString(),
      nextReplacementId: json['nextReplacementId']?.toString(),
    );
  }
}