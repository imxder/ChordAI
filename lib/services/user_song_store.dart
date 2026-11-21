import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_song.dart';

class UserSongStore {
  static const key = 'app_minhas_musicas';
  static const version = 1;

  Future<List<UserSong>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return [
        for (final s in json['musicas'] as List<dynamic>)
          UserSong.fromJson(s as Map<String, dynamic>),
      ];
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> _saveAll(List<UserSong> songs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'versao': version,
        'musicas': [for (final s in songs) s.toJson()],
      }),
    );
  }

  Future<void> save(UserSong song) async {
    final songs = await loadAll();
    final index = songs.indexWhere((s) => s.id == song.id);
    if (index >= 0) {
      songs[index] = song;
    } else {
      songs.add(song);
    }
    await _saveAll(songs);
  }

  Future<void> delete(String id) async {
    final songs = await loadAll();
    songs.removeWhere((s) => s.id == id);
    await _saveAll(songs);
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
