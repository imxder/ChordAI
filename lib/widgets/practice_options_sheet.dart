import 'package:flutter/cupertino.dart';

import '../state/app_state.dart';
import 'page_parts.dart';

Future<void> showPracticeOptionsSheet(BuildContext context) {
  return showGlassSheet(
    context,
    builder: (context) => const _PracticeOptionsSheet(),
  );
}

class _PracticeOptionsSheet extends StatelessWidget {
  const _PracticeOptionsSheet();

  static const _fontSizes = [0.85, 1.0, 1.3];
  static const _fontLabels = ['Pequeno', 'Médio', 'Grande'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHeader(title: 'Leitura das cifras'),
              GroupedSection(
                top: 8,
                header: 'Tamanho da letra',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: CupertinoSlidingSegmentedControl<double>(
                      groupValue: _fontSizes.contains(appState.lyricFontScale)
                          ? appState.lyricFontScale
                          : 1.0,
                      children: {
                        for (var i = 0; i < _fontSizes.length; i++)
                          _fontSizes[i]: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(_fontLabels[i]),
                          ),
                      },
                      onValueChanged: (value) {
                        if (value != null) appState.setLyricFontScale(value);
                      },
                    ),
                  ),
                ],
              ),
              GroupedSection(
                header: 'Ao tocar junto',
                children: [
                  SwitchRow(
                    title: 'Mostrar diagrama',
                    value: appState.showGuitarNeckInPlayer,
                    onChanged: appState.setShowGuitarNeckInPlayer,
                  ),
                  SwitchRow(
                    title: 'Rolar a cifra sozinha',
                    value: appState.autoScrollInPlayer,
                    onChanged: appState.setAutoScrollInPlayer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
