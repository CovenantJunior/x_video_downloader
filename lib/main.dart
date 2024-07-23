// import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as html;
// import 'package:oauth1/oauth1.dart' as oauth1;

/// ## Note
/// - This script relies on the external website [twitsave.com](https://twitsave.com) to retrieve the video URL for downloading.
///   It uses the API provided by twitsave.com to fetch the video details.
/// - Please ensure you have a stable internet connection and access to twitsave.com for the script to work properly.
/// - Me and this project are not affiliated with [twitsave.com](https://twitsave.com).
///   Please review and comply with the terms and conditions of [twitsave.com/terms](https://twitsave.com/terms)
///   when using their services through this script.

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
  // String? _errorMessage;
  String? _fileName;
  bool _isFetching = false;

  Future<void> _fetchXVideos() async {
    setState(() {
      _downloadUrl = null;
      // _errorMessage = null;
      _fileName = null;
      _isFetching = true;
    });

    String tweetUrl = _tweetUrlController.text;

    if (tweetUrl.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter a tweet URL",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
      /* setState(() {
        _errorMessage = 'Please enter a tweet URL.';
      }); */
      return;
    }

    try {
      var apiUrl = 'https://twitsave.com/info?url=$tweetUrl';
      var response = await get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        var document = html.parse(response.body);
        var downloadButton =
            document.querySelectorAll('div.origin-top-right')[0];
        var qualityButtons = downloadButton.querySelectorAll('a');
        var highestQualityUrl = qualityButtons[0].attributes['href'];
        print(highestQualityUrl);
        var fileNameElement = document
            .querySelectorAll('div.leading-tight')[0]
            .querySelectorAll('p.m-2')[0];
        var fileName = '${fileNameElement.text
                .trim()
                .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')}.mp4';

        setState(() {
          _downloadUrl = highestQualityUrl;
          _fileName = fileName;
        });
      } else {
        Fluttertoast.showToast(
          msg: "Failed to fetch tweet data",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
        setState(() {
          // _errorMessage = 'Failed to fetch tweet data.';
          _isFetching = false;
        });
      }
    } catch (e) {
      print(tweetUrl);
      print(e);
      Fluttertoast.showToast(
        msg: "An error occurred while fetching the video URL",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
      setState(() {
        // _errorMessage = 'An error occurred while fetching the video URL.';
        _isFetching = false;
      });
    }
  }

  Future<void> _downloadVideo() async {
    if (_downloadUrl == null) {
      Fluttertoast.showToast(
        msg: "No video to download",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
      /* setState(() {
        _errorMessage = 'No video to download.';
      }); */
      return;
    }

    try {
      var videoResponse = await http.get(Uri.parse(_downloadUrl!));

      if (videoResponse.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$_fileName.mp4';
        final file = File(filePath);
        await file.writeAsBytes(videoResponse.bodyBytes);

        /* setState(() {
          _errorMessage = 'Video downloaded successfully at $filePath';
        }); */

        Fluttertoast.showToast(
            msg: "Video downloaded successfully at $filePath",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        Fluttertoast.showToast(
          msg: "Failed to download video",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
        /* setState(() {
          _errorMessage = 'Failed to download video.';
        }); */
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "An error occurred while downloading the video",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
      /* setState(() {
        _errorMessage = 'An error occurred while downloading the video.';
      }); */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('𝕏 Video Downloader'),
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
              onPressed: !_isFetching ? _fetchXVideos : null,
              child: !_isFetching
                  ? const Text('Fetch 𝕏 Videos')
                  : const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2,)),
            ),
            const SizedBox(height: 10),
            if (_downloadUrl != null)
              ElevatedButton(
                onPressed: _downloadVideo,
                child: const Text('Download 𝕏 Video'),
              ),
            const SizedBox(height: 20),
            /* if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ), */
          ],
        ),
      ),
    );
  }
}
