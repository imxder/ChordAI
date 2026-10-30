import 'package:flutter/material.dart';

import '../models/guide_content.dart';
import 'guide_detail_screen.dart';

class GuideListScreen extends StatelessWidget {
  const GuideListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guia do iniciante')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: guideTopics.length,
        itemBuilder: (context, index) {
          final topic = guideTopics[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(topic.icon, color: Theme.of(context).colorScheme.primary),
              title: Text(topic.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GuideDetailScreen(topic: topic)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
