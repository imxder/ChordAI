import 'package:flutter/material.dart';

import '../models/theme_options.dart';
import '../state/app_state.dart';
import '../theme/platform_style.dart';
import '../widgets/desktop_input.dart';
import '../widgets/page_parts.dart';
import '../widgets/practice_options_sheet.dart';
import 'privacy_screen.dart';
import 'recognition_settings_screen.dart';
import 'tuning_select_sheet.dart';
import '../theme/ph.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IosPage(
      title: settingsTitle,
      largeTitle: true,
      children: const [PreferencesSection(showHeader: false, top: 8)],
    );
  }
}

class PreferencesSection extends StatelessWidget {
  final bool showHeader;
  final double top;

  const PreferencesSection({super.key, this.showHeader = true, this.top = 24});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _preferences(context),
        GroupedSection(
          header: 'Sons',
          footer:
              'O clique do metrônomo, o som de acorde aprendido e o da corda '
              'afinada no afinador.',
          children: [
            SwitchRow(
              key: const ValueKey('sons'),
              title: 'Sons',
              value: appState.soundsEnabled,
              onChanged: appState.setSoundsEnabled,
            ),
          ],
        ),
        GroupedSection(
          header: 'Apresentação',
          footer:
              'Ligado, a apresentação do app aparece toda vez que ele abre. '
              'Desligado, ela só aparece na primeira vez.',
          children: [
            SwitchRow(
              key: const ValueKey('apresentação ao abrir'),
              title: 'Mostrar ao abrir o app',
              value: appState.alwaysShowOnboarding,
              onChanged: appState.setAlwaysShowOnboarding,
            ),
          ],
        ),
      ],
    );
  }

  Widget _preferences(BuildContext context) {
    return GroupedSection(
      header: showHeader ? 'Preferências' : null,
      top: top,
      dividerIndent: 58,
      children: [
        GroupedRow(
          leading: const IconBadge(Ph.circleHalfFill),
          title: 'Aparência',
          value: appState.appearance.label,
          onTap: () => showAppearanceSheet(context),
        ),
        GroupedRow(
          leading: const IconBadge(Ph.paletteFill),
          title: 'Cor do app',
          trailing: _ThemePicker(selectedIndex: appState.selectedThemeIndex),
        ),
        GroupedRow(
          leading: const IconBadge(Ph.gaugeFill),
          title: 'Afinação',
          value: appState.activeTuningName,
          onTap: () => showTuningSelectSheet(context),
        ),
        GroupedRow(
          leading: const IconBadge(Ph.textAa),
          title: 'Leitura das cifras',
          onTap: () => showPracticeOptionsSheet(context),
        ),
        GroupedRow(
          leading: const IconBadge(Ph.microphoneFill),
          title: 'Reconhecimento',
          value: appState.onDeviceModel.label,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RecognitionSettingsScreen(),
            ),
          ),
        ),
        GroupedRow(
          leading: const IconBadge(Ph.shieldCheckFill),
          title: 'Privacidade',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const PrivacyScreen())),
        ),
      ],
    );
  }
}

class _ThemePicker extends StatelessWidget {
  final int selectedIndex;

  const _ThemePicker({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < appThemeOptions.length; i++)
          Semantics(
            selected: selectedIndex == i,
            button: true,
            label: 'Cor ${appThemeOptions[i].name}',
            excludeSemantics: true,
            child: ClickCursor(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => appState.selectTheme(i),
                child: SizedBox(
                  width: 40,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedIndex == i
                              ? onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dark
                              ? appThemeOptions[i].darkColor
                              : appThemeOptions[i].color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showAppearanceSheet(BuildContext context) {
  return showGlassSheet(
    context,
    size: 0.6,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(title: 'Aparência'),
              GroupedSection(
                top: 8,
                children: [
                  for (final option in AppAppearance.values)
                    CheckRow(
                      title: option.label,
                      subtitle: option.description,
                      selected: appState.appearance == option,
                      onTap: () => appState.setAppearance(option),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
