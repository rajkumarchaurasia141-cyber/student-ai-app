import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const StudentAiApp());
}

class StudentAiApp extends StatelessWidget {
  const StudentAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student AI Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
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
  int _tabIndex = 0;

  final List<Widget> _tabs = const [
    MultiPhotoSummaryTab(),
    DoubtSolverTab(),
    DiagramMakerTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.amber),
            SizedBox(width: 8),
            Text('Student AI: Smart Study', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        elevation: 2,
      ),
      body: _tabs[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.collections_bookmark), label: 'मल्टी-फ़ोटो नोट्स'),
          NavigationDestination(icon: Icon(Icons.document_scanner), label: 'सवाल हल (Math/Sci)'),
          NavigationDestination(icon: Icon(Icons.draw), label: 'AI डायग्राम'),
        ],
      ),
    );
  }
}

// ---------------- 1. मल्टी-फ़ोटो समरी और नोट्स (10-20 पन्ने) ----------------
class MultiPhotoSummaryTab extends StatefulWidget {
  const MultiPhotoSummaryTab({super.key});

  @override
  State<MultiPhotoSummaryTab> createState() => _MultiPhotoSummaryTabState();
}

class _MultiPhotoSummaryTabState extends State<MultiPhotoSummaryTab> {
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  final String _apiKey = 'AQ.Ab8RN6IA1m4s9fIKAcMVV0t3GQ6Q' + 'VtARTT-cmmZ9ti1jurd4dw';
  String _result = '';
  bool _loading = false;

  Future<void> _addFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null) {
      setState(() => _images.add(File(photo.path)));
    }
  }

  Future<void> _addFromGallery() async {
    final List<XFile> photos = await _picker.pickMultiImage(imageQuality: 80);
    if (photos.isNotEmpty) {
      setState(() {
        for (var p in photos) {
          _images.add(File(p.path));
        }
      });
    }
  }

  Future<void> _summarizeAll() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया कम से कम 1 या अधिक पन्नों की फ़ोटो लें!')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final List<Part> parts = [];

      for (var img in _images) {
        final bytes = await img.readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }

      const prompt = 'आप "Student AI" के सर्वोत्तम शिक्षक हैं। '
          'छात्र ने किताब/कॉपी के कई पन्नों की तस्वीरें भेजी हैं। '
          'कृपया इन सभी तस्वीरों को ध्यान से पढ़कर आसान हिंदी में प्रस्तुत करें:\n'
          '1. पूरे पाठ का स्पष्ट और संपूर्ण सारांश (Summary)\n'
          '2. परीक्षा के लिए सबसे महत्वपूर्ण बिंदु (Key Notes / Bullet Points)\n'
          '3. सभी मुख्य परिभाषाएँ और सूत्र (Formulas)';

      parts.add(const TextPart(prompt));

      final response = await model.generateContent([Content.multi(parts)]);
      setState(() {
        _result = response.text ?? 'सारांश तैयार नहीं हो सका।';
      });
    } catch (e) {
      setState(() => _result = 'त्रुटि (Error): $e');
    } finally {
      setState(() => _loading = false);
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
              color: Colors.indigo.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.indigo),
                SizedBox(width: 8),
                Expanded(
                  child: Text('किताब या नोट्स के 5, 10 या 20 पन्नों की फ़ोटो खींचें और एक क्लिक में पूरा सारांश और नोट्स पाएँ।'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _addFromCamera,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('फोटो खींचे (+)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _addFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('गैलरी से चुनें'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_images.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('कुल पन्ने: ${_images.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => _images.clear()),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  label: const Text('सभी हटाएं', style: TextStyle(color: Colors.red)),
                )
              ],
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                itemBuilder: (context, i) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_images[i], fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _summarizeAll,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'एनालाइज़ हो रहा है...' : 'सभी पन्नों का सारांश और नोट्स बनाएं'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_result.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(_result, style: const TextStyle(fontSize: 15, height: 1.5)),
            ),
        ],
      ),
    );
  }
}

// ---------------- 2. यूनिवर्सल सवाल हल (Math, Science, All Subjects) ----------------
class DoubtSolverTab extends StatefulWidget {
  const DoubtSolverTab({super.key});

  @override
  State<DoubtSolverTab> createState() => _DoubtSolverTabState();
}

