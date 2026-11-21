import '../services/cifra_parser.dart';
import 'lyric_sheet.dart';

enum StrumPreset {
  common('Comum', ['D1', 'D2', 'U2&', 'U3&', 'D4', 'U4&']),
  downs('Só pra baixo', ['D1', 'D2', 'D3', 'D4']),
  none('Sem batida', []);

  const StrumPreset(this.label, this.tokens);

  final String label;
  final List<String> tokens;
}

const List<String> songPartNames = [
  'Intro',
  'Verso',
  'Pré-refrão',
  'Refrão',
  'Ponte',
  'Solo',
  'Final',
];

const List<int> chordBeatOptions = [1, 2, 4, 8];

const int maxArtistLength = 40;
const int maxTitleLength = 40;
const int maxPartNameLength = 20;
const int minSongBpm = 40;
const int maxSongBpm = 160;

class SongChord {
  final String chord;
  final int beats;

  const SongChord(this.chord, this.beats);

  Map<String, dynamic> toJson() => {'acorde': chord, 'tempos': beats};

  factory SongChord.fromJson(Map<String, dynamic> json) =>
      SongChord(json['acorde'] as String, (json['tempos'] as num).toInt());
}

class SongPart {
  final String name;
  final List<SongChord> chords;

  const SongPart({required this.name, this.chords = const []});

  SongPart copyWith({String? name, List<SongChord>? chords}) =>
      SongPart(name: name ?? this.name, chords: chords ?? this.chords);

  Map<String, dynamic> toJson() => {
    'nome': name,
    'acordes': [for (final c in chords) c.toJson()],
  };

  factory SongPart.fromJson(Map<String, dynamic> json) => SongPart(
    name: json['nome'] as String,
    chords: [
      for (final c in json['acordes'] as List<dynamic>)
        SongChord.fromJson(c as Map<String, dynamic>),
    ],
  );
}

class UserSong {
  final String id;
  final String title;
  final String? artist;
  final int bpm;
  final StrumPreset strum;
  final List<SongPart> parts;

  const UserSong({
    required this.id,
    required this.title,
    this.artist,
    this.bpm = 90,
    this.strum = StrumPreset.common,
    this.parts = const [],
  });

  UserSong copyWith({
    String? title,
    String? artist,
    bool clearArtist = false,
    int? bpm,
    StrumPreset? strum,
    List<SongPart>? parts,
  }) => UserSong(
    id: id,
    title: title ?? this.title,
    artist: clearArtist ? null : (artist ?? this.artist),
    bpm: bpm ?? this.bpm,
    strum: strum ?? this.strum,
    parts: parts ?? this.parts,
  );

  int get chordCount => parts.fold(0, (n, p) => n + p.chords.length);

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': title,
    if (artist != null) 'artista': artist,
    'bpm': bpm,
    'batida': strum.name,
    'partes': [for (final p in parts) p.toJson()],
  };

  factory UserSong.fromJson(Map<String, dynamic> json) => UserSong(
    id: json['id'] as String,
    title: json['titulo'] as String,
    artist: json['artista'] as String?,
    bpm: (json['bpm'] as num?)?.toInt() ?? 90,
    strum: StrumPreset.values.firstWhere(
      (s) => s.name == json['batida'],
      orElse: () => StrumPreset.common,
    ),
    parts: [
      for (final p in json['partes'] as List<dynamic>? ?? const [])
        SongPart.fromJson(p as Map<String, dynamic>),
    ],
  );

  String toCifraText() {
    final out = StringBuffer()..writeln('Tempo: $bpm');
    if (strum.tokens.isNotEmpty) {
      out.writeln('Batida: ${strum.tokens.join(' ')}');
    }
    for (final part in parts) {
      if (part.chords.isEmpty) continue;
      out
        ..writeln()
        ..writeln('[${part.name}]');
      for (var i = 0; i < part.chords.length; i += 4) {
        out.writeln(
          part.chords
              .skip(i)
              .take(4)
              .map((c) => '${c.chord}:${c.beats}')
              .join('  '),
        );
      }
    }
    return out.toString();
  }

  LyricSheet toLyricSheet() {
    final parsed = parseCifra(toCifraText(), title: title);
    return LyricSheet(
      title: title,
      artist: artist,
      tempo: parsed.tempo,
      strummingPattern: parsed.strummingPattern,
      sections: parsed.sections,
      userSongId: id,
    );
  }
}
