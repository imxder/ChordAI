import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/app_theme.dart';
import 'models/lyric_sheet.dart';
import 'screens/achievements_screen.dart';
import 'screens/chord_list_screen.dart';
import 'screens/free_practice_screen.dart';
import 'screens/guide_list_screen.dart';
import 'screens/lyric_sheet_list_screen.dart';
import 'screens/lyric_sheet_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/tuner_screen.dart';
import 'services/lyric_sheet_library.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appState.loadProgress();
  runApp(const ChordAIApp());
}

class ChordAIApp extends StatelessWidget {
  const ChordAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final seedColor =
            appThemeOptions[appState.selectedThemeIndex].color;
        final colorScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        );
        const background = Color(0xFFFBF3E7);
        final textTheme = GoogleFonts.nunitoSansTextTheme().copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            fontSize: 57,
            fontWeight: FontWeight.w600,
          ),
          displayMedium: GoogleFonts.playfairDisplay(
            fontSize: 45,
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        );
        return MaterialApp(
          title: 'ChordAI',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
            scaffoldBackgroundColor: background,
            textTheme: textTheme,
            appBarTheme: AppBarTheme(
              backgroundColor: background,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleTextStyle: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
          ),
          home: appState.hasCompletedOnboarding
              ? const HomePage()
              : const OnboardingScreen(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  void _openChordList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChordListScreen(serverUrl: appState.serverUrl),
      ),
    );
  }

  void _openLyricList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LyricSheetListScreen(serverUrl: appState.serverUrl),
      ),
    );
  }

  void _openTuner() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TunerScreen()),
    );
  }

  void _openFreePractice() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FreePracticeScreen(serverUrl: appState.serverUrl),
      ),
    );
  }

  void _openGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GuideListScreen()),
    );
  }

  void _openAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    );
  }

  Future<void> _continueLastSong() async {
    final title = appState.lastSongTitle;
    if (title == null) return;
    final sheets = await LyricSheetLibrary().loadAll();
    LyricSheet? sheet;
    for (final s in sheets) {
      if (s.title == title) {
        sheet = s;
        break;
      }
    }
    if (sheet == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LyricSheetScreen(
          sheet: sheet!,
          serverUrl: appState.serverUrl,
        ),
      ),
    );
  }

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 12),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 1:
        _openLyricList();
        break;
      case 2:
        _openChordList();
        break;
      case 3:
        _openAchievements();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bom dia,',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.outline,
                              ),
                        ),
                        Text(
                          'vamos tocar',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _openAchievements,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_fire_department,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (appState.lastSongTitle != null)
                Card(
                  clipBehavior: Clip.antiAlias,
                  color: colorScheme.primary,
                  child: InkWell(
                    onTap: _continueLastSong,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CONTINUAR',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  appState.lastSongTitle!,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${appState.lastSongChordCount} acordes · Em andamento',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (appState.lastSongTitle != null) const SizedBox(height: 24),
              Text('Explorar', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                color: colorScheme.primary.withValues(alpha: 0.1),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.menu_book_outlined, color: colorScheme.primary),
                  ),
                  title: const Text('Guia do iniciante'),
                  subtitle: const Text('Acessórios, regulagem, como afinar e mais'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openGuide,
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildActionTile(
                    context,
                    icon: Icons.school_outlined,
                    iconBackground: const Color(0xFFFBE4D0),
                    iconColor: const Color(0xFFC1623D),
                    label: 'Aprender acordes',
                    onPressed: _openChordList,
                  ),
                  _buildActionTile(
                    context,
                    icon: Icons.music_note_outlined,
                    iconBackground: const Color(0xFFE0ECD8),
                    iconColor: const Color(0xFF6B7A4F),
                    label: 'Tocar músicas',
                    onPressed: _openLyricList,
                  ),
                  _buildActionTile(
                    context,
                    icon: Icons.graphic_eq,
                    iconBackground: const Color(0xFFE2E6F0),
                    iconColor: const Color(0xFF3E4C8C),
                    label: 'Afinador',
                    onPressed: _openTuner,
                  ),
                  _buildActionTile(
                    context,
                    icon: Icons.hearing,
                    iconBackground: const Color(0xFFF2DEE6),
                    iconColor: const Color(0xFF9C3B6B),
                    label: 'Treino livre (IA)',
                    onPressed: _openFreePractice,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: _onBottomNavTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.lyrics_outlined), label: 'Músicas'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Acordes'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}
