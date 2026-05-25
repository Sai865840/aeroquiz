// ==========================================================================
// Gemini API Structured Generation REST Client Service
// ==========================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mcq_model.dart';

class GeminiService {
  // Queries Gemini API using responseMimeType: "application/json" and strict responseSchema
  static Future<List<McqModel>> generateMcqs({
    required String apiKey,
    required String model,
    required String pdfText,
    required int questionCount,
    required String difficulty,
    required String language,
  }) async {
    final String prompt = '''
You are an expert educator. Your task is to generate exactly $questionCount multiple-choice questions (MCQs) based on the following extracted PDF document content.
The questions must be at a "${difficulty.toUpperCase()}" difficulty level.
The language of the questions, options, and explanations must be in "$language".

CRITICAL CONTENT DIRECTIVES:
- DO NOT generate math word problems or ask to calculate hypothetical postage prices based on package weights, dimensions, or volumes.
- Instead, ask factual, direct comprehension questions based exactly on the rules, rate tiers, terms, definitions, categories, and details explicitly stated in the PDF text (e.g. ask about specific postal rules, class categories, exceptions, or specific stated rates in the document).

CRITICAL BRIEF DESIGN DIRECTIVES:
- Keep the "question" direct, brief, and highly focused (strictly 1 to 2 short sentences maximum).
- Keep all 4 "options" extremely short, crisp, and concise (ideally a few words, a brief phrase, or at most a single short sentence). Strictly avoid long, wordy, or multi-sentence choices!
- Avoid redundant, repetitive, or verbose phrasing across options.
- The "explanation" must remain highly thorough, detailed, and educational, explaining why the correct choice is accurate and why the distractors are wrong.

Review the text carefully, identifying core concepts, key definitions, analytical reasoning, and factual details to create high-quality, non-trivial questions.
For each MCQ, you must provide:
1. "question": The clear, highly concise question prompt.
2. "options": Exactly 4 short, crisp choices, where only one option is absolutely correct.
3. "correctAnswerIndex": The index of the correct answer (0 for first option, 1 for second, 2 for third, 3 for fourth).
4. "explanation": A thorough, educational explanation.

Extracted PDF Document Content:
---
$pdfText
---''';

    // Build the request body with schema enforcement
    final Map<String, dynamic> body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'mcqs': {
              'type': 'ARRAY',
              'items': {
                'type': 'OBJECT',
                'properties': {
                  'question': {'type': 'STRING'},
                  'options': {
                    'type': 'ARRAY',
                    'items': {'type': 'STRING'},
                    'minItems': 4,
                    'maxItems': 4,
                  },
                  'correctAnswerIndex': {'type': 'INTEGER'},
                  'explanation': {'type': 'STRING'},
                },
                'required': ['question', 'options', 'correctAnswerIndex', 'explanation'],
              }
            }
          },
          'required': ['mcqs'],
        }
      }
    };

    final String url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        Map<String, dynamic> errorData = {};
        try {
          errorData = jsonDecode(response.body);
        } catch (_) {}
        
        final String errorMsg = errorData['error']?['message'] ?? response.reasonPhrase ?? 'Unknown Server Error';
        throw Exception('Gemini API Error (${response.statusCode}): $errorMsg');
      }

      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      final String? textResponse = responseJson['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (textResponse == null || textResponse.trim().isEmpty) {
        throw Exception('Received an empty response from the AI model.');
      }

      // Parse inner structured JSON string
      final Map<String, dynamic> resultJson = jsonDecode(textResponse);
      final List<dynamic>? mcqList = resultJson['mcqs'];

      if (mcqList == null || mcqList.isEmpty) {
        throw Exception('Failed to find a valid MCQs array in the AI output.');
      }

      return mcqList.map((q) => McqModel.fromJson(q)).toList();

    } catch (e) {
      rethrow;
    }
  }
}
