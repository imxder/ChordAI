import 'package:flutter/material.dart';

import '../models/guide_content.dart';
import '../state/app_state.dart';
import '../widgets/page_parts.dart';
import 'guide_detail_screen.dart';
import '../theme/ph.dart';

const guideTopicIcons = {
  'partes': Ph.bookOpenFill,
  'postura': Ph.userFill,
  'afinar': Ph.gaugeFill,
  'diagrama': Ph.squaresFourFill,
  'primeiro_acorde': Ph.checkCircleFill,
  'cifra': Ph.musicNotesFill,
  'batida': Ph.metronomeFill,
  'trocar_acorde': Ph.playFill,
  'treino_diario': Ph.lightbulbFill,
  'dor_dedos': Ph.bandaidsFill,
  'acessorios': Ph.backpackFill,
  'cordas': Ph.arrowsClockwiseFill,
  'regular': Ph.wrenchFill,
};

class GuideListScreen extends StatelessWidget {
  const GuideListScreen({super.key});

  static final _listRoutes = Expando<bool>();

  /// Se [route] é uma tela com a lista do guia. O "Voltar pra lista" do
  /// último tópico volta até ela em vez de abrir outra lista por cima.
  static bool isListRoute(Route<dynamic> route) => _listRoutes[route] ?? false;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route != null) _listRoutes[route] = true;
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => IosPage(
        title: 'Guia do iniciante',
        children: [
          for (final group in GuideGroup.values)
            GroupedSection(
              top: group == GuideGroup.values.first ? 8 : 24,
              header: group.title,
              dividerIndent: 58,
              children: [
                for (final topic in guideTopics.where((t) => t.group == group))
                  GroupedRow(
                    key: ValueKey('guia ${topic.id}'),
                    leading: IconBadge(
                      guideTopicIcons[topic.id] ?? Ph.bookOpenFill,
                    ),
                    title: topic.title,
                    subtitle: topic.summary,
                    trailing: appState.readGuideTopics.contains(topic.id)
                        ? const _ReadMark()
                        : null,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GuideDetailScreen(topic: topic),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReadMark extends StatelessWidget {
  const _ReadMark();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Ph.check, size: 16, color: muted, semanticLabel: 'lido'),
        const SizedBox(width: 8),
        ExcludeSemantics(
          child: Icon(
            Ph.caretRight,
            size: 17,
            color: muted.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
