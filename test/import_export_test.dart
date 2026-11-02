import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketfin/core/constants/categories.dart';
import 'package:pocketfin/data/local/app_database.dart';
import 'package:pocketfin/data/repositories/transaction_repository.dart';
import 'package:pocketfin/data/services/export_service.dart';
import 'package:pocketfin/data/services/import_service.dart';

TransactionEntry sample({
  required int id,
  required String title,
  required TxCategory category,
  required TxType type,
  required int cents,
  required DateTime at,
  String? note,
}) {
  return TransactionEntry(
    id: id,
    title: title,
    category: category.name,
    type: type.name,
    amountCents: cents,
    note: note,
    occurredAt: at,
  );
}

void main() {
  final entries = [
    sample(
      id: 1,
      title: 'Coffee',
      category: TxCategory.food,
      type: TxType.expense,
      cents: 450,
      at: DateTime(2026, 11, 2, 8, 15),
      note: 'Morning',
    ),
    sample(
      id: 2,
      title: 'Salary',
      category: TxCategory.salary,
      type: TxType.income,
      cents: 320000,
      at: DateTime(2026, 11, 2, 9),
    ),
  ];

  test('round-trips entries through the xlsx export', () {
    final bytes = ExportService().buildXlsx(entries);
    final parsed = ImportService().parseXlsx(bytes);

    expect(parsed.invalidRows, 0);
    expect(parsed.entries, hasLength(2));

    final coffee = parsed.entries.first;
    expect(coffee.title, 'Coffee');
    expect(coffee.category, TxCategory.food);
    expect(coffee.type, TxType.expense);
    expect(coffee.amountCents, 450);
    expect(coffee.note, 'Morning');
    expect(coffee.occurredAt, DateTime(2026, 11, 2, 8, 15));

    final salary = parsed.entries.last;
    expect(salary.category, TxCategory.salary);
    expect(salary.type, TxType.income);
    expect(salary.amountCents, 320000);
  });

  test('imports entries and skips duplicates on a second run', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = TransactionRepository(database);
    final bytes = ExportService().buildXlsx(entries);
    final service = ImportService();

    final first = await service.importInto(repository, bytes);
    expect(first.imported, 2);
    expect(first.duplicates, 0);
    expect(first.invalid, 0);

    final second = await service.importInto(repository, bytes);
    expect(second.imported, 0);
    expect(second.duplicates, 2);

    expect(await repository.watchAll().first, hasLength(2));
  });

  test('rejects a file that is not a valid workbook', () {
    expect(
      () => ImportService().parseXlsx(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<FormatException>()),
    );
  });
}
