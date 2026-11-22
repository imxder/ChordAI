import 'package:flutter/material.dart';

import '../models/guide_content.dart';
import '../models/lyric_sheet.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/chord_sequence.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/guitar_parts_drawing.dart';
import '../widgets/page_parts.dart';
import '../widgets/strings_illustration.dart';
import 'chord_list_screen.dart';
import 'chord_practice_screen.dart';
import 'guide_list_screen.dart';
import 'lyric_sheet_list_screen.dart';
import 'practice_session_screen.dart';
import 'tuner_screen.dart';
import '../theme/ph.dart';

const _commonStrum = [
  StrumKind.down,
  null,
  StrumKind.down,
  StrumKind.up,
  null,
  StrumKind.up,
  StrumKind.down,
  StrumKind.up,
];

const _noteNames = [
  ('C', 'Dó'),
  ('D', 'Ré'),
  ('E', 'Mi'),
  ('F', 'Fá'),
  ('G', 'Sol'),
  ('A', 'Lá'),
  ('B', 'Si'),
  ('m', 'menor'),
];

class GuideDetailScreen extends StatefulWidget {
  final GuideTopic topic;

  /// Falso quando o guia é aberto de dentro do afinador: aí o botão "Abrir o
  /// afinador" abriria um segundo afinador por cima do primeiro.
  final bool showTunerButton;

  const GuideDetailScreen({
    super.key,
    required this.topic,
    this.showTunerButton = true,
  });

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  GuideTopic get topic => widget.topic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => appState.markGuideTopicRead(topic.id),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _backToList() {
    final navigator = Navigator.of(context);
    var found = false;
    navigator.popUntil((route) {
      if (GuideListScreen.isListRoute(route)) {
        found = true;
        return true;
      }
      return route.isFirst;
    });
    if (!found) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const GuideListScreen()),
      );
    }
  }

  Widget? _actionButton() {
    final (IconData icon, String label, VoidCallback onPressed)? action =
        switch (topic.action) {
          GuideAction.next => switch (guideTopicAfter(topic)) {
            final next? => (
              Ph.caretRight,
              'Próximo: ${next.title}',
              () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => GuideDetailScreen(topic: next),
                ),
              ),
            ),
            null => null,
          },
          GuideAction.list => (Ph.list, 'Voltar pra lista', _backToList),
          GuideAction.tuner =>
            widget.showTunerButton
                ? (
                    Ph.gaugeFill,
                    'Abrir o afinador',
                    () => _push(const TunerScreen()),
                  )
                : null,
          GuideAction.chords => (
            Ph.squaresFourFill,
            'Ver os acordes',
            () => _push(const ChordListScreen()),
          ),
          GuideAction.practiceEm => (
            Ph.microphoneFill,
            'Treinar o Em',
            () => _push(const ChordPracticeScreen(chord: 'Em')),
          ),
          GuideAction.songs => (
            Ph.musicNotesFill,
            'Ver as músicas',
            () => _push(const LyricSheetListScreen()),
          ),
          GuideAction.sequences => (
            Ph.metronomeFill,
            'Treinar sequências',
            () => _push(const PracticeSessionScreen()),
          ),
          GuideAction.nextChord => switch (appState.nextChordToLearn) {
            final chord? => (
              Ph.microphoneFill,
              'Treinar o $chord',
              () => _push(ChordPracticeScreen(chord: chord)),
            ),
            null => (
              Ph.squaresFourFill,
              'Ver os acordes',
              () => _push(const ChordListScreen()),
            ),
          },
        };
    if (action == null) return null;
    final (icon, label, onPressed) = action;
    return FilledButton.icon(
      key: const ValueKey('ação do guia'),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }

  Widget? _illustration() {
    return switch (topic.id) {
      'partes' => const GuitarPartsDrawing(),
      'afinar' => const StringsIllustration(),
      'diagrama' || 'primeiro_acorde' => Center(
        child: SizedBox(
          width: 160,
          child: Column(
            children: [
              const GuitarNeck(chord: 'Em'),
              const SizedBox(height: 8),
              ChordName('Em', size: 24),
            ],
          ),
        ),
      ),
      'cifra' => const ChordSequence(
        collapseRepeats: true,
        lines: [
          [
            SequenceChord('Em', 4, 0, strum: _commonStrum),
            SequenceChord('Am', 4, 1, strum: _commonStrum),
            SequenceChord('Em', 4, 2, strum: _commonStrum),
            SequenceChord('Am', 4, 3, strum: _commonStrum),
          ],
          [
            SequenceChord('C', 4, 4, strum: _commonStrum),
            SequenceChord('G', 4, 5, strum: _commonStrum),
          ],
        ],
      ),
      'batida' => const ChordSequence(
        arrowScale: 1.3,
        lines: [
          [SequenceChord('Em', 4, 0, strum: _commonStrum)],
        ],
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final illustration = _illustration();
    final button = _actionButton();
    return IosPage(
      title: topic.title,
      children: [
        if (illustration != null) ...[
          const SizedBox(height: 8),
          illustration,
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final paragraph in topic.paragraphs) ...[
                Text(paragraph, style: textTheme.bodyLarge),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (topic.id == 'cifra')
          GroupedSection(
            top: 4,
            header: 'As letras',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    for (final (letter, name) in _noteNames)
                      SizedBox(
                        width: 120,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: ChordName(letter, size: 20),
                            ),
                            Text(name, style: textTheme.bodyLarge),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        if (topic.highlight != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Ph.lightbulbFill, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(topic.highlight!, style: textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        if (topic.steps.isNotEmpty)
          GroupedSection(
            header: topic.id == 'diagrama'
                ? 'O que cada parte quer dizer'
                : 'Passo a passo',
            dividerIndent: 52,
            children: [
              for (final (index, step) in topic.steps.indexed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: fontChord,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(step, style: textTheme.bodyLarge)),
                    ],
                  ),
                ),
            ],
          ),
        if (topic.sources.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
            child: Text(
              '${topic.sources.length == 1 ? 'Fonte' : 'Fontes'}: '
              '${topic.sources.join(' e ')}',
              style: textTheme.bodySmall,
            ),
          ),
        if (button != null) ...[const SizedBox(height: 24), button],
      ],
    );
  }
}
