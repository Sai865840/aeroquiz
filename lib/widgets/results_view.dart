// ==========================================================================
// custom Circular Accuracy Ring & Performance Stats Dashboard results view
// ==========================================================================

import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import '../theme.dart';
import '../models/mcq_model.dart';

class ResultsView extends StatefulWidget {
  final List<McqModel> questions;
  final int score;
  final int secondsElapsed;
  final String difficulty;
  final int pageCount;
  final String fileName;
  final Function() onRetakeQuiz;
  final Function() onNewPdf;
  final List<int?> userAnswers;
  final List<McqModel> savedQuestions;
  final Function(McqModel) onBookmarkToggled;

  const ResultsView({
    Key? key,
    required this.questions,
    required this.score,
    required this.secondsElapsed,
    required this.difficulty,
    required this.pageCount,
    required this.fileName,
    required this.onRetakeQuiz,
    required this.onNewPdf,
    required this.userAnswers,
    required this.savedQuestions,
    required this.onBookmarkToggled,
  }) : super(key: key);

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;
  late Animation<double> _sweepAnimation;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Initialize arc animation
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final double targetPercent = widget.questions.isNotEmpty 
        ? widget.score / widget.questions.length 
        : 0.0;

    _sweepAnimation = Tween<double>(begin: 0.0, end: targetPercent).animate(
      CurvedAnimation(parent: _sweepController, curve: Curves.easeOutCubic),
    );

