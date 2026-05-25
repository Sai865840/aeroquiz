// ==========================================================================
// Professional, Graded Quiz Screen Workspace Widget
// ==========================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';
import '../models/mcq_model.dart';

class QuizView extends StatefulWidget {
  final List<McqModel> questions;
  final String fileName;
  final String difficulty;
  final Function(int finalScore, int secondsElapsed, List<int?> userAnswers) onQuizFinished;
  final Function() onQuitTriggered;

  const QuizView({
    Key? key,
    required this.questions,
    required this.fileName,
    required this.difficulty,
    required this.onQuizFinished,
    required this.onQuitTriggered,
  }) : super(key: key);

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  int _score = 0;
  late List<int?> _userAnswers;
  
  // Timer State
  Timer? _timer;
  int _secondsElapsed = 0;
  String _timerString = "00:00";

  @override
  void initState() {
    super.initState();
    _userAnswers = List<int?>.filled(widget.questions.length, null);
    _startTimer();
  }

  // Starts the quiz timer
  void _startTimer() {
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
          final int mins = _secondsElapsed ~/ 60;
          final int secs = _secondsElapsed % 60;
          _timerString = "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Shows pop-up warning dialog before exiting quiz
  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Quiz?'),
        content: const Text('Are you sure you want to quit this quiz? All current progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AeroTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onQuitTriggered();
            },
            child: const Text('Quit', style: TextStyle(color: AeroTheme.incorrectRose)),
          ),
        ],
      ),
    );
  }

  // Option selection logic
  void _handleOptionTap(int index) {
    if (_selectedOptionIndex != null) return; // locked

    setState(() {
      _selectedOptionIndex = index;
      _userAnswers[_currentIndex] = index;
      if (index == widget.questions[_currentIndex].correctAnswerIndex) {
        _score++;
      }
    });
  }

  // Navigation logic
  void _handleNextTap() {
    if (_selectedOptionIndex == null) return;

    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        // Load next question answer cache (usually null, or already answered if they went back)
        _selectedOptionIndex = _userAnswers[_currentIndex];
      });
    } else {
      _timer?.cancel();
      widget.onQuizFinished(_score, _secondsElapsed, _userAnswers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final McqModel currentQuestion = widget.questions[_currentIndex];
    final int totalQuestions = widget.questions.length;
    final double completionPercent = (_currentIndex) / totalQuestions;
    final bool isLastQuestion = _currentIndex == totalQuestions - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Meta Information Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Document Badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          border: Border.all(color: AeroTheme.borderSideColor),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.bookOpen, color: AeroTheme.textSecondary, size: 12.0),
                            const SizedBox(width: 4.0),
                            Flexible(
                              child: Text(
                                widget.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AeroTheme.textSecondary, fontSize: 11.0, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Difficulty Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        border: Border.all(color: AeroTheme.borderSideColor),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.barChart, color: AeroTheme.textSecondary, size: 12.0),
                          const SizedBox(width: 4.0),
                          Text(
                            widget.difficulty.toUpperCase(),
                            style: const TextStyle(color: AeroTheme.textSecondary, fontSize: 11.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Glowing Timer & Compact Quit Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AeroTheme.primaryIndigoBg,
                      border: Border.all(color: AeroTheme.primaryIndigo.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.clock, color: AeroTheme.primaryIndigo, size: 12.0),
                        const SizedBox(width: 6.0),
                        Text(
                          _timerString,
                          style: const TextStyle(
                            color: AeroTheme.primaryIndigo,
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  GestureDetector(
                    onTap: _showQuitDialog,
                    child: Container(
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        border: Border.all(color: AeroTheme.borderSideColor),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, color: AeroTheme.textSecondary, size: 13.0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Stepper Progress Indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentIndex + 1} of $totalQuestions',
                    style: const TextStyle(color: AeroTheme.textSecondary, fontSize: 12.0, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(completionPercent * 100).round()}% Completed',
                    style: const TextStyle(color: AeroTheme.textMuted, fontSize: 11.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: SizedBox(
                  height: 6.0,
                  child: LinearProgressIndicator(
                    value: completionPercent,
                    color: AeroTheme.primaryIndigo,
                    backgroundColor: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10.0),

        // Scrollable Quiz Card Container
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glass Question Card
                Container(
                  decoration: AeroTheme.glassCardDecoration(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQuestion.question,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),

                // Dynamic options list A, B, C, D
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentQuestion.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                  itemBuilder: (context, optIdx) {
                    return _buildOptionTile(currentQuestion, optIdx);
                  },
                ),
                const SizedBox(height: 20.0),

                // Animated Explanation Slider Pane
                if (_selectedOptionIndex != null) ...[
                  _buildExplanationPanel(currentQuestion),
                  const SizedBox(height: 20.0),
                ],
              ],
            ),
          ),
        ),
        
        // Persistent Bottom Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AeroTheme.borderSideColor, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              // Back Button on left (if idx > 0)
              if (_currentIndex > 0)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentIndex--;
                      _selectedOptionIndex = _userAnswers[_currentIndex];
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AeroTheme.textSecondary,
                    side: const BorderSide(color: AeroTheme.borderSideColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  ),
                  icon: const Icon(LucideIcons.chevronLeft, size: 14.0),
                  label: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                ),
              
              const Spacer(),
              
              // Next Button on right
              Container(
                height: 44.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22.0),
                  gradient: _selectedOptionIndex != null
                      ? const LinearGradient(colors: [AeroTheme.primaryIndigo, AeroTheme.violetAccent])
                      : null,
                  color: _selectedOptionIndex == null ? Colors.white.withOpacity(0.02) : null,
                  boxShadow: _selectedOptionIndex != null
                      ? [
                          BoxShadow(
                            color: AeroTheme.primaryIndigo.withOpacity(0.2),
                            blurRadius: 10.0,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: _selectedOptionIndex != null ? _handleNextTap : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    disabledForegroundColor: AeroTheme.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLastQuestion ? 'See Results' : 'Next Question',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _selectedOptionIndex != null ? Colors.white : AeroTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Icon(
                        isLastQuestion ? LucideIcons.award : LucideIcons.arrowRight,
                        size: 14.0,
                        color: _selectedOptionIndex != null ? Colors.white : AeroTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Graded option tile builder
  Widget _buildOptionTile(McqModel question, int optIdx) {
    final bool isAnswered = _selectedOptionIndex != null;
    final bool isSelected = _selectedOptionIndex == optIdx;
    final bool isCorrectAnswer = question.correctAnswerIndex == optIdx;

    Color tileBg = Colors.white.withOpacity(0.015);
    Color borderColor = AeroTheme.borderSideColor;
    Color optionBubbleBg = Colors.white.withOpacity(0.04);
    Color optionBubbleBorder = AeroTheme.borderSideColor;
    Color optionIdxColor = AeroTheme.textSecondary;
    Color optionTextColor = AeroTheme.textSecondary;
    Widget optionBubbleChild = Text(
      String.fromCharCode(65 + optIdx), // A, B, C, D
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
    );

    double opacity = 1.0;

    if (isAnswered) {
      if (isCorrectAnswer) {
        // Correct option styling
        tileBg = AeroTheme.correctEmeraldBg;
        borderColor = AeroTheme.correctEmerald;
        optionBubbleBg = AeroTheme.correctEmerald;
        optionBubbleBorder = AeroTheme.correctEmerald;
        optionIdxColor = Colors.white;
        optionTextColor = AeroTheme.correctEmerald;
        optionBubbleChild = const Icon(LucideIcons.check, color: Colors.white, size: 10.0);
      } else if (isSelected) {
        // Selected wrong option styling
        tileBg = AeroTheme.incorrectRoseBg;
        borderColor = AeroTheme.incorrectRose;
        optionBubbleBg = AeroTheme.incorrectRose;
        optionBubbleBorder = AeroTheme.incorrectRose;
        optionIdxColor = Colors.white;
        optionTextColor = AeroTheme.incorrectRose;
        optionBubbleChild = const Icon(LucideIcons.x, color: Colors.white, size: 10.0);
      } else {
        // Faded options
        opacity = 0.4;
      }
    } else {
      // Normal state hovers (touch animations)
      // Custom splash colors can be handled by standard InkWell
    }

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: () => _handleOptionTap(optIdx),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: tileBg,
            border: Border.all(color: borderColor, width: 1.2),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              // Dynamic correctness bubble circle
              Container(
                width: 24.0,
                height: 24.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: optionBubbleBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: optionBubbleBorder, width: 1.0),
                ),
                child: DefaultTextStyle(
                  style: TextStyle(color: optionIdxColor, fontWeight: FontWeight.bold),
                  child: optionBubbleChild,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  question.options[optIdx],
                  style: TextStyle(
                    color: isAnswered && isCorrectAnswer ? AeroTheme.textPrimary : optionTextColor,
                    fontSize: 14.0,
                    height: 1.3,
                    fontWeight: isAnswered && isCorrectAnswer ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sliding dynamic explanation card sheet
  Widget _buildExplanationPanel(McqModel question) {
    final bool isUserCorrect = _selectedOptionIndex == question.correctAnswerIndex;
    final Color accentColor = isUserCorrect ? AeroTheme.correctEmerald : AeroTheme.incorrectRose;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUserCorrect ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
            color: accentColor,
            size: 18.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUserCorrect ? 'Correct Explanation' : 'Explanation',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  question.explanation,
                  style: const TextStyle(
                    color: AeroTheme.textSecondary,
                    fontSize: 12.0,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
