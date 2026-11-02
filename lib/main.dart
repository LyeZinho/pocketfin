import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/demo_seed.dart';
import 'logic/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  if (const bool.fromEnvironment('SEED_DEMO')) {
    await _seedIfEmpty(container);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PocketFinApp(),
    ),
  );
}

Future<void> _seedIfEmpty(ProviderContainer container) async {
  try {
    final repository = container.read(repositoryProvider);
    final existing = await repository.watchAll().first;
    if (existing.isEmpty) {
      await seedDemoData(repository, DateTime.now());
    }
  } catch (error, stackTrace) {
    debugPrint('Could not seed demo data: $error\n$stackTrace');
  }
}
