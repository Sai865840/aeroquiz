// ==========================================================================
// MCQ Question Data Model Definition
// ==========================================================================

class McqModel {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  McqModel({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  // Factory construct from JSON
  factory McqModel.fromJson(Map<String, dynamic> json) {
    // Graceful sanitization of choices array
    final rawOptions = json['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    } else {
      parsedOptions = ['A', 'B', 'C', 'D']; // safe fallback
    }

    return McqModel(
      question: json['question']?.toString() ?? 'Untitled Question',
      options: parsedOptions,
      correctAnswerIndex: int.tryParse(json['correctAnswerIndex']?.toString() ?? '0') ?? 0,
      explanation: json['explanation']?.toString() ?? 'No explanation provided.',
    );
  }

  // Serializer
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }
}
