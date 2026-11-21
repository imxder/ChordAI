import 'package:flutter/material.dart';

import '../widgets/page_parts.dart';
import 'profile_screen.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const IosPage(
      title: 'Preferências',
      largeTitle: true,
      children: [PreferencesSection(showHeader: false, top: 8)],
    );
  }
}
