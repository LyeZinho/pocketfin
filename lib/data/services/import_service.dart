import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../core/constants/categories.dart';
import '../models/imported_transaction.dart';
import '../repositories/transaction_repository.dart';

class ParsedImport {
  const ParsedImport({
    required this.entries,
    required this.invalidRows,
  });

  final List<ImportedTransaction> entries;
  final int invalidRows;
}

class ImportSummary {
  const ImportSummary({
    required this.imported,
    required this.duplicates,
    required this.invalid,
  });

  final int imported;
  final int duplicates;
  final int invalid;
}

class ImportService {
  ParsedImport parseXlsx(Uint8List bytes) {
    final Excel workbook;
    try {
      workbook = Excel.decodeBytes(bytes);
    } catch (_) {
      throw const FormatException(
        'That file is not a valid .xlsx workbook.',
      );
    }

    final sheet = _pickSheet(workbook);
    if (sheet == null) {
      throw const FormatException('The workbook has no data.');
    }

    final rows = sheet.rows;
    if (rows.isEmpty) {
      throw const FormatException('The workbook has no data.');
    }

    final headerIndex = _findHeaderRow(rows);
    if (headerIndex == null) {
      throw const FormatException(
        'Missing required columns: Date, Title, Category, Type and Amount.',
      );
    }

    final header = rows[headerIndex]
        .map((data) => _text(data?.value).trim().toLowerCase())
        .toList();

    final dateIndex = _column(header, ['date', 'occurred at', 'when']);
    final titleIndex =
        _column(header, ['title', 'description', 'name', 'merchant']);
    final categoryIndex = _column(header, ['category']);
    final typeIndex = _column(header, ['type', 'kind']);
    final amountIndex = _column(header, ['amount', 'value', 'total']);
    final noteIndex = _column(header, ['note', 'notes', 'memo']);

    if (dateIndex == null ||
        titleIndex == null ||
        categoryIndex == null ||
        typeIndex == null ||
        amountIndex == null) {
      throw const FormatException(
        'Missing required columns: Date, Title, Category, Type and Amount.',
      );
    }

    final entries = <ImportedTransaction>[];
    var invalid = 0;

    for (final row in rows.skip(headerIndex + 1)) {
      if (_isEmptyRow(row)) continue;

      final title = _text(_cell(row, titleIndex)?.value).trim();
      final category =
          TxCategory.tryParse(_text(_cell(row, categoryIndex)?.value));
      final type = _type(
        _text(_cell(row, typeIndex)?.value),
        category,
      );
      final amount = _amount(_cell(row, amountIndex)?.value);
      final occurredAt = _date(_cell(row, dateIndex)?.value);
      final note = noteIndex == null
          ? ''
          : _text(_cell(row, noteIndex)?.value).trim();

      if (title.isEmpty ||
          category == null ||
          amount <= 0 ||
          occurredAt == null) {
        invalid++;
        continue;
      }

      entries.add(
        ImportedTransaction(
          title: title,
          category: category,
          type: type,
          amountCents: amount,
          occurredAt: occurredAt,
          note: note.isEmpty ? null : note,
        ),
      );
    }

    return ParsedImport(entries: entries, invalidRows: invalid);
  }

  Future<ImportSummary> importInto(
    TransactionRepository repository,
    Uint8List bytes,
  ) async {
    final parsed = parseXlsx(bytes);
    final imported = await repository.importEntries(parsed.entries);
    return ImportSummary(
      imported: imported,
      duplicates: parsed.entries.length - imported,
      invalid: parsed.invalidRows,
    );
  }

  Sheet? _pickSheet(Excel workbook) {
    final transactions = workbook.tables['Transactions'];
    if (transactions != null) return transactions;
    if (workbook.tables.isEmpty) return null;
    return workbook.tables.values.first;
  }

  int? _findHeaderRow(List<List<Data?>> rows) {
    final limit = rows.length < 5 ? rows.length : 5;
    for (var index = 0; index < limit; index++) {
      final header = rows[index]
          .map((data) => _text(data?.value).trim().toLowerCase())
          .toSet();
      if (header.contains('date') &&
          header.contains('amount') &&
          (header.contains('title') ||
              header.contains('description') ||
              header.contains('name'))) {
        return index;
      }
    }
    return null;
  }

  int? _column(List<String> header, List<String> aliases) {
    for (final alias in aliases) {
      final index = header.indexOf(alias);
      if (index != -1) return index;
    }
    return null;
  }

  Data? _cell(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return null;
    return row[index];
  }

  bool _isEmptyRow(List<Data?> row) {
    return row.every(
      (data) => data?.value == null || _text(data?.value).trim().isEmpty,
    );
  }

  String _text(CellValue? value) {
    if (value == null) return '';
    return switch (value) {
      TextCellValue() => value.value.toString(),
      DoubleCellValue() => value.value.toString(),
      IntCellValue() => value.value.toString(),
      BoolCellValue() => value.value.toString(),
      DateTimeCellValue() => value.asDateTimeLocal().toIso8601String(),
      DateCellValue() => value.asDateTimeLocal().toIso8601String(),
      _ => value.toString(),
    };
  }

  int _amount(CellValue? value) {
    if (value is DoubleCellValue) {
      return (value.value.abs() * 100).round();
    }
    if (value is IntCellValue) {
      return value.value.abs() * 100;
    }
    final cleaned = _text(value)
        .replaceAll(RegExp(r'[\s,$€£]'), '')
        .replaceAll('(', '-')
        .replaceAll(')', '');
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return 0;
    return (parsed.abs() * 100).round();
  }

  TxType _type(String value, TxCategory? category) {
    return switch (value.trim().toLowerCase()) {
      'income' || 'in' || 'credit' => TxType.income,
      'expense' || 'out' || 'debit' => TxType.expense,
      _ => category == TxCategory.salary ? TxType.income : TxType.expense,
    };
  }

  DateTime? _date(CellValue? value) {
    if (value is DateTimeCellValue) return value.asDateTimeLocal();
    if (value is DateCellValue) return value.asDateTimeLocal();

    final text = _text(value).trim();
    if (text.isEmpty) return null;

    final direct = DateTime.tryParse(text);
    if (direct != null) return direct;

    const patterns = [
      'M/d/yyyy',
      'd/M/yyyy',
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'M/d/yy',
      'd/M/yy',
      'yyyy-MM-dd',
      'MMM d, yyyy',
      'd MMM yyyy',
    ];
    for (final pattern in patterns) {
      try {
        return DateFormat(pattern, 'en_US').parseStrict(text);
      } catch (_) {
        // Try the next pattern.
      }
    }
    return null;
  }
}
