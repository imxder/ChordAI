import 'package:flutter/material.dart';

import '../models/tuning_preset.dart';
import '../state/app_state.dart';
import '../widgets/page_parts.dart';
import 'custom_tuning_screen.dart';

Future<void> showTuningSelectSheet(BuildContext context) {
  return showGlassSheet(
    context,
    builder: (context) => const _TuningSelectSheet(),
  );
}

class _TuningSelectSheet extends StatelessWidget {
  const _TuningSelectSheet();

  @override
  Widget build(BuildContext context) {
    void choose(String id) {
      if (id == customTuningId) {
        Navigator.of(context).pop();
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CustomTuningScreen()));
        return;
      }
      appState.setTuningPreset(id);
      Navigator.of(context).pop();
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(title: 'Afinação'),
            GroupedSection(
              top: 8,
              children: [
                for (final preset in tuningPresets)
                  CheckRow(
                    title: preset.name,
                    selected: appState.tuningId == preset.id,
                    onTap: () => choose(preset.id),
                  ),
                CheckRow(
                  title: 'Personalizada',
                  subtitle: 'Escolha a nota de cada corda',
                  selected: appState.tuningId == customTuningId,
                  onTap: () => choose(customTuningId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
