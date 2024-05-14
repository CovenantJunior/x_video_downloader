import 'dart:convert';

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
  final TextEditingController _tweetUrlController = TextEditingController();
  String? _downloadUrl;
  String? _errorMessage;

  Future<void> _fetchXVideos() async {
    setState(() {
      _downloadUrl = null;
      _errorMessage = null;
    });

    String tweetUrl = _tweetUrlController.text;

    // Make request to Twitter API
    var response = await http.get(Uri.parse(
        'https://api.twitter.com/1.1/statuses/show.json?id=$tweetUrl'));

    print(response.body);

    if (response.statusCode == 200) {
      // Parse tweet data
      var tweetData = jsonDecode(response.body);

      // Extract video URL
      String? videoUrl = tweetData['extended_entities']['media'][0]
          ['video_info']['variants'][0]['url'];

      setState(() {
        _downloadUrl = videoUrl;
      });
    } else {
      setState(() {
        _errorMessage = 'Failed to fetch tweet data.';
      });
    }
  }

  Future<void> _downloadVideo() async {
    if (_downloadUrl == null) {
      setState(() {
        _errorMessage = 'No video to download.';
      });
      return;
    }

    try {
      // Make request to download video
      var videoResponse = await http.get(Uri.parse(_downloadUrl!));

      if (videoResponse.statusCode == 200) {
        // Save video file
        final file = File('x_video.mp4');
        await file.writeAsBytes(videoResponse.bodyBytes);
        setState(() {
          _errorMessage = 'Video downloaded successfully.';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to download video.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while downloading the video.';
      });
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
              controller: _tweetUrlController,
              decoration: const InputDecoration(
                labelText: 'Enter Tweet URL',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchXVideos,
              child: const Text('Fetch X Videos'),
            ),
            const SizedBox(height: 10),
            if (_downloadUrl != null)
              ElevatedButton(
                onPressed: _downloadVideo,
                child: const Text('Download X Video'),
              ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
