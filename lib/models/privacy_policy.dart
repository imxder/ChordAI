class PrivacySection {
  final String? title;
  final List<String> paragraphs;
  final List<String> items;

  const PrivacySection({
    this.title,
    this.paragraphs = const [],
    this.items = const [],
  });
}

class PrivacyPolicy {
  final String title;
  final List<PrivacySection> sections;

  const PrivacyPolicy({required this.title, required this.sections});
}

PrivacyPolicy parsePrivacyPolicy(String markdown) {
  var title = '';
  final sections = <PrivacySection>[];
  String? sectionTitle;
  var paragraphs = <String>[];
  var items = <String>[];
  var paragraph = <String>[];

  void closeParagraph() {
    if (paragraph.isNotEmpty) {
      paragraphs.add(paragraph.join(' '));
      paragraph = [];
    }
  }

  void closeSection() {
    closeParagraph();
    if (sectionTitle != null || paragraphs.isNotEmpty || items.isNotEmpty) {
      sections.add(
        PrivacySection(
          title: sectionTitle,
          paragraphs: paragraphs,
          items: items,
        ),
      );
    }
    sectionTitle = null;
    paragraphs = [];
    items = [];
  }

  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('## ')) {
      closeSection();
      sectionTitle = line.substring(3).trim();
    } else if (line.startsWith('# ')) {
      title = line.substring(2).trim();
    } else if (line.startsWith('- ')) {
      closeParagraph();
      items.add(line.substring(2).trim());
    } else if (line.isEmpty) {
      closeParagraph();
    } else {
      paragraph.add(line);
    }
  }
  closeSection();
  return PrivacyPolicy(title: title, sections: sections);
}
