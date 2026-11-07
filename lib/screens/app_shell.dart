import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../state/app_state.dart';
import 'chord_list_screen.dart';
import 'home_screen.dart';
import 'lyric_sheet_list_screen.dart';
import 'profile_screen.dart';
import '../theme/ph.dart';

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

  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        extendBody: true,
        body: ListenableBuilder(
          listenable: appState,
          builder: (context, _) => IndexedStack(
            index: _index,
            children: [
              HomeScreen(
                onOpenChords: () => _select(_chordsTab),
                onOpenSongs: () => _select(_songsTab),
              ),
              LyricSheetListScreen(serverUrl: appState.serverUrl),
              ChordListScreen(serverUrl: appState.serverUrl),
              const ProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar: GlassTabBar.bottom(
          tabs: _tabs,
          selectedIndex: _index,
          onTabSelected: (index) {
            if (index != _index) HapticFeedback.selectionClick();
            _select(index);
          },
          selectedIconColor: colorScheme.primary,
          selectedLabelColor: colorScheme.primary,
          unselectedIconColor: colorScheme.onSurface,
          unselectedLabelColor: colorScheme.onSurface,
        ),
      ),
    );
  }
}
