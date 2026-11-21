import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/user_song.dart';
import '../services/user_song_store.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../theme/ph.dart';
import '../widgets/page_parts.dart';

enum SongEditorResult { saved, deleted }

class SongEditorScreen extends StatefulWidget {
  final UserSong? song;
  final UserSongStore? store;

  const SongEditorScreen({super.key, this.song, this.store});

  @override
  State<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends State<SongEditorScreen> {
  late final UserSongStore _store = widget.store ?? UserSongStore();
  late final TextEditingController _title = TextEditingController(
    text: widget.song?.title ?? '',
  );
  late final TextEditingController _artist = TextEditingController(
    text: widget.song?.artist ?? '',
  );
  late int _bpm = widget.song?.bpm ?? 90;
  late StrumPreset _strum = widget.song?.strum ?? StrumPreset.common;
  late List<SongPart> _parts = [
    ...widget.song?.parts ??
        const [SongPart(name: 'Intro'), SongPart(name: 'Refrão')],
  ];

  bool get _editing => widget.song != null;

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final artist = _artist.text.trim();
    if (title.isEmpty) {
      _message('Dê um nome pra música');
      return;
    }
    final parts = _parts.where((p) => p.chords.isNotEmpty).toList();
    if (parts.isEmpty) {
      _message('Coloque pelo menos um acorde');
      return;
    }
    final song = UserSong(
      id: widget.song?.id ?? UserSongStore.newId(),
      title: title,
      artist: artist.isEmpty ? null : artist,
      bpm: _bpm,
      strum: _strum,
      parts: parts,
    );
    await _store.save(song);
    if (mounted) Navigator.of(context).pop(SongEditorResult.saved);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar a música?'),
        content: Text('"${widget.song!.title}" sai do aparelho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _store.delete(widget.song!.id);
    if (mounted) Navigator.of(context).pop(SongEditorResult.deleted);
  }

  void _setPart(int index, SongPart part) =>
      setState(() => _parts = [..._parts]..[index] = part);

  void _movePart(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _parts.length) return;
    setState(() {
      final parts = [..._parts];
      final part = parts.removeAt(index);
      parts.insert(target, part);
      _parts = parts;
    });
  }

  Future<void> _addChord(int partIndex) async {
    final chord = await showGlassSheet<SongChord>(
      context,
      builder: (_) => const _ChordPicker(),
    );
    if (chord == null) return;
    final part = _parts[partIndex];
    _setPart(partIndex, part.copyWith(chords: [...part.chords, chord]));
  }

  Future<void> _editChord(int partIndex, int chordIndex) async {
    final part = _parts[partIndex];
    final current = part.chords[chordIndex];
    final result = await showGlassSheet<SongChord?>(
      context,
      builder: (_) => _ChordPicker(initial: current, canRemove: true),
    );
    if (result == null) return;
    final chords = [...part.chords];
    if (result.beats == 0) {
      chords.removeAt(chordIndex);
    } else {
      chords[chordIndex] = result;
    }
    _setPart(partIndex, part.copyWith(chords: chords));
  }

  Future<void> _addPart() async {
    final name = await showGlassSheet<String>(
      context,
      builder: (_) => const _PartNamePicker(),
    );
    if (name == null) return;
    setState(() => _parts = [..._parts, SongPart(name: name)]);
  }

