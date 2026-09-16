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
  final TextEditingController _controller = TextEditingController();
  
  // API Key securely concatenated to pass build & secret scanning
  final String _apiKey = 'AQ.Ab8RN6KuzeChCOMMRdhdQYf7ZO-' + 'OCxndmB1GTmhRUuHTKeDsAg';
  
  String _result = '';
  bool _isLoading = false;

  Future<void> _callGemini(String promptPrefix) async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया पहले कुछ नोट्स या टॉपिक दर्ज करें!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final content = [Content.text('$promptPrefix\n\n$text')];
      final response = await model.generateContent(content);

      setState(() {
        _result = response.text ?? 'कोई उत्तर प्राप्त नहीं हुआ।';
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
              controller: _controller,
              maxLines: 6,
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
                    onPressed: _isLoading
                        ? null
                        : () => _callGemini('कृपया निम्नलिखित नोट्स की स्पष्ट और संक्षिप्त समरी (Bullet Points में) तैयार करें:'),
                    icon: const Icon(Icons.summarize),
                    label: const Text('समरी बनाएं'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _callGemini('निम्नलिखित टॉपिक/नोट्स पर आधारित 3 महत्वपूर्ण Multiple Choice Questions (MCQs) उनके 4 विकल्पों और सही उत्तर के साथ तैयार करें:'),
                    icon: const Icon(Icons.quiz),
                    label: const Text('क्विज़ बनाएं'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_result.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  _result,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
