import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:ai_imagez/theme_provider.dart';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'appsflyer_service.dart';
import 'main_screen.dart'; 
import 'package:http_parser/http_parser.dart';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

// Define the API endpoints
const String apiUrl1 = 'https://api.stability.ai/v2alpha/generation/image-to-video';
const String apiUrl2 = 'https://api.stability.ai/v2alpha/generation/image-to-video/result/';


class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  _ToolsPageState createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  File? _selectedImage;
  bool _is768x768 = false;
  bool _is576x1024 = false;
  bool _is1024x576 = false;
  // Define the state variables
  String _loadingMessage = 'Please select an image.';
  String? _generationId;
  RestartableTimer? _timer;
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  final seedController = TextEditingController(text: '0');
  double cfgScaleValue = 2.5;
  double motionBucketIdValue = 40;
  http.MultipartRequest? request; // Define request at a higher scope
  bool _isResizing = false;
  CustomerInfo? customerInfo; 
  InterstitialAd? _interstitialAd;

  void _reset() {
    setState(() {
      _controller = null;
      _selectedImage = null;
      _is768x768 = false;
      _is576x1024 = false;
      _is1024x576 = false;
    });
  }

  Future<void> initAds2() async {
    CustomerInfo info = await Purchases.getCustomerInfo(); // Fetch the customerInfo
    setState(() {
      customerInfo = info; // Update customerInfo inside setState
    });
    print('ADLOG2: Customer info fetched');
    print('ADLOG2: All entitlements: ${customerInfo!.entitlements.all}'); // Print all entitlements
    print('ADLOG2: remove_ads entitlement exists: ${customerInfo!.entitlements.all.containsKey('remove_ads')}');
    if (customerInfo!.entitlements.all.containsKey('remove_ads')) {
      print('ADLOG2: remove_ads entitlement is active: ${customerInfo!.entitlements.all['remove_ads']!.isActive}');
    }

    if (!customerInfo!.entitlements.all.containsKey('remove_ads') || 
        !customerInfo!.entitlements.all['remove_ads']!.isActive) { 

      print('ADLOG2: User does not have an active subscription, loading ad');

      // Load the interstitial ad
      InterstitialAd.load(
        adUnitId: 'ca-app-pub-5226927121793431/9906273974', // Replace with your Ad Unit ID
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('ADLOG2:InterstitialAd failed to load: $error');
          },
        ),
      );
    }
  }

    void _resizeImage(int width, int height) async {
      if (_selectedImage != null) {
        var imageBytes = await _selectedImage!.readAsBytes();
        if (kDebugMode) {
          print('Original image size: ${imageBytes.length} bytes');
        }
        
        // Decode the image
        img.Image? image = img.decodeImage(imageBytes);

        // Crop the image to the desired aspect ratio
        int cropSize = min(image!.width, image.height);
        int startX = (image.width - cropSize) ~/ 2;
        int startY = (image.height - cropSize) ~/ 2;
        img.Image croppedImage = img.copyCrop(image, x: startX, y: startY, width: cropSize, height: cropSize);

        // Resize the image
        img.Image resizedImage = img.copyResize(croppedImage, width: width, height: height);

        // Compress the image
        List<int> compressedBytes = img.encodePng(resizedImage);
        if (kDebugMode) {
          print('Compressed image size: ${compressedBytes.length} bytes');
        }

        Directory tempDir = await getTemporaryDirectory();
        String tempPath = tempDir.path;

        // Generate a unique file name by appending a timestamp
        String fileName = 'resized_image_${DateTime.now().millisecondsSinceEpoch}.png';
        File tempFile = File('$tempPath/$fileName')..writeAsBytesSync(compressedBytes);

        setState(() {
          _selectedImage = tempFile;
          _loadingMessage = 'Animation size selected.';
          _isResizing = false;
        });
      }
    }


      void _sendImage() async {
        if (_selectedImage == null) {
          if (kDebugMode) {
            print('No image selected');
          }
          return;
        }

        if (kDebugMode) {
          print('Sending image: ${_selectedImage!.path}');
        }
        img.Image? image = img.decodeImage(File(_selectedImage!.path).readAsBytesSync());
        if (kDebugMode) {
          print('Image dimensions: ${image!.width} x ${image.height}');
        }

        // Check if the image dimensions are valid
        if (!((image?.width == 768 && image?.height == 768) ||
              (image?.width == 576 && image?.height == 1024) ||
              (image?.width == 1024 && image?.height == 576))) {
          Fluttertoast.showToast(
            msg: "Please select an animation size.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
          return;
        }

        setState(() {
          _loadingMessage = 'Image submitted, please wait...';
          const CircularProgressIndicator();
        });

    var multipartFile = await http.MultipartFile.fromPath(
      'image', 
      _selectedImage!.path, 
      filename: 'resized_image.png',
      contentType: MediaType('image', 'png'), // Specify the content type
    );

      // Create an instance of FlutterSecureStorage
      const storage = FlutterSecureStorage();

      // Read the API key from secure storage
      String? apiKey = await storage.read(key: 'api_key');

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl1));
    request = http.MultipartRequest('POST', Uri.parse(apiUrl1))
    ..headers['authorization'] = 'Bearer $apiKey'
    ..files.add(multipartFile) // Add the multipartFile to the request
    ..fields['seed'] = seedController.text
    ..fields['cfg_scale'] = cfgScaleValue.toString()
    ..fields['motion_bucket_id'] = motionBucketIdValue.round().toString();


    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _generationId = jsonDecode(responseBody)['id'];
        if (kDebugMode) {
          print('Image sent, generation ID: $_generationId');
        }
        setState(() {
          _loadingMessage = 'Image accepted and processing..';
        });

        // Cancel the previous timer if it exists
        _timer?.cancel();

        // Start a new timer
        _timer = RestartableTimer(const Duration(seconds: 10), _checkResponse);
      } else {
        if (kDebugMode) {
          print('Error: ${response.reasonPhrase}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

void _checkResponse() async {
  // Send a GET request to the second API
  try {
          // Create an instance of FlutterSecureStorage
      const storage = FlutterSecureStorage();
      // Read the API key from secure storage
      String? apiKey = await storage.read(key: 'api_key');
    var response = await http.get(
      Uri.parse(apiUrl2 + _generationId!),
      headers: {
        'accept': 'application/json', // Use 'application/json' to receive base64 encoded JSON
        'authorization': 'Bearer $apiKey',
      },
    );

    var responseBody = utf8.decode(response.bodyBytes);
    var json = jsonDecode(responseBody);

    if (response.statusCode == 202) {
        if (kDebugMode) {
          print('Generation is still running, keep waiting...');
        }
        var messages = [
          'Image still processing...',
          "Tweaking the animation...",
          "Bringing the image to life...",
          'Fine tuning the animation...'
        ];
        var random = Random();
        var message = messages[random.nextInt(messages.length)];
        setState(() {
          _loadingMessage = message;
        });
        _timer?.reset();
      } else if (response.statusCode == 200) {
  if (kDebugMode) {
    print('Generation is complete!');
  }
  _timer?.cancel();

  // Save the received mp4 file and display it on the screen
  var bytes = base64Decode(json['video']);
  if (kDebugMode) {
    print('Decoded bytes: $bytes');
  }
  String dir = (await getApplicationDocumentsDirectory()).path;
  File file = File('$dir/output.mp4');
  if (kDebugMode) {
    print('File path: ${file.path}');
  }
  await file.writeAsBytes(bytes);
  if (kDebugMode) {
    print('File size: ${await file.length()} bytes');
  }

  setState(() {
    _loadingMessage = 'Animation Saved.';
  });

  // Save the video to the gallery
  final result = await ImageGallerySaver.saveFile(file.path);
  if (kDebugMode) {
    print('Saved to gallery: $result');
  }

  if (kDebugMode) {
    print('File exists: ${await file.exists()}');
  }
    _controller = VideoPlayerController.file(file)
      ..setLooping(true); // Add this line
    _initializeVideoPlayerFuture = _controller!.initialize();
      _initializeVideoPlayerFuture!.then((_) {
    // Call setState after the video is initialized
    setState(() {
      _controller!.play(); // Play the video after it's initialized
      if (kDebugMode) {
        print('Video player initialized and playing: ${_controller!.value.isPlaying}');
      }
    });
  });

  if (kDebugMode) {
    print('Video player initialized with file: ${file.path}');
  }
} else {
  if (kDebugMode) {
    print(json);
  }
  _timer?.cancel();
}
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
    _timer?.cancel();
  }
}

@override
  void initState() {
  super.initState();
  _controller = VideoPlayerController.network('your_video_url');
  _initializeVideoPlayerFuture = _controller!.initialize();
}

Widget buildVideoPlayer() {
  return FutureBuilder(
    future: _initializeVideoPlayerFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        // The video player has been initialized, build the UI.
        if (kDebugMode) {
          print('Building video player widget with aspect ratio: ${_controller!.value.aspectRatio}');
        }
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        // The video player is still being initialized, show a loading spinner.
        return const SpinKitDancingSquare(
        color: Colors.blue,
        size: 100.0,
      );
      }
    },
  );
}


@override
Widget build(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  if (kDebugMode) {
    print('_controller: $_controller, _controller!.value.isInitialized: ${_controller != null ? _controller!.value.isInitialized : 'N/A'}');
  }
  return MainScreen(
    body: Scaffold(
      backgroundColor: themeProvider.isNightMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          'Image to Animation',
          style: GoogleFonts.montserratAlternates(),
        ),
        backgroundColor: themeProvider.isNightMode ? Colors.grey[850] : Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "Status: $_loadingMessage",
                style: GoogleFonts.montserratAlternates(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setState(() {
                  _selectedImage = File(pickedFile.path);
                });
                if (kDebugMode) {
                  print('Image selected: ${_selectedImage!.path}');
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                height: 350, // specify the height
                width: 350, // specify the width
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: _controller != null && _controller!.value.isInitialized
                      ? buildVideoPlayer()
                      : _selectedImage != null 
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ) 
                          : Image.asset(
                              'assets/placeholder.png',
                              fit: BoxFit.cover,
                            ),
                      ),
                    ),
                  ),
                ),
                    if (_loadingMessage.startsWith('Image accepted') || 
                        _loadingMessage.startsWith('Image still processing') || 
                        _loadingMessage.startsWith('Bringing the image') ||
                        _loadingMessage.startsWith('Tweaking the') ||
                        _loadingMessage.startsWith('Fine tuning the'))
                                   const SpinKitPulse(
                color: Colors.deepPurple,
                size: 200.0,
              )
                  ],
                ),
              Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 0), // Adjust as needed
                  child: Text(
                    'Animation Size',
                    style: GoogleFonts.montserratAlternates(
                      color: Colors.grey,
                      fontWeight: FontWeight.w700,

                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(
                        Icons.crop_square,
                        color: _is768x768 ? Colors.blue : Colors.grey,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _is768x768 = true;
                          _is576x1024 = false;
                          _is1024x576 = false;
                        });
                        _resizeImage(768, 768);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.crop_portrait,
                        color: _is576x1024 ? Colors.blue : Colors.grey,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _is768x768 = false;
                          _is576x1024 = true;
                          _is1024x576 = false;
                        });
                        _resizeImage(576, 1024);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.crop_landscape,
                        color: _is1024x576 ? Colors.blue : Colors.grey,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _is768x768 = false;
                          _is576x1024 = false;
                          _is1024x576 = true;
                        });
                        _resizeImage(1024, 576);
                      },
                    ),
                  ],
                ),
                  ElevatedButton(
                    onPressed: () async {
                      AppsflyerService().appsflyerSdk.logEvent('image_to_anim_generate', {});
                      initAds2();
                      _sendImage();
                    },
                    child: const Text('Animate'),
                  ),
                    if (_isResizing) const CircularProgressIndicator(), // Add this line
                    ElevatedButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),

              ],
            ),
          ),
        ],
      ),
