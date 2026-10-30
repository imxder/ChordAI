import 'package:flutter/material.dart';

import '../state/app_state.dart';

Future<void> showPracticeOptionsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _PracticeOptionsSheet(),
  );
}

class _PracticeOptionsSheet extends StatefulWidget {
  const _PracticeOptionsSheet();

  @override
  State<_PracticeOptionsSheet> createState() => _PracticeOptionsSheetState();
}

class _PracticeOptionsSheetState extends State<_PracticeOptionsSheet> {
  static const _fontSizes = [0.85, 1.0, 1.3];
  static const _fontLabels = ['Pequeno', 'Médio', 'Grande'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opções de prática',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Tamanho da letra', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<double>(
              segments: [
                for (var i = 0; i < _fontSizes.length; i++)
                  ButtonSegment(value: _fontSizes[i], label: Text(_fontLabels[i])),
              ],
              selected: {appState.lyricFontScale},
              onSelectionChanged: (selection) {
                appState.setLyricFontScale(selection.first);
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar braço do violão'),
              value: appState.showGuitarNeckInPlayer,
              onChanged: (value) {
                appState.setShowGuitarNeckInPlayer(value);
                setState(() {});
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Rolagem automática'),
              value: appState.autoScrollInPlayer,
              onChanged: (value) {
                appState.setAutoScrollInPlayer(value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
