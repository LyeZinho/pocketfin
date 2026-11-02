import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../../core/constants/categories.dart';
import '../local/app_database.dart';

class ExportService {
  Uint8List buildXlsx(List<TransactionEntry> entries) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, 'Transactions');
    }
    final sheet = excel['Transactions'];

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Title'),
      TextCellValue('Category'),
      TextCellValue('Type'),
      TextCellValue('Amount'),
      TextCellValue('Note'),
    ]);

    final sorted = [...entries]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    for (final entry in sorted) {
      final category = TxCategory.fromName(entry.category);
      sheet.appendRow([
        DateTimeCellValue.fromDateTime(entry.occurredAt),
        TextCellValue(entry.title),
        TextCellValue(category.label),
        TextCellValue(entry.type),
        DoubleCellValue(entry.amountCents / 100),
        TextCellValue(entry.note ?? ''),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Could not generate the Excel file.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<String> exportXlsx({
    required List<TransactionEntry> entries,
    required DateTime from,
    required DateTime to,
  }) async {
    final bytes = buildXlsx(entries);
    final name = 'pocketfin-'
        '${DateFormat('yyyyMMdd').format(from)}-'
        '${DateFormat('yyyyMMdd').format(to)}';
    return FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }
}
