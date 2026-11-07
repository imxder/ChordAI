import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/tuning_preset.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/page_parts.dart';

class CustomTuningScreen extends StatefulWidget {
  const CustomTuningScreen({super.key});

  @override
  State<CustomTuningScreen> createState() => _CustomTuningScreenState();
}

class _CustomTuningScreenState extends State<CustomTuningScreen> {
  late List<String> _notes;

  static const _labels = [
    '6ª corda',
    '5ª corda',
    '4ª corda',
    '3ª corda',
    '2ª corda',
    '1ª corda (mais aguda)',
  ];

  @override
  void initState() {
    super.initState();
    _notes = List<String>.from(
      appState.customTuningNotes ??
          tuningPresets.firstWhere((p) => p.id == 'padrao').notes,
    );
  }

  void _save() {
    appState.setCustomTuning(_notes);
    Navigator.of(context).pop();
  }

  void _pickNote(int index) {
    final initial = availableTuningNotes.indexOf(_notes[index]);
    var selected = initial < 0 ? 0 : initial;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => Container(
        height: 280,
        color: context.tokens.cell,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SheetHeader(
                title: _labels[index],
                actionLabel: 'OK',
                onAction: () {
                  setState(
                    () => _notes[index] = availableTuningNotes[selected],
                  );
                  Navigator.of(popupContext).pop();
                },
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(
                    initialItem: selected,
                  ),
                  onSelectedItemChanged: (i) => selected = i,
                  children: [
                    for (final note in availableTuningNotes)
                      Center(
                        child: Text(
                          note,
                          style: TextStyle(
                            fontFamily: fontChord,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IosPage(
      title: 'Afinação personalizada',
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _save,
        child: const Text(
          'Salvar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      children: [
        GroupedSection(
          top: 8,
          footer: 'Toque numa corda para escolher a nota.',
          children: [
            for (var index = 0; index < _notes.length; index++)
              GroupedRow(
                title: _labels[index],
                value: _notes[index],
                onTap: () => _pickNote(index),
              ),
          ],
        ),
      ],
    );
  }
}
