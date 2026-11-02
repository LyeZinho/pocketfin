import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pocket_widgets.dart';
import '../../data/local/app_database.dart';
import '../../logic/providers.dart';

class ExportSection extends ConsumerStatefulWidget {
  const ExportSection({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  ConsumerState<ExportSection> createState() => _ExportSectionState();
}

class _ExportSectionState extends ConsumerState<ExportSection> {
  bool _busy = false;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(nowProvider);
    final from = DateTime(now.year);
    final entries = ref.watch(transactionsProvider).value ?? const [];
    final inRange = entries
        .where(
          (entry) =>
              !entry.occurredAt.isBefore(from) &&
              !entry.occurredAt.isAfter(now),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Text('Export data', style: AppText.display(24)),
          const SizedBox(height: 14),
        ],
        SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Text(
                'Range',
                style: AppText.body(17, color: AppColors.muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formatRange(from, now),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.data(14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FormatCard(
                extension: '.xlsx',
                label: 'Excel',
                background: AppColors.lime,
                foreground: AppColors.onAccent,
                busy: _busy,
                onTap: _busy || _importing || inRange.isEmpty
                    ? null
                    : () => _export(inRange, from, now),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FormatCard(
                extension: '.xls',
                label: 'Legacy Excel',
                background: AppColors.surface,
                foreground: AppColors.muted,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Legacy .xls export is coming soon.'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (inRange.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Add entries to enable export.',
              style: AppText.body(13, color: AppColors.muted),
            ),
          ),
        const SizedBox(height: 26),
        Text('Import data', style: AppText.display(24)),
        const SizedBox(height: 14),
        SurfaceCard(
          padding: const EdgeInsets.all(18),
          onTap: _busy || _importing ? null : _import,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: _importing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.lime,
                        ),
                      )
                    : const Icon(
                        Icons.upload_file_rounded,
                        color: AppColors.lime,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import from Excel',
                      style: AppText.body(18, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Restore a PocketFin .xlsx backup',
                      style: AppText.body(13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Existing entries are kept. Exact duplicates are skipped.',
          style: AppText.body(12, color: AppColors.muted),
        ),
      ],
    );
  }

  Future<void> _import() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Import PocketFin data',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (file == null) return;

      setState(() => _importing = true);
      final bytes = await file.readAsBytes();
      final summary = await ref.read(importServiceProvider).importInto(
            ref.read(repositoryProvider),
            bytes,
          );
      if (!mounted) return;

      final parts = <String>[
        if (summary.imported > 0) '${summary.imported} imported',
        if (summary.duplicates > 0)
          '${summary.duplicates} duplicate${summary.duplicates == 1 ? '' : 's'} skipped',
        if (summary.invalid > 0)
          '${summary.invalid} invalid row${summary.invalid == 1 ? '' : 's'} skipped',
      ];
      _showMessage(parts.isEmpty ? 'Nothing new to import.' : parts.join(' · '));
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Import failed: $error');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _export(
    List<TransactionEntry> entries,
    DateTime from,
    DateTime to,
  ) async {
    setState(() => _busy = true);
    try {
      final path = await ref.read(exportServiceProvider).exportXlsx(
            entries: entries,
            from: from,
            to: to,
          );
      if (!mounted) return;
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            subject: 'PocketFin export',
          ),
        );
      } catch (_) {
        // Sharing is best effort; the file is already saved.
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to $path')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.extension,
    required this.label,
    required this.background,
    required this.foreground,
    this.onTap,
    this.busy = false,
  });

  final String extension;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null && !busy ? 0.55 : 1,
      child: SurfaceCard(
        color: background,
        radius: 20,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    extension,
                    style: AppText.data(
                      25,
                      weight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
                if (busy)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: AppText.body(
                    18,
                    weight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
