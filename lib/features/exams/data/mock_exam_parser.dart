import '../domain/models.dart';

class MockExamParser {
  static final _questionStart = RegExp(r'^\s*([0-9০-৯]+)[\).]\s*(.+)$');
  static final _optionLine = RegExp(r'^\s*([A-Dক-ঘ])[\).:\-]?\s+(.+)$', caseSensitive: false);
  static final _answerLine = RegExp(
    r'^\s*(Answer|Ans|Correct Answer|উত্তর|সঠিক উত্তর)\s*[:\-]?\s*([A-Dক-ঘ])\s*$',
    caseSensitive: false,
  );
  static const _optionLabels = ['A', 'B', 'C', 'D', 'ক', 'খ', 'গ', 'ঘ'];
  static const _normalizedOptionMap = {
    'A': 0,
    'B': 1,
    'C': 2,
    'D': 3,
    'ক': 0,
    'খ': 1,
    'গ': 2,
    'ঘ': 3,
  };

  List<ParsedQuestionDraft> parse(String raw) {
    final drafts = <ParsedQuestionDraft>[];
    String? currentPrompt;
    final options = <String>[];
    int? correctIndex;

    void flush() {
      final prompt = currentPrompt;
      final answer = correctIndex;
      if (prompt != null && options.length == 4 && answer != null) {
        drafts.add(
          ParsedQuestionDraft(
            prompt: prompt.trim(),
            options: List<String>.from(options),
            correctIndex: answer,
          ),
        );
      }
    }

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      final questionMatch = _questionStart.firstMatch(line);
      if (questionMatch != null) {
        flush();
        currentPrompt = questionMatch.group(2)!.trim();
        options.clear();
        correctIndex = null;
        continue;
      }

      if (currentPrompt == null && options.isEmpty) {
        currentPrompt = line;
        continue;
      }

      final optionMatch = _optionLine.firstMatch(line);
      if (optionMatch != null) {
        final label = optionMatch.group(1)!.trim().toUpperCase();
        if (!_optionLabels.contains(label) && !_optionLabels.contains(optionMatch.group(1)!.trim())) {
          continue;
        }
        options.add(optionMatch.group(2)!.trim());
        continue;
      }

      final answerMatch = _answerLine.firstMatch(line);
      if (answerMatch != null) {
        final rawAnswer = answerMatch.group(2)!.trim();
        final answer = rawAnswer.toUpperCase();
        correctIndex = _normalizedOptionMap[answer] ?? _normalizedOptionMap[rawAnswer];
      }
    }

    flush();
    return drafts;
  }
}
