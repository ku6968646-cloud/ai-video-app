import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Video Generator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.orange,
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
  final TextEditingController _promptController = TextEditingController();
  String _selectedResolution = "720p";
  String _selectedAnimation = "zoom_in";
  int _selectedDuration = 5;
  bool _isLoading = false;
  String? _videoUrl;
  VideoPlayerController? _videoController;

  // 🌟 Animation အမျိုးအစားများ
  final Map<String, String> _animations = {
    "zoom_in": "🔍 Zoom In",
    "zoom_out": "🔎 Zoom Out",
    "pan_right": "➡️ Pan Right",
    "pan_left": "⬅️ Pan Left",
    "rotate": "🔄 Rotate",
  };

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.orange),
                const SizedBox(height: 20),
                const Text(
                  "Generating Video...",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  "AI ပုံဖန်တီးပြီး Video ပြောင်းနေပါတယ်။\n၃၀ စက္ကန့်ကနေ ၁ မိနစ်အထိ ကြာနိုင်ပါတယ်။",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateVideo() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prompt ရိုက်ထည့်ပါ")),
      );
      return;
    }

    setState(() { _isLoading = true; });
    _showLoadingDialog();

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/generate_video'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "prompt": _promptController.text,
          "resolution": _selectedResolution,
          "animation": _selectedAnimation,
          "duration": _selectedDuration,
        }),
      ).timeout(const Duration(minutes: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String videoUrl = data['video_url'];
        
        if (_videoController != null) {
          _videoController!.dispose();
        }
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await _videoController!.initialize();
        _videoController!.play();
        
        setState(() { _videoUrl = videoUrl; });
        
        if (mounted) Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video Generated! 🎉")),
        );
      } else {
        if (mounted) Navigator.of(context).pop();
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${error['message'] ?? 'Unknown'}")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _downloadVideo() async {
    if (_videoUrl == null) return;

    try {
      Directory? dir = await getDownloadsDirectory();
      if (dir == null) {
        dir = await getExternalStorageDirectory();
      }
      
      String savePath = '${dir!.path}/ai_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Downloading...")),
      );

      await Dio().download(_videoUrl!, savePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved to: $savePath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  void _showAnimationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: _animations.entries.map((entry) {
            return ListTile(
              title: Text(entry.value, style: const TextStyle(color: Colors.white)),
              trailing: _selectedAnimation == entry.key
                  ? const Icon(Icons.check, color: Colors.orange)
                  : null,
              onTap: () {
                setState(() { _selectedAnimation = entry.key; });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showDurationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [3, 5, 8, 10, 15].map((sec) {
            return ListTile(
              title: Text("$sec seconds", style: const TextStyle(color: Colors.white)),
              trailing: _selectedDuration == sec
                  ? const Icon(Icons.check, color: Colors.orange)
                  : null,
              onTap: () {
                setState(() { _selectedDuration = sec; });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("AI Video Generator", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.diamond, color: Colors.orange),
            label: const Text("Upgrade", style: TextStyle(color: Colors.orange)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTab("Video", true)),
                  Expanded(child: _buildTab("Image", false)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.videocam, size: 80, color: Colors.orange),
            const SizedBox(height: 10),
            const Text(
              "Create Stunning Videos with AI",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Transform your ideas into captivating videos.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // 🌟 Animation နဲ့ Duration ရွေးချယ်မှု
                  Row(
                    children: [
                      _buildChip(
                        _animations[_selectedAnimation] ?? "Zoom In",
                        onTap: _showAnimationPicker,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        "${_selectedDuration}s",
                        onTap: _showDurationPicker,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(_selectedResolution, onTap: () {
                        setState(() {
                          _selectedResolution = _selectedResolution == "720p" ? "1080p" : "720p";
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _promptController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Describe the content you want to create",
                      border: InputBorder.none,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.image, color: Colors.grey),
                      const Text("0/5000", style: TextStyle(color: Colors.grey)),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _generateVideo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Create | AD", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_videoController != null && _videoController!.value.isInitialized)
              Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _downloadVideo,
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text("Download Video", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              )
            else if (_videoUrl != null)
              Container(
                height: 200,
                color: Colors.grey[800],
                child: const Center(child: Text("Video Loading...")),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.grey[800] : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.orange : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ),
    );
  }
}
