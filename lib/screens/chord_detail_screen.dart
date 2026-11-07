import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_diagrams.dart';
import '../models/chord_names.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/page_parts.dart';
import 'chord_practice_screen.dart';
import '../theme/ph.dart';

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
    '6ª corda · Mi grave',
    '5ª corda · Lá',
    '4ª corda · Ré',
    '3ª corda · Sol',
    '2ª corda · Si',
    '1ª corda · Mi agudo',
  ];

  String _fretDescription(int? fret) {
    if (fret == null) return 'Não toca';
    if (fret == 0) return 'Solta';
    return 'Casa $fret';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fingering = chordFingerings[chord] ?? const [];

    return IosPage(
      title: chord,
      bottomBar: BottomActionBar(
        child: FilledButton.icon(
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
          icon: const Icon(Ph.microphoneFill, size: 20),
          label: const Text('Tocar e testar'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
      ),
      children: [
        ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final learned = appState.isChordLearned(chord);
            return Material(
              color: context.tokens.cell,
              borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 140, child: GuitarNeck(chord: chord)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: ChordName(chord, size: 52),
                          ),
                          Text(
                            chordFullName(chord),
                            style: textTheme.bodyLarge,
                          ),
                          if (learned) ...[
                            const SizedBox(height: 8),
                            StatusLine(
                              icon: Ph.checkCircleFill,
                              text: 'Aprendido',
                              color: context.tokens.correct,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        GroupedSection(
          header: 'Onde apertar',
          children: [
            for (var i = 0; i < fingering.length; i++)
              GroupedRow(
                title: _stringLabels[i],
                value: _fretDescription(fingering[i]),
              ),
          ],
        ),
      ],
    );
  }
}
