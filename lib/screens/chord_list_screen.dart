import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_difficulty.dart';
import '../screens/chord_practice_screen.dart';
import '../state/app_state.dart';
import '../widgets/guitar_neck.dart';

class ChordListScreen extends StatefulWidget {
  final String serverUrl;
  final InputDevice? inputDevice;

  const ChordListScreen({
    super.key,
    required this.serverUrl,
    this.inputDevice,
  });

  @override
  State<ChordListScreen> createState() => _ChordListScreenState();
}

class _ChordListScreenState extends State<ChordListScreen> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    appState.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aprender Acordes')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: chordsByDifficulty.length,
        itemBuilder: (context, index) {
          final chord = chordsByDifficulty[index];
          final learned = appState.isChordLearned(chord);
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChordPracticeScreen(
                      serverUrl: widget.serverUrl,
                      inputDevice: widget.inputDevice,
                      chord: chord,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(child: GuitarNeck(chord: chord)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          chord,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (learned) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 18),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