class _DoubtSolverTabState extends State<DoubtSolverTab> {
  final TextEditingController _ctrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _img;
  final String _apiKey = 'AQ.Ab8RN6IA1m4s9fIKAcMVV0t3GQ6Q' + 'VtARTT-cmmZ9ti1jurd4dw';
  String _ans = '';
  bool _busy = false;

  Future<void> _pickPhoto(ImageSource src) async {
    final p = await _picker.pickImage(source: src, imageQuality: 85);
    if (p != null) setState(() => _img = File(p.path));
  }

  Future<void> _solve() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty && _img == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('सवाल लिखें या फ़ोटो खींचें!')),
      );
      return;
    }

    setState(() {
      _busy = true;
      _ans = '';
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final List<Part> parts = [];

      if (_img != null) {
        final bytes = await _img!.readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }

      String prompt = 'आप "Student AI" के विशेषज्ञ शिक्षक हैं। '
          'छात्र के इस सवाल (गणित, विज्ञान या किसी भी विषय) का चरण-दर-चरण (Step-by-Step) '
          'और स्पष्ट हल आसान हिंदी में समझाइए:\n$txt';

      parts.add(TextPart(prompt));

      final res = await model.generateContent([Content.multi(parts)]);
      setState(() => _ans = res.text ?? 'हल प्राप्त नहीं हुआ।');
    } catch (e) {
      setState(() => _ans = 'Error: $e');
    } finally {
      setState(() => _busy = false);
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
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'गणित या विज्ञान का सवाल यहाँ लिखें या फ़ोटो लें...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('फ़ोटो खींचें'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('गैलरी'),
                ),
              ),
            ],
          ),
          if (_img != null) ...[
            const SizedBox(height: 10),
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_img!, height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => setState(() => _img = null),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _busy ? null : _solve,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('तुरंत हल पाएँ'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 16),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else if (_ans.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(_ans, style: const TextStyle(fontSize: 15, height: 1.5)),
            ),
        ],
      ),
    );
  }
}

// ---------------- 3. AI डायग्राम व चित्र मेकर (Diagram Maker) ----------------
class DiagramMakerTab extends StatefulWidget {
  const DiagramMakerTab({super.key});

  @override
  State<DiagramMakerTab> createState() => _DiagramMakerTabState();
}

class _DiagramMakerTabState extends State<DiagramMakerTab> {
  final TextEditingController _diagCtrl = TextEditingController();
  final String _apiKey = 'AQ.Ab8RN6IA1m4s9fIKAcMVV0t3GQ6Q' + 'VtARTT-cmmZ9ti1jurd4dw';
  String _diagResult = '';
  bool _isDrawing = false;

  Future<void> _generateDiagram() async {
    final topic = _diagCtrl.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया किसी डायग्राम का नाम लिखें (जैसे: मानव आँख)!')),
      );
      return;
    }

    setState(() {
      _isDrawing = true;
      _diagResult = '';
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final prompt = 'आप "Student AI" के डायग्राम विशेषज्ञ हैं। '
          'छात्र को "$topic" का नामांकित चित्र (Labelled Diagram) चाहिए। '
          'कृपया:\n'
          '1. इस चित्र की पूरी संरचना और सभी भागों (Parts) के नाम साफ़-साफ़ समझाएँ।\n'
          '2. कॉपी पर इस चित्र को कैसे आसान स्टेप्स (Step 1, Step 2, Step 3) में बनाना है, वह सिखाएँ।\n'
          '3. एक टेक्स्ट/ASCII या रेखाचित्र का प्रारूप दें ताकि छात्र देखकर तुरंत अपनी कॉपी पर बना सके।';

      final res = await model.generateContent([Content.text(prompt)]);
      setState(() => _diagResult = res.text ?? 'डायग्राम विवरण नहीं बन सका।');
    } catch (e) {
      setState(() => _diagResult = 'Error: $e');
    } finally {
      setState(() => _isDrawing = false);
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
            controller: _diagCtrl,
            decoration: InputDecoration(
              hintText: 'डायग्राम का नाम लिखें (उदा. मानव नेत्र, नेफ्रॉन, पाचन तंत्र)...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isDrawing ? null : _generateDiagram,
            icon: const Icon(Icons.draw),
            label: const Text('डायग्राम और संरचना बनाएँ'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_isDrawing)
            const Center(child: CircularProgressIndicator())
          else if (_diagResult.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(_diagResult, style: const TextStyle(fontSize: 15, height: 1.5)),
            ),
        ],
      ),
    );
  }
}
