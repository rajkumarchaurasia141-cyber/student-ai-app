import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const VidyaAgentApp());
}

class VidyaAgentApp extends StatelessWidget {
  const VidyaAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vidya Agent Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MultiPhotoSummaryScreen(),
    UniversalDoubtSolverScreen(),
    ChapterNotesScreen(),
    OnlineMcqTestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'विद्या एजेंट: AI स्टडी हब',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        elevation: 2,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.collections_bookmark), label: 'मल्टी-फ़ोटो समरी'),
          NavigationDestination(icon: Icon(Icons.document_scanner), label: 'सवाल हल (Math/Sci)'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'चैप्टर नोट्स'),
          NavigationDestination(icon: Icon(Icons.quiz), label: 'MCQ टेस्ट'),
        ],
      ),
    );
  }
}

// ---------------- 1. मल्टी-फ़ोटो समरी और नोट्स ----------------
class MultiPhotoSummaryScreen extends StatefulWidget {
  const MultiPhotoSummaryScreen({super.key});

  @override
  State<MultiPhotoSummaryScreen> createState() => _MultiPhotoSummaryScreenState();
}

class _MultiPhotoSummaryScreenState extends State<MultiPhotoSummaryScreen> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final String _apiKey = 'AQ.Ab8RN6IA1m4s9fIKAcMVV0t3GQ6Q' + 'VtARTT-cmmZ9ti1jurd4dw';
  
  String _summaryResult = '';
  bool _isLoading = false;

  Future<void> _captureFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null) {
      setState(() {
        _selectedImages.add(File(photo.path));
      });
    }
  }

  Future<void> _pickMultiFromGallery() async {
    final List<XFile> photos = await _picker.pickMultiImage(imageQuality: 80);
    if (photos.isNotEmpty) {
      setState(() {
        for (var p in photos) {
          _selectedImages.add(File(p.path));
        }
      });
    }
  }

  Future<void> _generateSummary() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया कम से कम 1 या अधिक फ़ोटो खींचें/चुनें!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _summaryResult = '';
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final List<Part> parts = [];

      for (var img in _selectedImages) {
        final bytes = await img.readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }

      const prompt = 'आप "विद्या एजेंट" के सबसे बेहतरीन शिक्षक हैं। '
          'छात्र ने किताब या नोट्स के कई पन्नों की तस्वीरें भेजी हैं। '
          'कृपया इन सभी तस्वीरों को ध्यान से पढ़ें और:\n'
          '1. इस पूरे टॉपिक का एक संपूर्ण, आसान और स्पष्ट सारांश (Summary) तैयार करें।\n'
          '2. परीक्षा में पूछे जाने वाले महत्वपूर्ण बिंदु (Bullet Points) निकालें।\n'
          '3. इसमें आए सभी महत्वपूर्ण सूत्र / परिभाषाएँ अलग से लिखें।\n'
          'यह सब शुद्ध और आसान हिंदी में प्रस्तुत करें।';

      parts.add(const TextPart(prompt));

      final response = await model.generateContent([Content.multi(parts)]);
      setState(() {
        _summaryResult = response.text ?? 'सारांश तैयार नहीं हो सका। कृपया दोबारा प्रयास करें।';
      });
    } catch (e) {
      setState(() {
        _summaryResult = 'त्रुटि (Error): $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'किताब या कॉपी के 5, 10 या 20 पन्नों की तस्वीरें खींचें और एक क्लिक में पूरा नोट्स व सारांश पाएँ।',
                    style: TextStyle(fontSize: 13, color: Colors.deepPurple.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _captureFromCamera,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('फोटो खींचें (+)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickMultiFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('गैलरी से चुनें'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedImages.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('कुल चुने गए पन्ने: ${_selectedImages.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedImages.clear()),
                  icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                  label: const Text('सभी हटाएं', style: TextStyle(color: Colors.red)),
                )
              ],
            ),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, idx) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.deepPurple, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImages[idx], fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImages.removeAt(idx)),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateSummary,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? 'एनालाइज़ हो रहा है...' : 'सभी पेजों का सारांश और नोट्स बनाएं'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('AI सभी पन्नों को पढ़ रहा है, कृपया प्रतीक्षा करें...'),
                ],
              ),
            )
          else if (_summaryResult.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                _summaryResult,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- 2. यूनिवर्सल सवाल हल (Math/Science) ----------------
class UniversalDoubtSolverScreen extends StatefulWidget {
  const UniversalDoubtSolverScreen({super.key});

  @override
  State<UniversalDoubtSolverScreen> createState() => _UniversalDoubtSolverScreenState();
}

class _UniversalDoubtSolverScreenState extends State<UniversalDoubtSolverScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _questionImage;
  final String _apiKey = 'AQ.Ab8RN6IA1m4s9fIKAcMVV0t3GQ6Q' + 'VtARTT-cmmZ9ti1jurd4dw';
  
  String _solution = '';
  bool _isSolving = false;

  Future<void> _pickSingleImage(ImageSource src) async {
    final photo = await _picker.pickImage(source: src, imageQuality: 85);
    if (photo != null) {
      setState(() {
        _questionImage = File(photo.path);
      });
    }
  }

  Future<void> _solveQuestion() async {
    final qText = _textCtrl.text.trim();
    if (qText.isEmpty && _questionImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया सवाल लिखें या उसकी फ़ोटो खींचें!')),
      );
      return;
    }

    setState(() {
      _isSolving = true;
      _solution = '';
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final List<Part> parts = [];

      if (_questionImage != null) {
        final bytes = await _questionImage!.readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }

      String prompt = 'आप "विद्या एजेंट" हैं - कक्षा 10वीं के विशेषज्ञ शिक्षक। '
          'छात्र द्वारा पूछे गए गणित (Maths), विज्ञान (Science) या किसी भी विषय के सवाल का '
          'विस्तृत, चरण-दर-चरण (Step-by-Step) और सटीक हल हिंदी माध्यम में दीजिए:\n$qText';

      parts.add(TextPart(prompt));

      final res = await model.generateContent([Content.multi(parts)]);
      setState(() {
        _solution = res.text ?? 'हल प्राप्त नहीं हो सका।';
      });
    } catch (e) {
      setState(() {
        _solution = 'Error: $e';
      });
    } finally {
      setState(() {
        _isSolving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'गणित या विज्ञान का सवाल यहाँ लिखें या नीचे से फ़ोटो खींचें...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSolving ? null : () => _pickSingleImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('सवाल की फ़ोटो लें'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSolving ? null : () => _pickSingleImage(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: const Text('गैलरी से चुनें'),
                ),
              ),
            ],
          ),
          if (_questionImage != null) ...[
            const SizedBox(height: 10),
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_questionImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 26),
                  onPressed: () => setState(() => _questionImage = null),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isSolving ? null : _solveQuestion,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('तुरंत हल पाएँ (Get Solution)'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 16),
          if (_isSolving)
            const Center(child: CircularProgressIndicator())
          else if (_solution.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                _solution,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- 3. सभी विषयों के चैप्टर नोट्स ----------------
class ChapterNotesScreen extends StatelessWidget {
  const ChapterNotesScreen({super.key});

  final List<Map<String, dynamic>> subjectData = const [
    {
      'subject': 'गणित (Mathematics)',
      'icon': Icons.calculate,
      'color': Colors.indigo,
      'chapters': [
        {
          'ch': 'अध्याय 1: वास्तविक संख्याएँ',
          'notes': '• यूक्लिड विभाजन प्रमेयिका: a = bq + r (0 ≤ r < b)\n• HCF(a, b) × LCM(a, b) = a × b\n• √2, √3, √5 अपरिमेय संख्याएँ हैं।'
        },
        {
          'ch': 'अध्याय 2: बहुपद',
          'notes': '• द्विघात बहुपद: ax² + bx + c = 0\n• α + β = -b/a, αβ = c/a'
        },
        {
          'ch': 'अध्याय 4: द्विघात समीकरण',
          'notes': '• मानक रूप: ax² + bx + c = 0\n• विविक्तकर D = b² - 4ac'
        },
        {
          'ch': 'अध्याय 8: त्रिकोणमिति का परिचय',
          'notes': '• sin²θ + cos²θ = 1\n• 1 + tan²θ = sec²θ\n• 1 + cot²θ = cosec²θ'
        },
      ]
    },
    {
      'subject': 'विज्ञान (Science)',
      'icon': Icons.biotech,
      'color': Colors.green,
      'chapters': [
        {
          'ch': 'भौतिकी: प्रकाश परावर्तन एवं अपवर्तन',
          'notes': '• दर्पण सूत्र: 1/f = 1/v + 1/u\n• लेंस सूत्र: 1/f = 1/v - 1/u\n• लेंस की क्षमता P = 1/f (डायोप्टर)'
        },
        {
          'ch': 'भौतिकी: विद्युत (Electricity)',
          'notes': '• ओम का नियम: V = IR\n• श्रेणीक्रम: R = R₁ + R₂ + R₃\n• समांतर क्रम: 1/R = 1/R₁ + 1/R₂ + 1/R₃'
        },
        {
          'ch': 'रसायन: अम्ल, क्षारक एवं लवण',
          'notes': '• अम्ल: नीले लिटमस को लाल करता है (pH < 7)\n• क्षारक: लाल लिटमस को नीला करता है (pH > 7)'
        },
      ]
    },
    {
      'subject': 'सामाजिक विज्ञान (Social Science)',
      'icon': Icons.public,
      'color': Colors.orange,
      'chapters': [
        {
          'ch': 'इतिहास: भारत में राष्ट्रवाद',
          'notes': '• जालियानवाला बाग हत्याकांड: 13 अप्रैल 1919\n• असहयोग आंदोलन: 1920-1922\n• सविनय अवज्ञा आंदोलन: 1930'
        },
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: subjectData.length,
      itemBuilder: (context, sIdx) {
        final sub = subjectData[sIdx];
        final chapters = sub['chapters'] as List;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: (sub['color'] as Color).withAlpha(40),
              child: Icon(sub['icon'], color: sub['color']),
            ),
            title: Text(sub['subject'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${chapters.length} महत्वपूर्ण अध्याय शामिल'),
            children: chapters.map<Widget>((ch) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.menu_book, color: Colors.deepPurple, size: 18),
                  title: Text(ch['ch'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SelectableText(
                        ch['notes'],
                        style: const TextStyle(fontSize: 14, height: 1.45),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ---------------- 4. ऑनलाइन MCQ टेस्ट सीरीज़ ----------------
class OnlineMcqTestScreen extends StatefulWidget {
  const OnlineMcqTestScreen({super.key});

  @override
  State<OnlineMcqTestScreen> createState() => _OnlineMcqTestScreenState();
}

class _OnlineMcqTestScreenState extends State<OnlineMcqTestScreen> {
  final List<Map<String, dynamic>> questions = [
    {
      'q': 'π (पाई) एक संख्या है:',
      'opts': ['परिमेय', 'अपरिमेय', 'पूर्णांक', 'प्राकृत'],
      'ans': 1
    },
    {
      'q': 'द्विघात बहुपद के शून्यकों की अधिकतम संख्या होती है:',
      'opts': ['1', '2', '3', 'अनंत'],
      'ans': 1
    },
    {
      'q': 'दाढ़ी बनाने में किस प्रकार के दर्पण का उपयोग किया जाता है?',
      'opts': ['समतल', 'उत
