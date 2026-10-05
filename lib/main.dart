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
  bool _isLoading = false;
  String? _videoUrl;
  VideoPlayerController? _videoController;

  Future<void> _generateVideo() async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/generate_video'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "prompt": _promptController.text,
          "resolution": _selectedResolution,
          "duration": 5
        }),
      );

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video Generated!")),
        );
      }
    } catch (e) {
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
    // Downloads Folder ကို ရယူခြင်း
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
      SnackBar(content: Text("Downloaded to: $savePath")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Download failed: $e")),
    );
  }
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
      body: Padding(
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
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildChip("Vela AI Video"),
                      const SizedBox(width: 8),
                      _buildChip(_selectedResolution, onTap: () {
                        setState(() {
                          _selectedResolution = _selectedResolution == "720p" ? "1080p" : "720p";
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildChip("9:16"),
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
                          ? const CircularProgressIndicator(color: Colors.white)
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