  Future<void> _chooseStrum() async {
    final strum = await showGlassSheet<StrumPreset>(
      context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHeader(title: 'Batida'),
              GroupedSection(
                top: 8,
                children: [
                  for (final option in StrumPreset.values)
                    CheckRow(
                      title: option.label,
                      subtitle: _strumText(option),
                      selected: option == _strum,
                      onTap: () => Navigator.of(sheetContext).pop(option),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (strum != null) setState(() => _strum = strum);
  }

  static String? _strumText(StrumPreset preset) {
    if (preset.tokens.isEmpty) return null;
    return preset.tokens
        .map((t) => '${t.startsWith('D') ? '↓' : '↑'}${t.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final known = appState.chordsInModel;
    return IosPage(
      title: _editing ? 'Editar música' : 'Nova música',
      trailing: CupertinoButton(
        key: const ValueKey('salvar música'),
        padding: EdgeInsets.zero,
        onPressed: _save,
        child: const Text(
          'Salvar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      children: [
        GroupedSection(
          top: 8,
          header: 'Música',
          children: [
            _Field(
              key: const ValueKey('nome da música'),
              controller: _title,
              hint: 'Nome',
              maxLength: maxTitleLength,
            ),
            _Field(
              key: const ValueKey('artista'),
              controller: _artist,
              hint: 'Artista (opcional)',
              maxLength: maxArtistLength,
            ),
          ],
        ),
        GroupedSection(
          children: [
            GroupedRow(
              title: 'Andamento',
              chevron: false,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _bpm <= minSongBpm
                        ? null
                        : () => setState(() => _bpm--),
                    icon: const Icon(Ph.minus, semanticLabel: 'Mais devagar'),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '$_bpm BPM',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: fontChord),
                    ),
                  ),
                  IconButton(
                    onPressed: _bpm >= maxSongBpm
                        ? null
                        : () => setState(() => _bpm++),
                    icon: const Icon(Ph.plus, semanticLabel: 'Mais rápido'),
                  ),
                ],
              ),
            ),
            GroupedRow(
              title: 'Batida',
              value: _strum.label,
              onTap: _chooseStrum,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'O app reconhece só estes acordes: ${known.join(', ')}.',
            style: textTheme.bodySmall,
          ),
        ),
        for (final (i, part) in _parts.indexed)
          GroupedSection(
            header: part.name,
            footer: _unknownFooter(part, known),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (j, chord) in part.chords.indexed)
                      _EditorChip(
                        label: chord.chord,
                        beats: chord.beats,
                        unknown: !known.contains(chord.chord),
                        onTap: () => _editChord(i, j),
                      ),
                    _EditorChip(
                      key: ValueKey('mais acorde $i'),
                      label: '+ Acorde',
                      onTap: () => _addChord(i),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: i == 0 ? null : () => _movePart(i, -1),
                    icon: const Icon(Ph.arrowUp, semanticLabel: 'Subir parte'),
                  ),
                  IconButton(
                    onPressed: i == _parts.length - 1
                        ? null
                        : () => _movePart(i, 1),
                    icon: const Icon(
                      Ph.arrowDown,
                      semanticLabel: 'Descer parte',
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _parts = [..._parts]..removeAt(i)),
                    icon: const Icon(Ph.trash, semanticLabel: 'Tirar parte'),
                  ),
                ],
              ),
            ],
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('mais parte'),
          onPressed: _addPart,
          icon: const Icon(Ph.plus, size: 20),
          label: const Text('Parte'),
        ),
        if (_editing) ...[
          const SizedBox(height: 24),
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Apagar música'),
          ),
        ],
      ],
    );
  }

  String? _unknownFooter(SongPart part, List<String> known) {
    final unknown = {
      for (final c in part.chords)
        if (!known.contains(c.chord)) c.chord,
    };
    if (unknown.isEmpty) return null;
    return '${unknown.join(', ')}: o modelo escolhido não reconhece, então não '
        'conta no placar.';
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;

  const _Field({
    super.key,
    required this.controller,
    required this.hint,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        maxLength: maxLength,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _EditorChip extends StatelessWidget {
  final String label;
  final int? beats;
  final bool unknown;
  final VoidCallback onTap;

  const _EditorChip({
    super.key,
    required this.label,
    required this.onTap,
    this.beats,
    this.unknown = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final color = unknown ? colorScheme.error : colorScheme.primary;
    final radius = BorderRadius.circular(GlassTokens.radiusMd);
    return Semantics(
      button: true,
      label: beats == null ? label : '$label, $beats tempos',
      excludeSemantics: true,
      child: Material(
        color: tokens.fill,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              beats == null ? label : '$label · $beats',
              style: TextStyle(
                fontFamily: fontChord,
                fontWeight: FontWeight.w600,
                color: color,
                decoration: unknown ? TextDecoration.lineThrough : null,
                decorationColor: colorScheme.error,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChordPicker extends StatefulWidget {
  final SongChord? initial;
  final bool canRemove;

  const _ChordPicker({this.initial, this.canRemove = false});

  @override
  State<_ChordPicker> createState() => _ChordPickerState();
}

class _ChordPickerState extends State<_ChordPicker> {
  late String? _chord = widget.initial?.chord;
  late int _beats = widget.initial?.beats ?? 4;

  @override
  Widget build(BuildContext context) {
    final known = appState.chordsInModel;
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: 'Acorde',
              actionLabel: 'Pronto',
              onAction: _chord == null
                  ? null
                  : () => Navigator.of(context).pop(SongChord(_chord!, _beats)),
            ),
            GroupedSection(
              top: 8,
              header: 'Qual acorde',
              footer: 'O app reconhece só estes acordes.',
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final chord in known)
                        ChoiceChip(
                          key: ValueKey('escolher $chord'),
                          label: Text(
                            chord,
                            style: const TextStyle(fontFamily: fontChord),
                          ),
                          selected: chord == _chord,
                          onSelected: (_) => setState(() => _chord = chord),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            GroupedSection(
              header: 'Quantos tempos',
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _beats,
                    children: {
                      for (final b in chordBeatOptions)
                        b: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('$b'),
                        ),
                    },
                    onValueChanged: (value) {
                      if (value != null) setState(() => _beats = value);
                    },
                  ),
                ),
              ],
            ),
            if (widget.canRemove) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    Navigator.of(context)
                        .pop(SongChord(widget.initial!.chord, 0)),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                child: const Text('Tirar acorde'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PartNamePicker extends StatefulWidget {
  const _PartNamePicker();

  @override
  State<_PartNamePicker> createState() => _PartNamePickerState();
}

class _PartNamePickerState extends State<_PartNamePicker> {
  final _other = TextEditingController();

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _useOther() {
    final name = _other.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader(title: 'Nova parte'),
            GroupedSection(
              top: 8,
              children: [
                for (final name in songPartNames)
                  GroupedRow(
                    title: name,
                    onTap: () => Navigator.of(context).pop(name),
                  ),
              ],
            ),
            GroupedSection(
              header: 'Outro nome',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _other,
                    maxLength: maxPartNameLength,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ex.: Ponte 2',
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _useOther(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _useOther,
              child: const Text('Usar esse nome'),
            ),
          ],
        ),
      ),
    );
  }
}
