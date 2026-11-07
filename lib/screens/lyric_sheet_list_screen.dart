import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/lyric_sheet.dart';
import '../services/lyric_sheet_library.dart';
import '../theme/app_theme.dart';
import '../widgets/page_parts.dart';
import 'lyric_sheet_screen.dart';
import 'practice_session_screen.dart';
import '../theme/ph.dart';

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
  List<LyricSheet>? _sheets;

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

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final sheets = _sheets;
    return IosPage(
      title: 'Músicas',
      largeTitle: true,
      children: [
        if (sheets == null)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CupertinoActivityIndicator(),
          )
        else
          GroupedSection(
            top: 4,
            header: 'Cifras',
            footer: sheets.isEmpty ? 'Nenhuma cifra encontrada.' : null,
            children: [
              for (final sheet in sheets)
                _SheetRow(
                  sheet: sheet,
                  onTap: () => _push(
                    LyricSheetScreen(
                      sheet: sheet,
                      serverUrl: widget.serverUrl,
                      inputDevice: widget.inputDevice,
                    ),
                  ),
                ),
            ],
          ),
        GroupedSection(
          header: 'Sem letra',
          dividerIndent: 58,
          children: [
            GroupedRow(
              leading: const IconBadge(Ph.metronomeFill),
              title: 'Sequências de acordes',
              subtitle: 'Treine trocas de acorde com metrônomo',
              onTap: () => _push(
                PracticeSessionScreen(
                  serverUrl: widget.serverUrl,
                  inputDevice: widget.inputDevice,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SheetRow extends StatelessWidget {
  final LyricSheet sheet;
  final VoidCallback onTap;

  const _SheetRow({required this.sheet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final chords = extractChords(sheet);
    final meta = [
      if (sheet.artist != null) sheet.artist!,
      difficultyLabel(chords),
    ].join(' · ');

    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sheet.title, style: textTheme.titleMedium),
                    const SizedBox(height: 1),
                    Text(meta, style: textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text(
                      chords.join('  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: fontChord,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Ph.caretRight,
                size: 17,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