    _sweepController.forward();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  // Helper to format seconds
  String _formatTime() {
    final int mins = widget.secondsElapsed ~/ 60;
    final int secs = widget.secondsElapsed % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  // Native Android file export
  Future<void> _exportQuizToJson() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final exportMap = {
        'metadata': {
          'fileName': widget.fileName,
          'difficulty': widget.difficulty,
          'totalPages': widget.pageCount,
          'score': widget.score,
          'totalQuestions': widget.questions.length,
          'accuracyPercent': widget.questions.isNotEmpty
              ? ((widget.score / widget.questions.length) * 100).round()
              : 0,
          'timeTakenSeconds': widget.secondsElapsed,
          'generatedAt': DateTime.now().toIso8601String(),
        },
        'quiz': widget.questions.map((q) => q.toJson()).toList(),
      };

      // Save locally to device Application Documents Directory
      final Directory? appDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      if (appDir == null) throw Exception('Storage directory not available.');

      final String sanitizedName = widget.fileName.replaceAll(RegExp(r'\.[^/.]+$'), '').replaceAll(RegExp(r'\s+'), '_');
      final String filePath = '${appDir.path}/AeroQuiz_${sanitizedName}_MCQs.json';
      
      final File file = File(filePath);
      await file.writeAsString(jsonEncode(exportMap));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported successfully to AeroQuiz_${sanitizedName}_MCQs.json in local files!'),
            backgroundColor: AeroTheme.correctEmerald,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: AeroTheme.incorrectRose,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalQ = widget.questions.length;
    final int accuracyPercent = totalQ > 0 ? ((widget.score / totalQ) * 100).round() : 0;

    // Dynamic headers based on accuracy
    String headline = "Good Effort!";
    String subheadline = "A passing grade. Review correct answers to reinforce learning.";
    
    if (accuracyPercent == 100) {
      headline = "Perfect Score!";
      subheadline = "Masterclass performance! You fully grasp all topics in this PDF.";
    } else if (accuracyPercent >= 80) {
      headline = "Outstanding Work!";
      subheadline = "Incredible comprehension levels. Excellent study habits shown!";
    } else if (accuracyPercent >= 50) {
      headline = "Good Effort!";
      subheadline = "A passing grade. Review details to strengthen your accuracy.";
    } else {
      headline = "Keep Practicing!";
      subheadline = "Make another attempt or read the text to strengthen your accuracy.";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Circular Score Dashboard
          Container(
            decoration: AeroTheme.glassCardDecoration(),
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              children: [
                SizedBox(
                  width: 160.0,
                  height: 160.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animate custom painter arc
                      AnimatedBuilder(
                        animation: _sweepAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _CircularProgressPainter(
                              progress: _sweepAnimation.value,
                              backgroundColor: Colors.white.withOpacity(0.02),
                              arcColor: AeroTheme.correctEmerald,
                            ),
                            size: const Size(160.0, 160.0),
                          );
                        },
                      ),
                      // Core Score Text Labels
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$accuracyPercent%',
                            style: const TextStyle(
                              fontSize: 32.0,
                              fontWeight: FontWeight.w800,
                              color: AeroTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '${widget.score} / $totalQ',
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: AeroTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20.0),
                ),
                const SizedBox(height: 6.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    subheadline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AeroTheme.textSecondary, fontSize: 13.0, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // Performance Breakdown Title
          const Text(
            'Performance Breakdown',
            style: TextStyle(
              color: AeroTheme.textPrimary,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12.0),

          // 2x2 Stats analytics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 2.2,
            children: [
              _buildStatTile(
                icon: LucideIcons.clock,
                label: 'Time Taken',
                val: _formatTime(),
                accentColor: AeroTheme.violetAccent,
                bgColor: AeroTheme.violetAccentBg,
              ),
              _buildStatTile(
                icon: LucideIcons.trendingUp,
                label: 'Accuracy',
                val: '$accuracyPercent%',
                accentColor: AeroTheme.correctEmerald,
                bgColor: AeroTheme.correctEmeraldBg,
              ),
              _buildStatTile(
                icon: LucideIcons.award,
                label: 'Difficulty',
                val: widget.difficulty.toUpperCase(),
                accentColor: AeroTheme.alertAmber,
                bgColor: AeroTheme.alertAmberBg,
              ),
              _buildStatTile(
                icon: LucideIcons.bookOpen,
                label: 'PDF Scope',
                val: '${widget.pageCount} Page${widget.pageCount != 1 ? 's' : ''}',
                accentColor: AeroTheme.infoBlue,
                bgColor: AeroTheme.infoBlueBg,
              ),
            ],
          ),
          const SizedBox(height: 32.0),

          // Navigation action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onRetakeQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AeroTheme.primaryIndigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  icon: const Icon(LucideIcons.rotateCcw, size: 16.0),
                  label: const Text('Retake Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onNewPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.03),
                    foregroundColor: AeroTheme.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: AeroTheme.borderSideColor),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  icon: const Icon(LucideIcons.checkSquare, size: 16.0),
                  label: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Export JSON Document
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportQuizToJson,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AeroTheme.textSecondary,
              elevation: 0,
              side: const BorderSide(color: AeroTheme.borderSideColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              padding: const EdgeInsets.symmetric(vertical: 14.0),
            ),
            icon: const Icon(LucideIcons.download, size: 16.0),
            label: Text(
              _isExporting ? 'Exporting...' : 'Export Quiz Questions (JSON)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
            ),
          ),
          
          const SizedBox(height: 28.0),
          const Divider(color: AeroTheme.borderSideColor),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Question Analysis',
                style: TextStyle(
                  color: AeroTheme.textPrimary,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: AeroTheme.primaryIndigoBg,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  '${widget.score} / ${widget.questions.length} Correct',
                  style: const TextStyle(
                    color: AeroTheme.primaryIndigo,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16.0),
            itemBuilder: (context, idx) {
              final q = widget.questions[idx];
              final int? userChoice = idx < widget.userAnswers.length ? widget.userAnswers[idx] : null;
              final bool isSaved = widget.savedQuestions.any((sq) => sq.question == q.question);
              return _buildAnalysisCard(q, userChoice, isSaved);
            },
          ),
        ],
      ),
    );
  }

  // Graded question breakdown review card
  Widget _buildAnalysisCard(McqModel question, int? userChoice, bool isSaved) {
    final bool isCorrect = userChoice == question.correctAnswerIndex;
    
    return Container(
      decoration: AeroTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: isCorrect ? AeroTheme.correctEmeraldBg : AeroTheme.incorrectRoseBg,
                  border: Border.all(
                    color: isCorrect ? AeroTheme.correctEmerald : AeroTheme.incorrectRose,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                      color: isCorrect ? AeroTheme.correctEmerald : AeroTheme.incorrectRose,
                      size: 13.0,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      isCorrect ? 'Correct' : 'Incorrect',
                      style: TextStyle(
                        color: isCorrect ? AeroTheme.correctEmerald : AeroTheme.incorrectRose,
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              IconButton(
                icon: Icon(
                  isSaved ? Icons.star : Icons.star_border,
                  color: isSaved ? AeroTheme.alertAmber : AeroTheme.textMuted,
                  size: 22.0,
                ),
                onPressed: () {
                  widget.onBookmarkToggled(question);
                  setState(() {}); // refresh stars
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          
          Text(
            question.question,
            style: const TextStyle(
              color: AeroTheme.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12.0),
          
          ...List.generate(question.options.length, (optIdx) {
            final bool isOptCorrect = optIdx == question.correctAnswerIndex;
            final bool isOptSelected = optIdx == userChoice;
            
            Color optBg = Colors.white.withOpacity(0.015);
            Color optBorder = AeroTheme.borderSideColor;
            Color charBg = Colors.white.withOpacity(0.04);
            Color textCol = AeroTheme.textSecondary;
            
            if (isOptCorrect) {
              optBg = AeroTheme.correctEmeraldBg;
              optBorder = AeroTheme.correctEmerald;
              charBg = AeroTheme.correctEmerald;
              textCol = AeroTheme.correctEmerald;
            } else if (isOptSelected) {
              optBg = AeroTheme.incorrectRoseBg;
              optBorder = AeroTheme.incorrectRose;
              charBg = AeroTheme.incorrectRose;
              textCol = AeroTheme.incorrectRose;
            } else if (userChoice != null) {
              optBg = Colors.white.withOpacity(0.005);
            }
            
            final String choiceChar = String.fromCharCode(65 + optIdx);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Opacity(
                opacity: (isOptCorrect || isOptSelected || userChoice == null) ? 1.0 : 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: optBg,
                    border: Border.all(color: optBorder, width: 1.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22.0,
                        height: 22.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: charBg,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          choiceChar,
                          style: TextStyle(
                            color: (isOptCorrect || isOptSelected) ? Colors.white : AeroTheme.textSecondary,
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          question.options[optIdx],
                          style: TextStyle(
                            color: isOptCorrect ? AeroTheme.textPrimary : textCol,
                            fontSize: 13.0,
                            fontWeight: isOptCorrect ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 10.0),
          
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: const Border(
                left: BorderSide(color: AeroTheme.primaryIndigo, width: 3.5),
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explanation:',
                  style: TextStyle(
                    color: AeroTheme.primaryIndigo,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  question.explanation,
                  style: const TextStyle(
                    color: AeroTheme.textSecondary,
                    fontSize: 12.0,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builder for performance stat block
  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String val,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        border: Border.all(color: AeroTheme.borderSideColor, width: 1.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          // Stat icon container box
          Container(
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: accentColor, size: 18.0),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AeroTheme.textMuted, fontSize: 10.0, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2.0),
                Text(
                  val,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AeroTheme.textPrimary, fontSize: 13.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Circular sweep arc painter
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color arcColor;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.arcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 8.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // Background track ring
    final Paint bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    // Active sweep accuracy arc
    final Paint arcPaint = Paint()
      ..color = arcColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double startAngle = -math.pi / 2; // top of circle
    final double sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
