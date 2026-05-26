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

  /// Returns a new [McqModel] with options list shuffled and the
  /// [correctAnswerIndex] updated to point to the new correct option position.
  McqModel shuffled() {
    if (options.isEmpty) return this;

    // Create an indexed list of the original options to track their positions robustly
    final List<MapEntry<int, String>> indexedOptions = options.asMap().entries.toList();
    
    // Shuffle the indexed options
    indexedOptions.shuffle();

    // Extract the shuffled option texts
    final List<String> shuffledOptions = indexedOptions.map((e) => e.value).toList();

    // Locate where the original correct answer ended up in the shuffled list
    final int newCorrectAnswerIndex = indexedOptions.indexWhere((e) => e.key == correctAnswerIndex);

    return McqModel(
      question: question,
      options: shuffledOptions,
      correctAnswerIndex: newCorrectAnswerIndex != -1 ? newCorrectAnswerIndex : correctAnswerIndex,
      explanation: explanation,
    );
  }

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
