import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';
import '../models/mcq_model.dart';

class SavedPracticeView extends StatefulWidget {
  final List<McqModel> savedQuestions;
  final Function(McqModel) onBookmarkToggled;
  final Function(List<McqModel>) onStartPracticeQuiz;
  final Function() onGoBack;

  const SavedPracticeView({
    Key? key,
    required this.savedQuestions,
    required this.onBookmarkToggled,
    required this.onStartPracticeQuiz,
    required this.onGoBack,
  }) : super(key: key);

  @override
  State<SavedPracticeView> createState() => _SavedPracticeViewState();
}

class _SavedPracticeViewState extends State<SavedPracticeView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter questions based on search query
    final List<McqModel> filteredQuestions = widget.savedQuestions.where((q) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return q.question.toLowerCase().contains(query) ||
          q.explanation.toLowerCase().contains(query) ||
          q.options.any((opt) => opt.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: AeroTheme.obsidianBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: widget.onGoBack,
        ),
        title: const Text('Saved Practice Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AeroTheme.alertAmberBg,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              '${filteredQuestions.length} Questions',
              style: const TextStyle(
                color: AeroTheme.alertAmber,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Action Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AeroTheme.textPrimary, fontSize: 14.5),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search saved questions, topics, or explanations...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18.0, color: AeroTheme.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16.0, color: AeroTheme.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: AeroTheme.borderSideColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: AeroTheme.primaryIndigo),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Start Practice Quiz Button
                ElevatedButton(
                  onPressed: filteredQuestions.isEmpty
                      ? null
                      : () => widget.onStartPracticeQuiz(filteredQuestions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.white.withOpacity(0.02),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.disabled)) return Colors.white.withOpacity(0.02);
                      return Colors.transparent;
                    }),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: filteredQuestions.isNotEmpty
                          ? const LinearGradient(
                              colors: [AeroTheme.primaryIndigo, AeroTheme.violetAccent, Color(0xFFD946EF)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.play, size: 16.0, color: Colors.white),
                          const SizedBox(width: 8.0),
                          Text(
                            'Start Practice Quiz (${filteredQuestions.length})',
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable List of Questions
          Expanded(
            child: widget.savedQuestions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.bookmarkMinus, size: 48.0, color: AeroTheme.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 16.0),
                          const Text(
                            'No bookmarked questions yet.',
                            style: TextStyle(color: AeroTheme.textSecondary, fontSize: 15.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Bookmark wrong questions on the results page to save them for practice here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AeroTheme.textMuted, fontSize: 12.0, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredQuestions.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching questions found.',
                          style: TextStyle(color: AeroTheme.textMuted, fontSize: 14.0),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
                        itemCount: filteredQuestions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                        itemBuilder: (context, idx) {
                          final q = filteredQuestions[idx];
                          return Container(
                            decoration: AeroTheme.glassCardDecoration(),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        q.question,
                                        style: const TextStyle(
                                          color: AeroTheme.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, color: AeroTheme.incorrectRose, size: 16.0),
                                      onPressed: () {
                                        widget.onBookmarkToggled(q);
                                        setState(() {}); // update search count
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12.0),
                                
                                // Options
                                ...List.generate(q.options.length, (optIdx) {
                                  final bool isCorrect = optIdx == q.correctAnswerIndex;
                                  final String choiceChar = String.fromCharCode(65 + optIdx);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                      decoration: BoxDecoration(
                                        color: isCorrect ? AeroTheme.correctEmeraldBg : Colors.black.withOpacity(0.1),
                                        border: Border.all(
                                          color: isCorrect ? AeroTheme.correctEmerald : AeroTheme.borderSideColor,
                                        ),
                                        borderRadius: BorderRadius.circular(6.0),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 18.0,
                                            height: 18.0,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isCorrect ? AeroTheme.correctEmerald : Colors.white.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(4.0),
                                            ),
                                            child: Text(
                                              choiceChar,
                                              style: TextStyle(
                                                color: isCorrect ? Colors.white : AeroTheme.textSecondary,
                                                fontSize: 10.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8.0),
                                          Expanded(
                                            child: Text(
                                              q.options[optIdx],
                                              style: TextStyle(
                                                color: isCorrect ? AeroTheme.textPrimary : AeroTheme.textSecondary,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 10.0),
                                
                                // Explanation
                                Container(
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    border: const Border(left: BorderSide(color: AeroTheme.primaryIndigo, width: 3.0)),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    q.explanation,
                                    style: const TextStyle(color: AeroTheme.textSecondary, fontSize: 11.5, height: 1.45),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
