import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const StudentAIApp());
}

class StudentAIApp extends StatelessWidget {
  const StudentAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  // अपनी Gemini API Key यहाँ डालें (aistudio.google.com से मुफ़्त मिलती है)
  final String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  Future<void> _processText(String promptType) async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      String prompt = '';
      if (promptType == 'summary') {
        prompt = 'Summarize the following educational content in 5 clear bullet points for quick exam revision in simple language:\n\n${_textController.text}';
      } else if (promptType == 'quiz') {
        prompt = 'Create 3 multiple-choice questions (MCQs) with answers and brief explanations based on this topic:\n\n${_textController.text}';
      }

      final response = await model.generateContent([Content.text(prompt)]);
      setState(() {
        _result = response.text ?? 'कोई उत्तर नहीं मिला।';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Exam Prep & Notes'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'यहाँ नोट्स या टॉपिक पेस्ट करें...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _processText('summary'),
                    icon: const Icon(Icons.summarize),
                    label: const Text('समरी बनाएं'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _processText('quiz'),
                    icon: const Icon(Icons.quiz),
                    label: const Text('क्विज़ बनाएं'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading) const CircularProgressIndicator(),
            if (_result.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    _result,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
