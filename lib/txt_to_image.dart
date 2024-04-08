import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'appsflyer_service.dart';
import 'main_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'theme_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ai_imagez/revcat_sdk.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _cfgScaleValue = 7.0;
  String _seedValue = '0';
  String _inputText = '';
  Uint8List? _imageBytes;
  bool _isLoading = false;
  final FocusNode _focusNode = FocusNode();
  final _sizes = [
    '1024x1024',
    '1152x896',
    '1216x832',
    '1344x768',
    '1536x640',
    '640x1536',
    '768x1344',
    '832x1216',
    '896x1152'
  ];
  String _selectedSize = '1024x1024'; // Add this line
  final List<String> _stylePresetsList = [
    '3d-model',
    'anime',
    'cinematic',
    'comic-book',
    'digital-art',
    'enhance',
    'fantasy-art',
    'isometric',
    'line-art',
    'low-poly',
    'neon-punk',
    'origami',
    'photographic',
    'pixel-art',
    'tile-texture'
  ];
  String _selectedStylePreset = '3d-model'; // default value
  final _seedValueController = TextEditingController(text: "0");
  final TextEditingController _controller = TextEditingController();

  late Map<String, String> _stylePresets;

  @override
  void initState() {
    super.initState();
    _stylePresets = {
      for (var item in _stylePresetsList) item: 'assets/images/$item.jpg'
    };
    _loadText();
    loadAd();
    if (kDebugMode) {
      print('initState completed');
    }
  }

  _loadText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _controller.text = (prefs.getString('textField1') ?? '');
    });
    if (kDebugMode) {
      print('Loaded text: ${_controller.text}');
    }
  }

  void _saveImage() async {
    final result = await ImageGallerySaver.saveImage(_imageBytes!);
    Fluttertoast.showToast(
        msg: result['isSuccess'] ? 'Image saved!' : 'Failed to save image',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  InterstitialAd? myInterstitialAd;
  bool isAdLoaded = false;

  Future<void> loadAd() async {
    InterstitialAd.load(
      adUnitId:
          'ca-app-pub-5226927121793431/9906273974', // Replace with your Ad Unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (Ad ad) {
          print('ADLOG: Ad loaded.');
          myInterstitialAd = ad as InterstitialAd;
          isAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('ADLOG: Ad failed to load: $error');
          print('ADLOG: Error code: ${error.code}');
          print('ADLOG: Error domain: ${error.domain}');
          print('ADLOG: Error message: ${error.message}');
          isAdLoaded = false;
        },
      ),
    );
  }

  void showAd() async {
    CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    if (!customerInfo.entitlements.all.containsKey('remove_ads') ||
        !customerInfo.entitlements.all['remove_ads']!.isActive) {
      if (isAdLoaded && myInterstitialAd != null) {
        myInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (Ad ad) {
            print('ADLOG: Ad dismissed.');
          },
          onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
            print('ADLOG: Ad failed to show: $error');
          },
        );
        myInterstitialAd!.show();
        myInterstitialAd = null;
        isAdLoaded = false;
      }
    }
  }

  void _shareImage() async {
    final tempDir = Directory.systemTemp;
    final file = await File('${tempDir.path}/image.png').create();
    await file.writeAsBytes(_imageBytes!);

    Share.shareFiles([file.path],
        text:
            'Check out this image I created on the PixelCraft app! https://play.google.com/store/apps/details?id=com.ai.wizardai');
  }

  void _generateImage() async {
    await _loadText();
    if (kDebugMode) {
      print('Text before API request: ${_controller.text}');
    }
    _focusNode.unfocus();
    setState(() {
      _isLoading = true;
    });
    String engineId = 'stable-diffusion-v1-6';
    String apiHost = 'https://api.stability.ai';

    const storage = FlutterSecureStorage();
    String? apiKey = await storage.read(key: 'api_key');

    if (kDebugMode) {
      print('Selected style preset: $_selectedStylePreset');
    }

    try {
      var response = await http.post(
        Uri.parse('$apiHost/v1/generation/$engineId/text-to-image'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'text_prompts': [
            {'text': _controller.text},
          ],
          'cfg_scale': int.parse(_cfgScaleValue.round().toString()),
          'height': int.parse(_selectedSize.split('x')[0]),
          'width': int.parse(_selectedSize.split('x')[1]),
          'samples': 1,
          'steps': 30,
          'style_preset': _selectedStylePreset,
          'seed': int.parse(_seedValue),
        }),
      );

      //print input text
      if (kDebugMode) {
        print('input text: $_inputText');
      }

      // print the cfg_scale value and seed value
      if (kDebugMode) {
        print('cfg_scale: ${int.parse(_cfgScaleValue.round().toString())}');
      }
      if (kDebugMode) {
        print('seed: ${int.parse(_seedValue)}');
      }

      if (kDebugMode) {
        print('HTTP response status code: ${response.statusCode}');
      } // Add this line
      if (kDebugMode) {
        print('HTTP response body: ${response.body}');
      } // Add this line

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var imageBase64 = data['artifacts'][0]['base64'];
        var imageBytes = base64Decode(imageBase64);
        Uint8List? compressedImage;

        if (!kIsWeb) {
          compressedImage = await FlutterImageCompress.compressWithList(
            imageBytes,
            minWidth: 1024,
            minHeight: 1024,
            quality: 88,
          );
        } else {
          compressedImage = imageBytes;
        }

        setState(() {
          _imageBytes = compressedImage;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to generate image');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        if (!snapshot.hasData) {
          return const SpinKitPulse(
            color: Colors.deepPurple,
            size: 200.0,
          );
        }
        bool isNightMode = snapshot.data!.getBool('nightMode') ?? false;
        return MainScreen(
          body: Scaffold(
            appBar: AppBar(
              title: const Text('Text to Image'),
            ),
            backgroundColor: isNightMode ? Colors.black : Colors.white,
            body: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _isLoading
                          ? const SpinKitPulse(
                              color: Colors.deepPurple,
                              size: 200.0,
                            )
                          : _imageBytes != null
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 5,
                                        blurRadius: 7,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15.0),
                                    child: Image.memory(_imageBytes!),
                                  ),
                                )
                              : const Text(''),
                      if (_imageBytes != null) ...[
                        const SizedBox(
                            height: 20), // Add padding above the buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _saveImage,
                              child: const Text(
                                'Save',
                              ),
                            ),
                            if (!kIsWeb) ...[
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _shareImage,
                                child: const Text(
                                  'Share',
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: TextField(
                          controller: _controller, // Add this line
                          focusNode: _focusNode,
                          onChanged: (value) async {
                            setState(() {
                              _inputText = value;
                            });
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            prefs.setString(
                                'textField1', value); // Save the text
                          },
                          decoration: InputDecoration(
                            labelText: 'Enter your text prompt here..',
                            labelStyle: TextStyle(
                              color: isNightMode ? Colors.white : Colors.black,
                            ),
                            fillColor: isNightMode
                                ? const Color.fromARGB(255, 95, 95, 95)
                                : Colors.grey[200],
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: const BorderSide(),
                            ),
                          ),
                          maxLines:
                              5, // Make the TextField expand as the user types more lines of text
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Text(
                          'Select Style:',
                          style: TextStyle(
                            color:
                                Provider.of<ThemeProvider>(context).isNightMode
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 120, // adjust as needed
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _stylePresets.length,
                          itemBuilder: (context, index) {
                            final styleName =
                                _stylePresets.keys.elementAt(index);
                            final imageUrl =
                                _stylePresets.values.elementAt(index);
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedStylePreset = styleName;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedStylePreset == styleName
                                        ? Colors.blue
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _selectedStylePreset == styleName
                                          ? Colors.blue
                                          : Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 2,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Consumer<ThemeProvider>(
                                        builder:
                                            (context, themeProvider, child) {
                                          return Text(
                                            styleName,
                                            style: TextStyle(
                                              color: themeProvider.isNightMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          );
                                        },
                                      ),
                                      Image.asset(imageUrl,
                                          width: 75,
                                          height: 70), // adjust as needed
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Select Size',
                                    style: TextStyle(
                                      color: Provider.of<ThemeProvider>(context)
                                              .isNightMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  FittedBox(
                                    child: DropdownButton<String>(
                                      value: _selectedSize,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedSize = newValue!;
                                        });
                                      },
                                      items: _sizes
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        final themeProvider =
                                            Provider.of<ThemeProvider>(context);
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Center(
                                            child: Text(
                                              value,
                                              style: TextStyle(
                                                color: themeProvider.isNightMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                AppsflyerService()
                                    .appsflyerSdk
                                    .logEvent('txt_to_image_generate', {});
                                _generateImage();
                                await configureSDK();
                                await loadAd();
                                showAd();
                              },
                              child: const Text('Generate'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    final themeProvider = Provider.of<ThemeProvider>(context);
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'CFG Scale: How strictly the diffusion process adheres to the prompt text (higher values keep your image closer to your prompt).',
                                style: TextStyle(
                                  color: themeProvider.isNightMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              Slider(
                                min: 0,
                                max: 35,
                                divisions: 35,
                                value: _cfgScaleValue,
                                label: _cfgScaleValue.round().toString(),
                                onChanged: (double value) {
                                  setState(() {
                                    _cfgScaleValue = value;
                                  });
                                },
                              ),
                              Text(
                                'Seed: A random number that influences the image generation process. You can use this to generate different images from the same prompt. Values from 0>4294967295 accepted. 0=Random.',
                                style: TextStyle(
                                  color: themeProvider.isNightMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              TextField(
                                controller: _seedValueController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _seedValue = value;
                                },
                                decoration: const InputDecoration(
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                              ),
                              ElevatedButton(
                                child: Text(
                                  'Apply Settings',
                                  style: TextStyle(
                                    color: themeProvider.isNightMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context, {
                                    'cfgScaleValue': _cfgScaleValue,
                                    'seedValue': _seedValue,
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ).then((result) {
                  if (result != null) {
                    setState(() {
                      _cfgScaleValue = result['cfgScaleValue'];
                      _seedValue = result['seedValue'];
                    });
                  }
                });
              },
              child: const Icon(Icons.settings),
            ),
          ),
        );
      },
    );
  }
}