floatingActionButton: FloatingActionButton(
  child: const Icon(Icons.settings),
  onPressed: () {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'CFG Scale: How strongly the video sticks to the original image. Use lower values to allow the model more freedom to make changes and higher values to correct motion distortions.',
                    style: TextStyle(
                      color: themeProvider.isNightMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Slider(
                    value: cfgScaleValue,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    label: cfgScaleValue.toString(),
                    onChanged: (double value) {
                      setState(() {
                        cfgScaleValue = value;
                      });
                    },
                  ),
                  Text(
                    'Motion Bucket: Lower values generally result in less motion in the output video, while higher values generally result in more motion.',
                    style: TextStyle(
                      color: themeProvider.isNightMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Slider(
                    value: motionBucketIdValue,
                    min: 1,
                    max: 255,
                    divisions: 254,
                    label: motionBucketIdValue.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        motionBucketIdValue = value;
                      });
                    },
                  ),
                  Text(
                    'Seed: A specific value that is used to guide the randomness of the generation. Values from 0 to 2147483648 accepted. 0=Random.',
                    style: TextStyle(
                      color: themeProvider.isNightMode ? Colors.white : Colors.black,
                    ),
                  ),
                  TextField(
                    controller: seedController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ], // Only numbers can be entered
                    onChanged: (value) {
                      // Update the seed value
                    },
                    decoration: InputDecoration(
                      fillColor: themeProvider.isNightMode ? Colors.grey : Colors.white,
                      filled: true,
                    ),
                  ),
                  Center(
                    child: ElevatedButton(
                      child: Text(
                        'Apply Settings',
                        style: TextStyle(
                          color: themeProvider.isNightMode ? Colors.white : Colors.black,
                        ),
                      ),
                      onPressed: () {
                        // Update the fields of the request object
                        request?.fields['seed'] = seedController.text;
                        request?.fields['cfg_scale'] = cfgScaleValue.toString();
                        request?.fields['motion_bucket_id'] = motionBucketIdValue.round().toString();
                        if (kDebugMode) {
                          print('Fields: ${request?.fields}');
                        }
                        Navigator.pop(context);
                              },
                            ),
                          )
                    ],
                  ),
                );
                           },
          );
        },
      );
    },
  ),
),
    );  
}
}
