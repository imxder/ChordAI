import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/privacy_policy.dart';
import '../widgets/page_parts.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late final Future<PrivacyPolicy> _policy = rootBundle
      .loadString('PRIVACY.md')
      .then(parsePrivacyPolicy);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<PrivacyPolicy>(
      future: _policy,
      builder: (context, snapshot) {
        final policy = snapshot.data;
        return IosPage(
          title: 'Privacidade',
          children: [
            if (policy != null)
              for (final section in policy.sections)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (section.title != null) ...[
                        const SizedBox(height: 8),
                        Semantics(
                          header: true,
                          child: Text(
                            section.title!,
                            style: textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      for (final paragraph in section.paragraphs) ...[
                        Text(paragraph, style: textTheme.bodyLarge),
                        const SizedBox(height: 12),
                      ],
                      for (final item in section.items) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ', style: textTheme.bodyLarge),
                            Expanded(
                              child: Text(item, style: textTheme.bodyLarge),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }
}
