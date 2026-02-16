import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notes_provider.dart';

class SemanticSearchToggle extends ConsumerWidget {
  const SemanticSearchToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(semanticSearchToggleProvider);

    return Row(
      children: [
        const Text('Semantic Search'),
        Switch(
          value: enabled,
          onChanged: (val) => ref.read(semanticSearchToggleProvider.notifier).toggle(val),
        ),
      ],
    );
  }
}