import 'package:flutter/material.dart';

import '../models/tuning_preset.dart';
import '../state/app_state.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Afinação personalizada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Salvar',
            onPressed: _save,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(_labels[index]),
              trailing: DropdownButton<String>(
                value: _notes[index],
                items: availableTuningNotes
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _notes[index] = value);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
