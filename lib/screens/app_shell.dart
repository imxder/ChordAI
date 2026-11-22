import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../state/app_state.dart';
import 'chord_list_screen.dart';
import 'free_practice_screen.dart';
import 'guide_list_screen.dart';
import 'home_screen.dart';
import 'lyric_sheet_list_screen.dart';
import 'settings_screen.dart';
import 'tuner_screen.dart';
import '../theme/ph.dart';
import '../theme/platform_style.dart';
import '../widgets/audio_input_section.dart';
import '../widgets/desktop_shell.dart';

const appTabBarKey = Key('app_tab_bar');

/// Barra lateral do computador (Windows e Mac), no lugar da barra de abas.
const appSideBarKey = Key('app_side_bar');

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _chordsTab = 1;
  static const _recognizeTab = 2;
  static const _tunerTab = 3;

  static const _tabs = [
    GlassTab(
      icon: Icon(Ph.house),
      activeIcon: Icon(Ph.houseFill),
      label: 'Início',
    ),
    GlassTab(
      icon: Icon(Ph.squaresFour),
      activeIcon: Icon(Ph.squaresFourFill),
      label: 'Acordes',
    ),
    GlassTab(
      icon: Icon(Ph.ear),
      activeIcon: Icon(Ph.earFill),
      label: 'Reconhecer',
    ),
    GlassTab(
      icon: Icon(Ph.gauge),
      activeIcon: Icon(Ph.gaugeFill),
      label: 'Afinador',
    ),
  ];

  static List<DesktopDestination> get _desktopTabs => [
    DesktopDestination(
      icon: Ph.house,
      selectedIcon: Ph.houseFill,
      label: 'Início',
    ),
    DesktopDestination(
      icon: Ph.gauge,
      selectedIcon: Ph.gaugeFill,
      label: 'Afinador',
      keepAlive: false,
    ),
    DesktopDestination(
      icon: Ph.squaresFour,
      selectedIcon: Ph.squaresFourFill,
      label: 'Aprender acordes',
    ),
    DesktopDestination(
      icon: Ph.ear,
      selectedIcon: Ph.earFill,
      label: 'Reconhecer acorde',
      keepAlive: false,
    ),
    DesktopDestination(
      icon: Ph.bookOpen,
      selectedIcon: Ph.bookOpenFill,
      label: 'Guia do iniciante',
      keepAlive: false,
    ),
    DesktopDestination(
      icon: Ph.musicNotes,
      selectedIcon: Ph.musicNotesFill,
      label: 'Músicas',
    ),
    DesktopDestination(
      icon: Ph.gearSix,
      selectedIcon: Ph.gearSixFill,
      label: settingsTitle,
      bottom: true,
    ),
  ];
  static const _desktopChordsTab = 2;
  static const _desktopSongsTab = 5;
  static const _desktopSettingsTab = 6;

  int _index = 0;

  static const _macMenu = MethodChannel('chordai/menu');

  @override
  void initState() {
    super.initState();
    if (desktopLook == DesktopLook.mac) {
      _macMenu.setMethodCallHandler((call) async {
        if (call.method == 'abrirAjustes' && mounted) {
          _select(_desktopSettingsTab);
        }
      });
    }
  }

  @override
  void dispose() {
    if (desktopLook == DesktopLook.mac) _macMenu.setMethodCallHandler(null);
    super.dispose();
  }

  void _select(int index) => setState(() => _index = index);

  void _onTabSelected(int index) {
    if (index != _index) HapticFeedback.selectionClick();
    _select(index);
  }

  void _openSongs() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LyricSheetListScreen()));
  }

  List<Widget> _pages() => [
    HomeScreen(
      onOpenChords: () => _select(_desktopChordsTab),
      onOpenSongs: () => _select(_desktopSongsTab),
    ),
    LyricSheetListScreen(),
    ChordListScreen(),
  ];

  List<Widget> _mobilePages() => [
    HomeScreen(
      onOpenChords: () => _select(_chordsTab),
      onOpenSongs: _openSongs,
    ),
    ChordListScreen(),
    if (_index == _recognizeTab) FreePracticeScreen() else const SizedBox(),
    if (_index == _tunerTab) const TunerScreen() else const SizedBox(),
  ];

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return DesktopShell(
        key: appSideBarKey,
        destinations: _desktopTabs,
        // No computador é comum trocar de microfone (interface, webcam,
        // pedaleira), então a entrada fica sempre à mão no menu.
        actions: const [
          DesktopPaneAction(
            icon: Ph.microphoneFill,
            label: 'Entrada de áudio',
            onTap: showAudioInputDialog,
          ),
        ],
        pages: [
          (_) => _pages()[0],
          (_) => const TunerScreen(),
          (_) => _pages()[2],
          (_) => FreePracticeScreen(),
          (_) => const GuideListScreen(),
          (_) => _pages()[1],
          (_) => const SettingsScreen(),
        ],
        rebuildOn: appState,
        selectedIndex: _index,
        onSelected: _select,
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        extendBody: useLiquidGlass,
        body: ListenableBuilder(
          listenable: appState,
          builder: (context, _) =>
              IndexedStack(index: _index, children: _mobilePages()),
        ),
        bottomNavigationBar: useLiquidGlass
            ? GlassTabBar.bottom(
                key: appTabBarKey,
                tabs: _tabs,
                selectedIndex: _index,
                onTabSelected: _onTabSelected,
                selectedIconColor: colorScheme.primary,
                selectedLabelColor: colorScheme.primary,
                unselectedIconColor: colorScheme.onSurface,
                unselectedLabelColor: colorScheme.onSurface,
              )
            : NavigationBar(
                key: appTabBarKey,
                selectedIndex: _index,
                onDestinationSelected: _onTabSelected,
                destinations: [
                  for (final tab in _tabs)
                    NavigationDestination(
                      icon: tab.icon!,
                      selectedIcon: tab.activeIcon,
                      label: tab.label!,
                    ),
                ],
              ),
      ),
    );
  }
}
