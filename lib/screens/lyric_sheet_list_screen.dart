import 'package:flutter/material.dart';

import '../models/lyric_sheet.dart';
import '../services/lyric_sheet_library.dart';
import 'lyric_sheet_screen.dart';

class LyricSheetListScreen extends StatefulWidget {
  const LyricSheetListScreen({super.key});

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
      appBar: AppBar(title: const Text('Letra e Cifra')),
      body: ListView.builder(
        itemCount: _sheets.length,
        itemBuilder: (context, index) {
          final sheet = _sheets[index];
          return ListTile(
            leading: const Icon(Icons.lyrics_outlined),
            title: Text(sheet.title),
            subtitle: sheet.key != null ? Text('Tom: ${sheet.key}') : null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LyricSheetScreen(sheet: sheet),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
