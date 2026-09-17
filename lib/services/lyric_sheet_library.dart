import 'package:flutter/services.dart' show rootBundle;

import '../models/lyric_sheet.dart';
import 'cifra_parser.dart';

class LyricSheetLibrary {
  static const List<({String title, String path})> _assets = [
    (
      title: 'All Too Well - Taylor Swift',
      path: 'assets/lyrics/all_too_well.txt',
    ),
  ];

  Future<List<LyricSheet>> loadAll() async {
    final sheets = <LyricSheet>[];
    for (final entry in _assets) {
      final raw = await rootBundle.loadString(entry.path);
      sheets.add(parseCifra(raw, title: entry.title));
    }
    return sheets;
  }
}
