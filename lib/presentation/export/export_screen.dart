import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pocket_widgets.dart';
import '../export/export_section.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppScaffoldBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Text('Export', style: AppText.display(36)),
            const SizedBox(height: 6),
            Text(
              'Your history, ready for a spreadsheet',
              style: AppText.body(17, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            const ExportSection(),
            const SizedBox(height: 28),
            SurfaceCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.lime,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Everything stays on this device. Exporting creates a '
                      'local file that you can share however you like.',
                      style: AppText.body(14, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
