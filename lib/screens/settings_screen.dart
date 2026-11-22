import 'package:flutter/material.dart';

import '../models/on_device_model.dart';
import '../services/audio_input.dart';
import '../state/app_state.dart';
import '../widgets/audio_input_section.dart';
import '../widgets/page_parts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _selectModel(OnDeviceModel model) async {
    await appState.setOnDeviceModel(model);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IosPage(
      title: 'Reconhecimento',
      children: [
        GroupedSection(
          top: 8,
          header: 'Modelo no aparelho',
          footer:
              'O v3 + meu dataset mostra menos acorde quando não tem acorde '
              'sendo tocado (cordas abafadas, tarraxa, fala).',
          children: [
            for (final option in OnDeviceModel.values)
              CheckRow(
                title: option.label,
                subtitle: option.description,
                selected: appState.onDeviceModel == option,
                onTap: () => _selectModel(option),
              ),
          ],
        ),
        if (canChooseAudioInput) const AudioInputSection(),
      ],
    );
  }
}
