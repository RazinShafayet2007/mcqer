import '../domain/models.dart';

class MockExamParser {
  static final _questionStart = RegExp(r'^\s*\d+[\).]\s*(.+)$');
  static final _optionLine = RegExp(r'^\s*([A-D])[\).:]\s*(.+)$', caseSensitive: false);
  static final _answerLine = RegExp(r'^\s*(Answer|Ans|Correct Answer)\s*:\s*([A-D])\s*$', caseSensitive: false);

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
        currentPrompt = questionMatch.group(1)!.trim();
        options.clear();
        correctIndex = null;
        continue;
      }

      final optionMatch = _optionLine.firstMatch(line);
      if (optionMatch != null) {
        options.add(optionMatch.group(2)!.trim());
        continue;
      }

      final answerMatch = _answerLine.firstMatch(line);
      if (answerMatch != null) {
        final answer = answerMatch.group(2)!.toUpperCase();
        correctIndex = 'ABCD'.indexOf(answer);
      }
    }

    flush();
    return drafts;
  }
}
