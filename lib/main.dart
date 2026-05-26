// ==========================================================================
// AeroQuiz Main App Root & State Coordinator Routing Engine
// ==========================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'theme.dart';
import 'models/mcq_model.dart';
import 'services/pdf_service.dart';
import 'services/gemini_service.dart';
import 'widgets/settings_drawer.dart';
import 'widgets/upload_view.dart';
import 'widgets/loading_view.dart';
import 'widgets/quiz_view.dart';
import 'widgets/results_view.dart';
import 'widgets/saved_practice_view.dart';

void main() {
  runApp(const AeroQuizApp());
}

class AeroQuizApp extends StatelessWidget {
  const AeroQuizApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroQuiz - AI MCQ Generator',
      debugShowCheckedModeBanner: false,
      theme: AeroTheme.darkTheme,
      home: const MainCoordinator(),
    );
  }
}

// Router State Machine Enums
enum AeroView { upload, loading, quiz, results, savedPractice }

class MainCoordinator extends StatefulWidget {
  const MainCoordinator({Key? key}) : super(key: key);

  @override
  State<MainCoordinator> createState() => _MainCoordinatorState();
}

class _MainCoordinatorState extends State<MainCoordinator> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Router View States
  AeroView _currentView = AeroView.upload;
  String _loadingTitle = '';
  String _loadingSubtitle = '';
  String _loadingStepKey = 'pdf'; // 'pdf', 'gemini', 'assemble'

  // Application Settings Cache
  String _apiKey = '';
  String _model = 'gemini-2.5-flash';
  int _questionCount = 5;
  String _difficulty = 'medium';
  String _language = 'english';

  // File Upload State Cache
  String _pdfText = '';
  String _fileName = '';
  int _pageCount = 0;

  // Active Quiz State Cache
  List<McqModel> _generatedQuestions = [];
  int _finalScore = 0;
  int _finalSecondsElapsed = 0;
  List<int?> _userAnswers = [];
  List<McqModel> _savedQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadApiSettings();
    _loadSavedQuestions();
  }

  // Load API parameters from LocalStorage
  Future<void> _loadApiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('aeroquiz_api_key') ?? '';
      _model = prefs.getString('aeroquiz_model') ?? 'gemini-2.5-flash';
      _questionCount = (prefs.getDouble('aeroquiz_question_count') ?? 5.0).round();
      _difficulty = prefs.getString('aeroquiz_difficulty') ?? 'medium';
      _language = prefs.getString('aeroquiz_language') ?? 'english';
    });
  }

  // Load Bookmarked Wrong Questions from LocalStorage
  Future<void> _loadSavedQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedJsonList = prefs.getStringList('aeroquiz_saved_mcqs') ?? [];
    setState(() {
      _savedQuestions = savedJsonList.map((e) => McqModel.fromJson(jsonDecode(e))).toList();
    });
  }

  // Toggle saving bookmark question
  Future<void> _toggleBookmark(McqModel question) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedJsonList = prefs.getStringList('aeroquiz_saved_mcqs') ?? [];
    
    final bool isSaved = _savedQuestions.any((q) => q.question == question.question);
    
    if (isSaved) {
      _savedQuestions.removeWhere((q) => q.question == question.question);
      savedJsonList.removeWhere((str) {
        final qMap = jsonDecode(str);
        return qMap['question'] == question.question;
      });
    } else {
      _savedQuestions.add(question);
      savedJsonList.add(jsonEncode(question.toJson()));
    }
    
    await prefs.setStringList('aeroquiz_saved_mcqs', savedJsonList);
    setState(() {});
  }

  // Triggered when drawer changes config
  void _onSettingsChanged() {
    _loadApiSettings();
  }

  // Parses PDF and extracts text in the background
  Future<void> _onFileParsed(List<int> bytes, String name) async {
    setState(() {
      _currentView = AeroView.loading;
      _loadingTitle = 'Extracting PDF Data...';
      _loadingSubtitle = 'Reading pages and parsing layout information.';
      _loadingStepKey = 'pdf';
    });

    final result = await PdfService.extractText(
      bytes: bytes,
      onProgress: (statusTitle, fraction) {
        setState(() {
          _loadingTitle = 'Reading PDF...';
          _loadingSubtitle = statusTitle;
        });
      },
    );

    if (result['success'] == true) {
      setState(() {
        _pdfText = result['text'];
        _pageCount = result['pages'];
        _fileName = name;
        _currentView = AeroView.upload;
      });
    } else {
      setState(() {
        _currentView = AeroView.upload;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to parse PDF: ${result['error']}'),
          backgroundColor: AeroTheme.incorrectRose,
        ),
      );
    }
  }

  // Direct REST generation query to Gemini
  Future<void> _onGenerateTriggered() async {
    setState(() {
      _currentView = AeroView.loading;
      _loadingTitle = 'Designing Your Quiz...';
      _loadingSubtitle = 'Synthesizing key topics and drafting challenging options via Gemini.';
      _loadingStepKey = 'gemini';
    });

    try {
      final questions = await GeminiService.generateMcqs(
        apiKey: _apiKey,
        model: _model,
        pdfText: _pdfText,
        questionCount: _questionCount,
        difficulty: _difficulty,
        language: _language,
      );

      setState(() {
        _loadingTitle = 'Assembling Dashboard...';
        _loadingSubtitle = 'Finalizing interactive controls and visual elements.';
        _loadingStepKey = 'assemble';
      });

      // Brief delay for beautiful transitions
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _generatedQuestions = questions;
        _currentView = AeroView.quiz;
      });
    } catch (e) {
      setState(() {
        _currentView = AeroView.upload;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate quiz: ${e.toString()}'),
          backgroundColor: AeroTheme.incorrectRose,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Quiz completed callbacks
  void _onQuizFinished(int score, int secondsElapsed, List<int?> userAnswers) {
    setState(() {
      _finalScore = score;
      _finalSecondsElapsed = secondsElapsed;
      _userAnswers = userAnswers;
      _currentView = AeroView.results;
    });
  }

  // Reset states
  void _onResetFile() {
    setState(() {
      _pdfText = '';
      _fileName = '';
      _pageCount = 0;
    });
  }

  void _onQuitQuiz() {
    setState(() {
      _currentView = AeroView.upload;
    });
  }

  void _onRetakeQuiz() {
    setState(() {
      _currentView = AeroView.quiz;
    });
  }

  void _onNewPdf() {
    setState(() {
      _pdfText = '';
      _fileName = '';
      _pageCount = 0;
      _currentView = AeroView.upload;
    });
  }

  void _showQuitConfirmation() {
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
              setState(() {
                _currentView = AeroView.upload;
              });
            },
            child: const Text('Quit', style: TextStyle(color: AeroTheme.incorrectRose)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget activeBody = const SizedBox();
    
    // Switch between views
    switch (_currentView) {
      case AeroView.upload:
        activeBody = UploadView(
          apiKey: _apiKey,
          pdfText: _pdfText,
          fileName: _fileName,
          onFileParsed: _onFileParsed,
          onGenerateTriggered: _onGenerateTriggered,
          onResetFile: _onResetFile,
        );
        break;
      case AeroView.loading:
        activeBody = LoadingView(
          title: _loadingTitle,
          subtitle: _loadingSubtitle,
          activeStepKey: _loadingStepKey,
        );
        break;
      case AeroView.quiz:
        activeBody = QuizView(
          questions: _generatedQuestions,
          fileName: _fileName,
          difficulty: _difficulty,
          onQuizFinished: _onQuizFinished,
          onQuitTriggered: _onQuitQuiz,
        );
        break;
      case AeroView.results:
        activeBody = ResultsView(
          questions: _generatedQuestions,
          score: _finalScore,
          secondsElapsed: _finalSecondsElapsed,
          difficulty: _difficulty,
          pageCount: _pageCount,
          fileName: _fileName,
          onRetakeQuiz: _onRetakeQuiz,
          onNewPdf: _onNewPdf,
          userAnswers: _userAnswers,
          savedQuestions: _savedQuestions,
          onBookmarkToggled: _toggleBookmark,
        );
        break;
      case AeroView.savedPractice:
        activeBody = SavedPracticeView(
          savedQuestions: _savedQuestions,
          onBookmarkToggled: _toggleBookmark,
          onStartPracticeQuiz: (questions) {
            setState(() {
              _generatedQuestions = questions.map((q) => q.shuffled()).toList();
              _fileName = "Saved Bookmarks Quiz";
              _difficulty = "custom";
              _currentView = AeroView.quiz;
            });
          },
          onGoBack: () {
            setState(() {
              _currentView = AeroView.upload;
            });
          },
        );
        break;
    }

    final bool isConfigured = _apiKey.isNotEmpty;

    return PopScope(
      canPop: _currentView == AeroView.upload,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentView == AeroView.results || _currentView == AeroView.savedPractice) {
          setState(() {
            _currentView = AeroView.upload;
          });
        } else if (_currentView == AeroView.quiz) {
          _showQuitConfirmation();
        }
      },
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: AeroTheme.obsidianBg,
      
      // Slidable Settings Drawer
      drawer: SettingsDrawer(
        onSettingsChanged: _onSettingsChanged,
        savedQuestions: _savedQuestions,
        onBookmarkToggled: _toggleBookmark,
        onStartPracticeQuiz: (questions) {
          setState(() {
            _generatedQuestions = questions.map((q) => q.shuffled()).toList();
            _fileName = "Saved Bookmarks Quiz";
            _difficulty = "custom";
            _currentView = AeroView.quiz;
          });
        },
        onGoToSavedPractice: () {
          setState(() {
            _currentView = AeroView.savedPractice;
          });
        },
      ),

      // Glassmorphic App Bar
      appBar: _currentView == AeroView.loading
          ? null // No appbar during loading
          : AppBar(
              title: const Text('AeroQuiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
              actions: [
                // Saved Practice shortcut button
                if (_currentView == AeroView.upload)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _currentView = AeroView.savedPractice;
                        });
                      },
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          border: Border.all(color: AeroTheme.borderSideColor),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: AeroTheme.alertAmber,
                              size: 14.0,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              'Practice (${_savedQuestions.length})',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AeroTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Config status dot badge
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        border: Border.all(color: AeroTheme.borderSideColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.key,
                            color: isConfigured ? AeroTheme.correctEmerald : AeroTheme.incorrectRose,
                            size: 14.0,
                          ),
                          const SizedBox(width: 6.0),
                          Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: BoxDecoration(
                              color: isConfigured ? AeroTheme.correctEmerald : AeroTheme.incorrectRose,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isConfigured ? AeroTheme.correctEmerald : AeroTheme.incorrectRose,
                                  blurRadius: 4.0,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

      // Page Content
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -150.0,
            left: -150.0,
            child: Container(
              width: 400.0,
              height: 400.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AeroTheme.primaryIndigo.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -200.0,
            right: -200.0,
            child: Container(
              width: 500.0,
              height: 500.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AeroTheme.correctEmerald.withOpacity(0.03),
              ),
            ),
          ),
          
          // Current Page Widget View
          SafeArea(child: activeBody),
        ],
      ),
    ),);
  }
}
