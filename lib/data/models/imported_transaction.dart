import '../../core/constants/categories.dart';

class ImportedTransaction {
  const ImportedTransaction({
    required this.title,
    required this.category,
    required this.type,
    required this.amountCents,
    required this.occurredAt,
    this.note,
  });

  final String title;
  final TxCategory category;
  final TxType type;
  final int amountCents;
  final DateTime occurredAt;
  final String? note;
}
