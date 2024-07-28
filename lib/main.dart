import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.manageExternalStorage,
      Permission.storage,
    ].request();
    
    if (statuses.containsValue(PermissionStatus.denied)) {
      Fluttertoast.showToast(
          msg: "App may malfunction without granted permissions",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1);
    }
  }

  final TextEditingController _tweetUrlController = TextEditingController();
  String? _highestQualityUrl;
  String? _lowestQualityUrl;
  String? _highestQualityText;
  String? _lowestQualityText;
  String? _fileName;
  bool _isFetching = false;
  bool _isDownloading = false;
  String _selectedResolution = 'Tap to Choose Resolution';

  String getDeviceInternalPath(dir) {
    print(dir);
    List<String> comp = dir.path.split('/');
    List<String> trunc = comp.sublist(1, 4);
    return trunc.join('/');
  }

  Future<void> _fetchXVideos() async {
    setState(() {
      _highestQualityUrl = null;
      _lowestQualityUrl = null;
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
      setState(() {
        _isFetching = false;
      });
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
        var lowestQualityUrl = qualityButtons[1].attributes['href'];
        var highestQualityText = qualityButtons[0]
            .querySelector('.truncate')
            ?.text
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        var lowestQualityText = qualityButtons[1]
            .querySelector('.truncate')
            ?.text
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        setState(() {
          _highestQualityText = highestQualityText;
          _lowestQualityText = lowestQualityText;
        });
        var fileNameElement = document
            .querySelectorAll('div.leading-tight')[0]
            .querySelectorAll('p.m-2')[0];
        var fileName =
            '${fileNameElement.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}.mp4';
        if (fileName.length > 50) {
          fileName = '${fileName.substring(0, 50)}.mp4';
        }
        setState(() {
          _highestQualityUrl = highestQualityUrl;
          _lowestQualityUrl = lowestQualityUrl;
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
    String? downloadUrl;
    if (_selectedResolution.contains('Highest')) {
      downloadUrl = _highestQualityUrl;
    } else if (_selectedResolution.contains('Lowest')) {
      downloadUrl = _lowestQualityUrl;
    }

    if (downloadUrl == null) {
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
      });

      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        final directory = await getDownloadsDirectory();
        final storage = getDeviceInternalPath(directory);
        final dir = Directory('/$storage/X Videos');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        var filePath = '${dir.path}/$_fileName';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        Fluttertoast.showToast(
          msg: "Video downloaded successfully at $filePath",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        setState(() {
          _isDownloading = false;
        });
      } else {
        Fluttertoast.showToast(
          msg: "Failed to download video",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        setState(() {
          _isDownloading = false;
        });
      }

    } catch(e){
      print(e);
      Fluttertoast.showToast(
        msg: "An error occurred while downloading the video",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          '𝕏 Video Downloader',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tweetUrlController,
              style: const TextStyle(
                color: Color.fromARGB(255, 156, 184, 198)
              ),
              decoration: const InputDecoration(
                labelText: 'Enter Tweet URL',
                labelStyle: TextStyle(
                  color: Color.fromARGB(255, 156, 184, 198)
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: !_isFetching ? _fetchXVideos : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                side: const BorderSide(width: 1, color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: !_isFetching
                  ? const Text(
                    'Fetch 𝕏 Video',
                    style: TextStyle(
                      color: Colors.white
                    ),
                  )
                  : const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            if (_highestQualityUrl != null && _lowestQualityUrl != null)
              DropdownButton<String>(
                dropdownColor: Colors.black,
                value: _selectedResolution,
                icon: Container(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedResolution = newValue!;
                    _isDownloading = false;
                  });
                },
                items: <String>[
                  'Tap to Choose Resolution',
                  'Highest $_highestQualityText',
                  'Lowest $_lowestQualityText'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 10),
            if (_highestQualityUrl != null || _lowestQualityUrl != null)
              ElevatedButton(
                onPressed: !_isDownloading ? _downloadVideo : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  side: const BorderSide(width: 1, color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: !_isDownloading
                    ? const Text(
                      'Download 𝕏 Video',
                      style: TextStyle(
                        color: Colors.white
                      ),
                    )
                    : const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
              ),
            if (_isDownloading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      'Downloading...',
                      style: TextStyle(
                        color: Colors.white
                      ),
                    ),
                    SizedBox(height: 20),
                    LinearProgressIndicator(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
