import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../state/app_state.dart';
import 'chord_list_screen.dart';
import 'free_practice_screen.dart';
import 'guide_list_screen.dart';
import 'home_screen.dart';
import 'lyric_sheet_list_screen.dart';
import 'preferences_screen.dart';
import 'profile_screen.dart';
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
  static const _songsTab = 1;
  static const _chordsTab = 2;

  static const _tabs = [
    GlassTab(
      icon: Icon(Ph.house),
      activeIcon: Icon(Ph.houseFill),
      label: 'Início',
    ),
    GlassTab(
      icon: Icon(Ph.musicNotes),
      activeIcon: Icon(Ph.musicNotesFill),
      label: 'Músicas',
    ),
    GlassTab(
      icon: Icon(Ph.squaresFour),
      activeIcon: Icon(Ph.squaresFourFill),
      label: 'Acordes',
    ),
    GlassTab(
      icon: Icon(Ph.userCircle),
      activeIcon: Icon(Ph.userCircleFill),
      label: 'Perfil',
    ),
  ];

  // No computador a barra lateral tem as abas do celular e também o que no
  // celular fica nos cards do Início. Preferências e Perfil vão pro pé da
  // barra, junto da entrada de áudio.
  static const _desktopTabs = [
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
      label: 'Preferências',
      bottom: true,
    ),
    DesktopDestination(
      icon: Ph.userCircle,
      selectedIcon: Ph.userCircleFill,
      label: 'Perfil',
      bottom: true,
    ),
  ];
  static const _desktopChordsTab = 2;
  static const _desktopSongsTab = 5;

  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  void _onTabSelected(int index) {
    if (index != _index) HapticFeedback.selectionClick();
    _select(index);
  }

  List<Widget> _pages() => [
    HomeScreen(
      onOpenChords: () => _select(isDesktop ? _desktopChordsTab : _chordsTab),
      onOpenSongs: () => _select(isDesktop ? _desktopSongsTab : _songsTab),
    ),
    LyricSheetListScreen(serverUrl: appState.serverUrl),
    ChordListScreen(serverUrl: appState.serverUrl),
    const ProfileScreen(),
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
          (_) => FreePracticeScreen(serverUrl: appState.serverUrl),
          (_) => const GuideListScreen(),
          (_) => _pages()[1],
          (_) => const PreferencesScreen(),
          (_) => _pages()[3],
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
              IndexedStack(index: _index, children: _pages()),
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
