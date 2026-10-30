import 'package:flutter/material.dart';

import '../models/tuning_preset.dart';
import '../state/app_state.dart';
import 'custom_tuning_screen.dart';

Future<void> showTuningSelectSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _TuningSelectSheet(),
  );
}

class _TuningSelectSheet extends StatelessWidget {
  const _TuningSelectSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: RadioGroup<String>(
          groupValue: appState.tuningId,
          onChanged: (value) {
            if (value == customTuningId) {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomTuningScreen()),
              );
              return;
            }
            appState.setTuningPreset(value!);
            Navigator.of(context).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Afinação',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              for (final preset in tuningPresets)
                RadioListTile<String>(
                  value: preset.id,
                  title: Text(preset.name),
                ),
              RadioListTile<String>(
                value: customTuningId,
                title: const Text('Personalizada...'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
