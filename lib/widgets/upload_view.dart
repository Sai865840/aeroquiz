// ==========================================================================
// Interactive File-Picker, Text Preview, and Trigger Upload View Widget
// ==========================================================================

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';
import '../services/pdf_service.dart';

class UploadView extends StatefulWidget {
  final String apiKey;
  final Function(List<int> bytes, String fileName) onFileParsed;
  final Function() onGenerateTriggered;
  final String pdfText;
  final String fileName;
  final Function() onResetFile;

  const UploadView({
    Key? key,
    required this.apiKey,
    required this.onFileParsed,
    required this.onGenerateTriggered,
    required this.pdfText,
    required this.fileName,
    required this.onResetFile,
  }) : super(key: key);

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  bool _isPicking = false;

  // Triggers PDF file picking via PdfService
  Future<void> _handleFileSelection() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final FilePickerResult? result = await PdfService.pickPdf();
      if (result != null && result.files.single.bytes != null) {
        widget.onFileParsed(
          result.files.single.bytes!.toList(),
          result.files.single.name,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: $e'),
          backgroundColor: AeroTheme.incorrectRose,
        ),
      );
    } finally {
      setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isReady = widget.apiKey.isNotEmpty && widget.pdfText.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome / Title Banner Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x1F6366F1), Color(0x0C8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0x266366F1), width: 1.0),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Convert PDFs to Smart Quizzes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18.0),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Upload study sheets, slides, or textbook chapters. AeroQuiz reads the document, extracts key facts, and creates customized assessments.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Dotted Upload Zone Card
          GestureDetector(
            onTap: widget.fileName.isEmpty ? _handleFileSelection : null,
            child: CustomPaint(
              painter: _DottedBorderPainter(
                color: widget.fileName.isEmpty ? AeroTheme.borderSideColor : AeroTheme.correctEmerald.withOpacity(0.3),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    if (widget.fileName.isEmpty) ...[
                      // Upload State
                      Container(
                        width: 64.0,
                        height: 64.0,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          border: Border.all(color: AeroTheme.borderSideColor, width: 1.0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.fileText, color: AeroTheme.textMuted, size: 28.0),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        _isPicking ? 'Opening File Explorer...' : 'Tap to browse PDF',
                        style: const TextStyle(
                          color: AeroTheme.textPrimary,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      const Text(
                        'Supports documents up to 20MB',
                        style: TextStyle(color: AeroTheme.textMuted, fontSize: 12.0),
                      ),
                    ] else ...[
                      // File Loaded State
                      Container(
                        width: 64.0,
                        height: 64.0,
                        decoration: const BoxDecoration(
                          color: AeroTheme.correctEmeraldBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.file, color: AeroTheme.correctEmerald, size: 28.0),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        widget.fileName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AeroTheme.correctEmerald,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      ElevatedButton.icon(
                        onPressed: widget.onResetFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AeroTheme.incorrectRose,
                          elevation: 0,
                          side: const BorderSide(color: AeroTheme.incorrectRoseGlow),
                        ),
                        icon: const Icon(LucideIcons.x, size: 14.0),
                        label: const Text('Remove File', style: TextStyle(fontSize: 12.0)),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          // Preview Card
          if (widget.pdfText.isNotEmpty) ...[
            Container(
              decoration: AeroTheme.glassCardDecoration(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(LucideIcons.eye, color: AeroTheme.textPrimary, size: 16.0),
                          SizedBox(width: 6.0),
                          Text(
                            'Extracted PDF Preview',
                            style: TextStyle(
                              color: AeroTheme.textPrimary,
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          '${widget.pdfText.length.toString()} chars',
                          style: const TextStyle(color: AeroTheme.textSecondary, fontSize: 11.0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    height: 120.0,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: AeroTheme.borderSideColor, width: 1.0),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.pdfText,
                        style: const TextStyle(
                          color: AeroTheme.textSecondary,
                          fontFamily: 'monospace',
                          fontSize: 11.0,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
          ],

          // Key Missing Warning
          if (widget.apiKey.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: AeroTheme.alertAmberBg,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AeroTheme.alertAmber.withOpacity(0.2)),
              ),
              child: Row(
                children: const [
                  Icon(LucideIcons.key, color: AeroTheme.alertAmber, size: 16.0),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      'API Key Required! Swipe from the left or tap Settings to enter your Gemini API Key.',
                      style: TextStyle(color: AeroTheme.alertAmber, fontSize: 12.0, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
          ],

          // Generate Action Button
          Container(
            height: 52.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: AeroTheme.primaryIndigo.withOpacity(0.3),
                        blurRadius: 16.0,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: isReady ? widget.onGenerateTriggered : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isReady ? null : Colors.white.withOpacity(0.02),
                disabledBackgroundColor: Colors.white.withOpacity(0.02),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                padding: EdgeInsets.zero, // lets gradient cover it
              ).copyWith(
                // Setup visual gradient for active states
                backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(MaterialState.disabled)) return Colors.white.withOpacity(0.02);
                  return Colors.transparent; // handled by parent Container gradient
                }),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: isReady
                      ? const LinearGradient(colors: [AeroTheme.primaryIndigo, AeroTheme.violetAccent])
                      : null,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Generate MCQ Quiz',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Icon(LucideIcons.sparkles, size: 16.0, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw a modern dotted border around dropzone
class _DottedBorderPainter extends CustomPainter {
  final Color color;

  _DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16.0),
    );

    final Path path = Path()..addRRect(rrect);

    // Draw dashed lines
    const double dashWidth = 8.0;
    const double dashSpace = 6.0;
    
    final Path metricsPath = Path();
    double distance = 0.0;
    
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        metricsPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    
    canvas.drawPath(metricsPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
