import 'package:flutter/material.dart';

import '../models/guide_content.dart';
import '../widgets/page_parts.dart';
import 'guide_detail_screen.dart';
import '../theme/ph.dart';

const _topicIcons = {
  'acessorios': Ph.backpackFill,
  'regular': Ph.wrenchFill,
  'afinar': Ph.gaugeFill,
  'cordas': Ph.arrowsClockwiseFill,
  'postura': Ph.userFill,
  'dor_dedos': Ph.bandaidsFill,
};

class GuideListScreen extends StatelessWidget {
  const GuideListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IosPage(
      title: 'Guia do iniciante',
      children: [
        GroupedSection(
          top: 8,
          dividerIndent: 58,
          children: [
            for (final topic in guideTopics)
              GroupedRow(
                leading: IconBadge(_topicIcons[topic.id] ?? Ph.bookOpenFill),
                title: topic.title,
                subtitle: topic.summary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuideDetailScreen(topic: topic),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
