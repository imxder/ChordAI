import 'package:flutter/material.dart';

import '../models/app_theme.dart';
import '../models/chord_difficulty.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/page_parts.dart';
import '../widgets/practice_options_sheet.dart';
import 'chord_detail_screen.dart';
import 'settings_screen.dart';
import 'tuning_select_sheet.dart';
import '../theme/ph.dart';

const List<String> experienceOptions = [
  'Estou começando',
  'Já toco um pouco',
  'Toco há anos',
];

String lastPracticeLabel(String? iso, DateTime now) {
  if (iso == null) return 'Nenhum ainda';
  final date = DateTime.tryParse(iso);
  if (date == null) return 'Nenhum ainda';
  final today = DateTime(now.year, now.month, now.day);
  final days = today
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;
  if (days == 0) return 'Hoje';
  if (days == 1) return 'Ontem';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final learned = appState.learnedChordCount;
    return IosPage(
      title: 'Perfil',
      largeTitle: true,
      children: [
        _ProfileHeader(
          name: appState.profileName,
          experience: appState.profileExperience,
        ),
        GroupedSection(
          header:
              'Acordes aprendidos: $learned de ${chordsByDifficulty.length}',
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final chord in chordsByDifficulty)
                    _LearnedChordTile(chord: chord),
                ],
              ),
            ),
          ],
        ),
        GroupedSection(
          header: 'Prática',
          children: [
            GroupedRow(
              title: 'Último treino',
              value: lastPracticeLabel(
                appState.lastPracticeDateIso,
                DateTime.now(),
              ),
            ),
            GroupedRow(
              title: 'Treinos concluídos',
              value: '${appState.totalSessionsCompleted}',
            ),
            GroupedRow(
              title: 'Acordes certos',
              value: '${appState.totalCorrectChords}',
            ),
          ],
        ),
        GroupedSection(
          header: 'Preferências',
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
              trailing: _ThemePicker(
                selectedIndex: appState.selectedThemeIndex,
              ),
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
              value: appState.chordRecognitionMode.label,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String? experience;

  const _ProfileHeader({required this.name, required this.experience});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final experience = this.experience;

    return Material(
      color: context.tokens.cell,
      borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showEditProfileSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: name.isEmpty
                      ? Icon(
                          Ph.userFill,
                          color: colorScheme.onPrimary,
                          size: 30,
                        )
                      : Text(
                          name.characters.first.toUpperCase(),
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Seu nome' : name,
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      experience ??
                          (name.isEmpty
                              ? 'Toque para preencher o perfil'
                              : 'Editar perfil'),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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

class _LearnedChordTile extends StatelessWidget {
  final String chord;

  const _LearnedChordTile({required this.chord});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final learned = appState.isChordLearned(chord);
    final foreground = learned ? colorScheme.onPrimary : colorScheme.onSurface;

    return Semantics(
      button: true,
      label: '$chord, ${learned ? "aprendido" : "ainda não aprendido"}',
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: learned ? colorScheme.primary : context.tokens.fill,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChordDetailScreen(
                  serverUrl: appState.serverUrl,
                  chord: chord,
                ),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChordName(chord, size: 16, color: foreground),
                    if (learned) ...[
                      const SizedBox(width: 4),
                      Icon(Ph.check, size: 14, color: foreground),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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

Future<void> showEditProfileSheet(BuildContext context) {
  return showGlassSheet(
    context,
    startFull: true,
    builder: (_) => const _EditProfileSheet(),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  String? _experience;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: appState.profileName);
    _experience = appState.profileExperience;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await appState.setProfile(name: _name.text, experience: _experience);
    if (mounted) Navigator.of(context).pop();
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
            SheetHeader(
              title: 'Perfil',
              actionLabel: 'Salvar',
              onAction: _save,
            ),
            GroupedSection(
              top: 8,
              header: 'Como quer ser chamado',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 30,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Seu nome',
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                ),
              ],
            ),
            GroupedSection(
              header: 'Experiência com violão',
              children: [
                for (final option in experienceOptions)
                  CheckRow(
                    title: option,
                    selected: _experience == option,
                    onTap: () => setState(() => _experience = option),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
