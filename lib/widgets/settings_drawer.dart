// ==========================================================================
// slidable API Settings & Quiz Parameters Configuration Drawer Widget
// ==========================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';
import '../models/mcq_model.dart';

class SettingsDrawer extends StatefulWidget {
  final Function() onSettingsChanged;
  final List<McqModel> savedQuestions;
  final Function(McqModel) onBookmarkToggled;
  final Function(List<McqModel>) onStartPracticeQuiz;
  final Function() onGoToSavedPractice;

  const SettingsDrawer({
    Key? key,
    required this.onSettingsChanged,
    required this.savedQuestions,
    required this.onBookmarkToggled,
    required this.onStartPracticeQuiz,
    required this.onGoToSavedPractice,
  }) : super(key: key);

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  // Config controllers
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  String _selectedModel = 'gemini-2.5-flash';
  double _questionCount = 5;
  String _selectedDifficulty = 'medium';
  String _selectedLanguage = 'english';

  @override
  void initState() {
    super.initState();
    _loadStoredSettings();
  }

  // Fetch preferences from device SharedPreferences
  Future<void> _loadStoredSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('aeroquiz_api_key') ?? '';
      _selectedModel = prefs.getString('aeroquiz_model') ?? 'gemini-2.5-flash';
      _questionCount = prefs.getDouble('aeroquiz_question_count') ?? 5.0;
      _selectedDifficulty = prefs.getString('aeroquiz_difficulty') ?? 'medium';
      _selectedLanguage = prefs.getString('aeroquiz_language') ?? 'english';
    });
  }

  // Set shared preferences
  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
    widget.onSettingsChanged(); // Notify root state
  }

  // Opens external link for obtaining free keys
  Future<void> _launchApiKeyUrl() async {
    final Uri url = Uri.parse('https://aistudio.google.com/app/apikey');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch URL.')),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AeroTheme.obsidianBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AeroTheme.borderSideColor, width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.sliders, color: AeroTheme.primaryIndigo, size: 20.0),
                  const SizedBox(width: 10.0),
                  Text(
                    'Quiz Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // API KEY Group
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Gemini API Key',
                            style: TextStyle(
                              color: AeroTheme.textSecondary,
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: _launchApiKeyUrl,
                            child: Row(
                              children: const [
                                Text(
                                  'Get Free Key',
                                  style: TextStyle(
                                    color: AeroTheme.primaryIndigo,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(LucideIcons.externalLink, color: AeroTheme.primaryIndigo, size: 10.0),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      TextField(
                        controller: _apiKeyController,
                        obscureText: _obscureKey,
                        onChanged: (val) => _saveSetting('aeroquiz_api_key', val.trim()),
                        style: const TextStyle(color: AeroTheme.textPrimary, fontSize: 14.0),
                        decoration: InputDecoration(
                          hintText: 'AIzaSy...',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureKey ? LucideIcons.eye : LucideIcons.eyeOff,
                              size: 16.0,
                              color: AeroTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureKey = !_obscureKey;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      const Text(
                        'Your API Key is securely cached on your device.',
                        style: TextStyle(color: AeroTheme.textMuted, fontSize: 11.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Model Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'AI Model',
                        style: TextStyle(
                          color: AeroTheme.textSecondary,
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          border: Border.all(color: AeroTheme.borderSideColor, width: 1.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedModel,
                            dropdownColor: AeroTheme.obsidianCardSolid,
                            icon: const Icon(LucideIcons.chevronDown, color: AeroTheme.textMuted, size: 16.0),
                            onChanged: (String? val) {
                              if (val != null) {
                                setState(() => _selectedModel = val);
                                _saveSetting('aeroquiz_model', val);
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'gemini-2.5-flash',
                                child: Text('Gemini 2.5 Flash (Fast & Free)', style: TextStyle(fontSize: 13.0)),
                              ),
                              DropdownMenuItem(
                                value: 'gemini-1.5-flash',
                                child: Text('Gemini 1.5 Flash (Standard)', style: TextStyle(fontSize: 13.0)),
                              ),
                              DropdownMenuItem(
                                value: 'gemini-2.5-pro',
                                child: Text('Gemini 2.5 Pro (High Quality)', style: TextStyle(fontSize: 13.0)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Divider(color: AeroTheme.borderSideColor),
                  const SizedBox(height: 16.0),

                  // Question Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Number of MCQs',
                            style: TextStyle(
                              color: AeroTheme.textSecondary,
                              fontSize: 13.0,
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
                              _questionCount.round().toString(),
                              style: const TextStyle(
                                color: AeroTheme.primaryIndigo,
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AeroTheme.primaryIndigo,
                          inactiveTrackColor: Colors.white.withOpacity(0.08),
                          thumbColor: AeroTheme.primaryIndigo,
                          overlayColor: AeroTheme.primaryIndigoGlow,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                        ),
                        child: Slider(
                          value: _questionCount,
                          min: 3,
                          max: 50,
                          divisions: 47,
                          onChanged: (double val) {
                            setState(() => _questionCount = val);
                            _saveSetting('aeroquiz_question_count', val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  // Difficulty Toggle Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Difficulty Level',
                        style: TextStyle(
                          color: AeroTheme.textSecondary,
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          border: Border.all(color: AeroTheme.borderSideColor, width: 1.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            _buildDifficultyBtn('easy', 'Easy'),
                            _buildDifficultyBtn('medium', 'Medium'),
                            _buildDifficultyBtn('hard', 'Hard'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Target Language Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Quiz Language',
                        style: TextStyle(
                          color: AeroTheme.textSecondary,
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          border: Border.all(color: AeroTheme.borderSideColor, width: 1.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            dropdownColor: AeroTheme.obsidianCardSolid,
                            icon: const Icon(LucideIcons.chevronDown, color: AeroTheme.textMuted, size: 16.0),
                            onChanged: (String? val) {
                              if (val != null) {
                                setState(() => _selectedLanguage = val);
                                _saveSetting('aeroquiz_language', val);
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: 'english', child: Text('English', style: TextStyle(fontSize: 13.0))),
                              DropdownMenuItem(value: 'spanish', child: Text('Spanish (Español)', style: TextStyle(fontSize: 13.0))),
                              DropdownMenuItem(value: 'french', child: Text('French (Français)', style: TextStyle(fontSize: 13.0))),
                              DropdownMenuItem(value: 'german', child: Text('German (Deutsch)', style: TextStyle(fontSize: 13.0))),
                              DropdownMenuItem(value: 'italian', child: Text('Italian (Italiano)', style: TextStyle(fontSize: 13.0))),
                              DropdownMenuItem(value: 'portuguese', child: Text('Portuguese (Português)', style: TextStyle(fontSize: 13.0))),
                              DropdownMenuItem(value: 'auto', child: Text('Auto (Detect from PDF)', style: TextStyle(fontSize: 13.0))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Divider(color: AeroTheme.borderSideColor),
                  const SizedBox(height: 16.0), // Saved Questions Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(LucideIcons.star, color: AeroTheme.alertAmber, size: 16.0),
                              SizedBox(width: 8.0),
                              Text(
                                'Saved Practice',
                                style: TextStyle(
                                  color: AeroTheme.textPrimary,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: AeroTheme.alertAmberBg,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              '${widget.savedQuestions.length}',
                              style: const TextStyle(
                                color: AeroTheme.alertAmber,
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // close drawer
                          widget.onGoToSavedPractice();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.white.withOpacity(0.02),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                          side: const BorderSide(color: AeroTheme.alertAmber, width: 1.0),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                        ),
                        icon: const Icon(LucideIcons.star, size: 14.0, color: AeroTheme.alertAmber),
                        label: const Text('Open Practice Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget builder for difficulty row
  Widget _buildDifficultyBtn(String val, String title) {
    final bool isActive = _selectedDifficulty == val;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedDifficulty = val);
          _saveSetting('aeroquiz_difficulty', val);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AeroTheme.primaryIndigo : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : AeroTheme.textSecondary,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
