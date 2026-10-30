import 'package:flutter/services.dart' show rootBundle;

import '../models/lyric_sheet.dart';
import 'cifra_parser.dart';

class LyricSheetLibrary {
  static const List<({String title, String artist, String path})> _assets = [
    (
      title: 'All Too Well',
      artist: 'Taylor Swift',
      path: 'assets/lyrics/all_too_well.txt',
    ),
  ];

  Future<List<LyricSheet>> loadAll() async {
    final sheets = <LyricSheet>[];
    for (final entry in _assets) {
      final raw = await rootBundle.loadString(entry.path);
      final parsed = parseCifra(raw, title: entry.title);
      sheets.add(
        LyricSheet(
          title: parsed.title,
          artist: entry.artist,
          key: parsed.key,
          tempo: parsed.tempo,
          capo: parsed.capo,
          strummingPattern: parsed.strummingPattern,
          sections: parsed.sections,
        ),
      );
    }
    return sheets;
  }
}
