import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_diagrams.dart';
import '../state/app_state.dart';
import '../widgets/guitar_neck.dart';
import 'chord_practice_screen.dart';

class ChordDetailScreen extends StatelessWidget {
  final String serverUrl;
  final InputDevice? inputDevice;
  final String chord;

  const ChordDetailScreen({
    super.key,
    required this.serverUrl,
    required this.chord,
    this.inputDevice,
  });

  static const _stringLabels = [
    '6ª corda (Mi grave)',
    '5ª corda (Lá)',
    '4ª corda (Ré)',
    '3ª corda (Sol)',
    '2ª corda (Si)',
    '1ª corda (Mi agudo)',
  ];

  String _fretDescription(int? fret) {
    if (fret == null) return 'Não toca';
    if (fret == 0) return 'Solta (sem pressionar)';
    return 'Casa $fret';
  }

  @override
  Widget build(BuildContext context) {
    final learned = appState.isChordLearned(chord);
    final fingering = chordFingerings[chord] ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(chord)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 220,
            child: GuitarNeck(chord: chord),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(chord, style: Theme.of(context).textTheme.headlineMedium),
              if (learned) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Colors.green),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Text('Dedilhado', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < fingering.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(_stringLabels[i])),
                  Text(_fretDescription(fingering[i])),
                ],
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChordPracticeScreen(
                    serverUrl: serverUrl,
                    inputDevice: inputDevice,
                    chord: chord,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.mic),
            label: const Text('Tocar e testar'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ],
      ),
    );
  }
}
