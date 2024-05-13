import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoDownloader(),
    );
  }
}

class VideoDownloader extends StatefulWidget {
  const VideoDownloader({super.key});

  @override
  State<VideoDownloader> createState() => _VideoDownloaderState();
}

class _VideoDownloaderState extends State<VideoDownloader> {
  final TextEditingController _urlController = TextEditingController();
  String? _filePath;

  Future<void> _downloadVideo(url) async {
    // Fetch the tweet
    var response = await http.get(Uri.parse(_urlController.text));

    try {
      Fluttertoast.showToast(
        msg: "Downloading",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Parsing video...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
        );
        // Find video URL in the response
        // Parse the HTML to get the video URL

        // Placeholder code: You will need to parse the HTML to extract the video URL.
        // Depending on the complexity of the video URL extraction, you may need a package to parse the HTML.

        // Assuming you get the video URL in `_videoUrl`
        // Download the video
        Directory tempDir = await getTemporaryDirectory();
        String filePath = '${tempDir.path}/video.mp4';

        http.Response videoResponse = await http.get(Uri.parse(url!));

        if (videoResponse.statusCode == 200) {
          File file = File(filePath);
          await file.writeAsBytes(videoResponse.bodyBytes);
          setState(() {
            _filePath = filePath;
          });
        }
      }
    } catch (e) {
      print(e);
    }
    
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('X Video Downloader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Enter Tweet URL',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _downloadVideo(_urlController.text);
              },
              child: const Text('Download Video'),
            ),
            const SizedBox(height: 20),
            if (_filePath != null)
              Column(
                children: [
                  Text('Video downloaded at: $_filePath'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
