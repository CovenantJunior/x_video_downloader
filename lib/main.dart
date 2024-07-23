import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as html;

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
  String? _fileName;
  bool _isFetching = false;
  bool _isDownloading = false;
  double _progress = 0.0;

  Future<void> _fetchXVideos() async {
    setState(() {
      _downloadUrl = null;
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
      return;
    }

    try {
      var apiUrl = 'https://twitsave.com/info?url=$tweetUrl';
      var response = await http.get(Uri.parse(apiUrl));
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
        var fileName =
            '${fileNameElement.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')}.mp4';
        if (fileName.length > 50) {
          fileName = '${fileName.substring(0, 50)}.mp4';
        }
        setState(() {
          _downloadUrl = highestQualityUrl;
          _fileName = fileName;
          _isFetching = false;
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
      return;
    }

    try {
      setState(() {
        _isDownloading = true;
        _progress = 0.0;
      });

      var request = http.Request('GET', Uri.parse(_downloadUrl!));
      var response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/Download/$_fileName';
        final file = File(filePath);
        var bytes = <int>[];
        var totalBytes = response.contentLength ?? 0;
        var downloadedBytes = 0;

        response.stream.listen(
          (List<int> newBytes) {
            bytes.addAll(newBytes);
            downloadedBytes += newBytes.length;
            setState(() {
              _progress = totalBytes != 0 ? downloadedBytes / totalBytes : 0.0;
            });
          },
          onDone: () async {
            await file.writeAsBytes(bytes);
            Fluttertoast.showToast(
                msg: "Video downloaded successfully at $filePath",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.green,
                textColor: Colors.white,
                fontSize: 16.0);
            setState(() {
              _isDownloading = false;
              _progress = 0.0;
            });
          },
          onError: (e) {
            Fluttertoast.showToast(
                msg: "An error occurred while downloading the video",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                fontSize: 16.0);
            setState(() {
              _isDownloading = false;
              _progress = 0.0;
            });
          },
          cancelOnError: true,
        );
      } else {
        Fluttertoast.showToast(
            msg: "Failed to download video",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
        setState(() {
          _isDownloading = false;
        });
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
      setState(() {
        _isDownloading = false;
      });
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
                  ? const Text('Fetch 𝕏 Video')
                  : const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            if (_downloadUrl != null)
              ElevatedButton(
                onPressed: !_isDownloading ? _downloadVideo : null,
                child: !_isDownloading
                    ? const Text('Download 𝕏 Video')
                    : const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
              ),
            if (_isDownloading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: LinearProgressIndicator(value: _progress),
              ),
          ],
        ),
      ),
    );
  }
}
