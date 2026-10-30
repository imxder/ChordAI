import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/lyric_sheet.dart';
import '../services/lyric_sheet_library.dart';
import 'lyric_sheet_screen.dart';
import 'practice_session_screen.dart';

class LyricSheetListScreen extends StatefulWidget {
  final String serverUrl;
  final InputDevice? inputDevice;

  const LyricSheetListScreen({
    super.key,
    required this.serverUrl,
    this.inputDevice,
  });

  @override
  State<LyricSheetListScreen> createState() => _LyricSheetListScreenState();
}

class _LyricSheetListScreenState extends State<LyricSheetListScreen> {
  final _library = LyricSheetLibrary();
  List<LyricSheet> _sheets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sheets = await _library.loadAll();
    if (!mounted) return;
    setState(() => _sheets = sheets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Músicas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music_outlined),
            tooltip: 'Praticar com partitura',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PracticeSessionScreen(
                    serverUrl: widget.serverUrl,
                    inputDevice: widget.inputDevice,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _sheets.length,
        itemBuilder: (context, index) {
          final sheet = _sheets[index];
          final chords = extractChords(sheet);
          final subtitleParts = [
            if (sheet.artist != null) sheet.artist!,
            '${chords.length} acordes',
            difficultyLabel(chords),
          ];
          return ListTile(
            leading: const Icon(Icons.lyrics_outlined),
            title: Text(sheet.title),
            subtitle: Text(subtitleParts.join('  •  ')),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LyricSheetScreen(
                    sheet: sheet,
                    serverUrl: widget.serverUrl,
                    inputDevice: widget.inputDevice,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
