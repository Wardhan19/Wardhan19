import 'dart:io';
import 'package:ai_imagez/theme_provider.dart';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'appsflyer_service.dart';
import 'main_screen.dart';
import 'package:share/share.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ImageToImagePage extends StatefulWidget {
  const ImageToImagePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ImageToImagePageState createState() => _ImageToImagePageState();
}

class ImageDisplay extends StatefulWidget {
  final File? image;
  final bool isLoading;
  final ValueNotifier<File?> imageNotifier;

  const ImageDisplay(
      {super.key,
      this.image,
      this.isLoading = false,
      required this.imageNotifier});

  @override
  // ignore: library_private_types_in_public_api
  _ImageDisplayState createState() => _ImageDisplayState();
}

class _ImageDisplayState extends State<ImageDisplay> {
  @override
  void initState() {
    super.initState();
    // presentPaywall();
  }

  void presentPaywall() async {
    final paywallResult = await RevenueCatUI.presentPaywall();
    log('Paywall result: $paywallResult');
  }

  @override
  void didUpdateWidget(covariant ImageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      if (kDebugMode) {
        print('Image updated in ImageDisplay widget');
      }
      widget.imageNotifier.value = widget.image;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Building ImageDisplayPart widget1');
    }
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Padding(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: ImageDisplayPart(imageNotifier: widget.imageNotifier),
            ),
          ),
        ),
        widget.isLoading
            ? const SpinKitPulse(
                color: Colors.deepPurple,
                size: 200.0,
              )
            : Container(),
      ],
    );
  }
}

class ImageDisplayPart extends StatelessWidget {
  final ValueNotifier<File?> imageNotifier;
  final GlobalKey _globalKey = GlobalKey();

  ImageDisplayPart({super.key, required this.imageNotifier});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Building ImageDisplayPart widget2');
    }
    return ValueListenableBuilder<File?>(
      valueListenable: imageNotifier,
      builder: (context, image, child) {
        return AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: image == null
              ? Image.asset('assets/placeholder.png',
                  key: const ValueKey<String>('placeholder'))
              : FutureBuilder(
                  future: evictImage(image, context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (kDebugMode) {
                        print('Image has been loaded');
                      } // Log message
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(
                                    0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(image), // Display the image
                          ),
                        ),
                      );
                    } else {
                      if (kDebugMode) {
                        print('Image is still loading');
                      } // Log message
                      return const CircularProgressIndicator();
                    }
                  },
                ),
        );
      },
    );
  }

  Future<void> evictImage(File imageFile, BuildContext context) async {
    final imageProvider = FileImage(imageFile);
    if (kDebugMode) {
      print('Evicting image from cache');
    } // Log message
    await imageProvider.evict();
    if (kDebugMode) {
      print('Pre-caching image');
    } // Log message
    // ignore: use_build_context_synchronously
    await precacheImage(
        imageProvider, (_globalKey.currentState as ScaffoldState).context);
    if (kDebugMode) {
      print('Image pre-cached');
    } // Log message
  }
}

class _ImageToImagePageState extends State<ImageToImagePage> {
  File? _image;
  bool _isLoading = false;
  final ValueNotifier<File?> imageNotifier = ValueNotifier<File?>(null);
  final ValueNotifier<String> _selectedStyleNotifier =
      ValueNotifier<String>('');
  final TextEditingController _textController = TextEditingController();
  bool _isImageLoadedFromAPI = false;
  double _imageStrength = 0.35;
  double _cfgScaleValue = 7;
  String _negativePrompt = 'bad, blurry';
  final _negativePromptController = TextEditingController(text: "bad, blurry");

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

  late Map<String, String> _stylePresets;

  void _onStyleSelected(String styleName) {
    _selectedStylePreset = styleName;
  }

  void _loadText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _textController.text = (prefs.getString('textField') ?? '');
  }

  @override
  void initState() {
    super.initState();
    // _imageKey = const ValueKey('image'); // Initialize with a constant value
    _stylePresets = {
      for (var item in _stylePresetsList) item: 'assets/images/$item.jpg'
    };
    _loadText();
    // ...
  }

  Future getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        if (kDebugMode) {
          print('Image selected: ${pickedFile.path}');
        }
        _image = File(pickedFile.path);
        imageNotifier.value =
            _image; // Notify the ImageDisplay widget of the new image
      } else {
        if (kDebugMode) {
          print('No image selected.');
        }
      }
    });
  }

  void generateImage(BuildContext context) async {
    const storage = FlutterSecureStorage();

    // Read the API key from secure storage
    String? apiKey = await storage.read(key: 'api_key');

    if (_textController.text.trim().isEmpty) {
      Fluttertoast.showToast(
          msg: "Please enter an image description first.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }

    setState(() {
      _isLoading = true;
      _isImageLoadedFromAPI = false;
    });

    img.Image? image = img.decodeImage(await _image!.readAsBytes());
    String imageSize = '${image!.width}x${image.height}';

    // Log the image size
    if (kDebugMode) {
      print('Image size: $imageSize');
    }

    // List of accepted sizes
    List<String> acceptedSizes = [
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

    bool isSizeAccepted = acceptedSizes.contains(imageSize);

    // Log the result of the size check
    if (kDebugMode) {
      print('Is size accepted: $isSizeAccepted');
    }

    if (!isSizeAccepted) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "The image size is not accepted, must be one of the following: ['1024x1024', '1152x896', '1216x832', '1344x768', '1536x640', '640x1536', '768x1344', '832x1216', '896x1152']. Please resize your image or use the text to image feature to generate an image first."),
          duration: Duration(seconds: 8),
        ),
      );
      return;
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    var stream = http.ByteStream(DelegatingStream.typed(_image!.openRead()));
    var length = await _image!.length();

    var uri = Uri.parse(
        'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/image-to-image');

    var request = http.MultipartRequest("POST", uri);
    var multipartFile = http.MultipartFile('init_image', stream, length,
        filename: basename(_image!.path));

    request.files.add(multipartFile);
    request.fields['init_image_mode'] = 'IMAGE_STRENGTH';
    request.fields['image_strength'] = _imageStrength.toString();
    request.fields['steps'] = '30';
    request.fields['cfg_scale'] = _cfgScaleValue.toString();
    request.fields['samples'] = '1';
    request.fields['style_preset'] = _selectedStylePreset;
    request.fields['text_prompts[0][text]'] = _textController.text;
    request.fields['text_prompts[0][weight]'] = '1';
    request.fields['text_prompts[1][text]'] = _negativePrompt;
    request.fields['text_prompts[1][weight]'] = '-1';

    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer ${apiKey!}';

    if (kDebugMode) {
      print('Style preset being sent: $_selectedStylePreset');
    }

    //print the cfgscale value, image strength, and negative prompt
    if (kDebugMode) {
      print('CFG Scale: $_cfgScaleValue');
    }
    if (kDebugMode) {
      print('Image Strength: $_imageStrength');
    }
    if (kDebugMode) {
      print('Negative Prompt: $_negativePrompt');
    }

    var response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print("Uploaded!");
      }
      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response body: ${response.body}');
      }

      var responseBody = jsonDecode(response.body);

      if (responseBody['artifacts'][0]['base64'] != null) {
        var imageBase64 = responseBody['artifacts'][0]['base64'];

        var imageData = base64Decode(imageBase64);

        var tempDir = await getTemporaryDirectory();

        var file = File('${tempDir.path}/image.jpg');

        await file.writeAsBytes(imageData);

        setState(() {
          _image = file;
        });

        // Save the image to the gallery
        final result = await ImageGallerySaver.saveFile(file.path);
        if (result['isSuccess']) {
          Fluttertoast.showToast(
              msg: "Image saved successfully!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0);
        } else {
          if (kDebugMode) {
            print("Failed to save the image!");
          }
        }

        setState(() {
          _isLoading = false;
          _isImageLoadedFromAPI = true;
        });
      }
    }
  }

  void _shareImage() async {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/image.jpg').create();
    await file.writeAsBytes(await _image!.readAsBytes());

    Share.shareFiles([file.path],
        text:
            'Check out this image I created on the PixelCraft app! https://play.google.com/store/apps/details?id=com.ai.wizardai');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MainScreen(
      body: Scaffold(
        backgroundColor:
            themeProvider.isNightMode ? Colors.black : Colors.white,
        appBar: AppBar(
          title: const Text('Image To Image'),
          backgroundColor:
              themeProvider.isNightMode ? Colors.grey[850] : Colors.white,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTap: getImage,
                  child: ImageDisplay(
                      image: _image,
                      isLoading: _isLoading,
                      imageNotifier: imageNotifier),
                ),
                if (_isImageLoadedFromAPI) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: _shareImage,
                          child: const Text(
                            'Share',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ImageToImagePage()),
                            );
                          },
                          child: const Text(
                            'Reset',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    'Select Style:',
                    style: TextStyle(
                      color: themeProvider.isNightMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: _selectedStyleNotifier,
                  builder: (context, value, child) {
                    return StyleSelector(
                      stylePresetsList: _stylePresets.keys.toList(),
                      onStyleSelected: _onStyleSelected,
                    );
                  },
                ), // Use the StyleSelector widget to select a style
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      labelText: 'Describe your image...',
                      labelStyle: TextStyle(
                        color: themeProvider.isNightMode
                            ? Colors.white
                            : Colors.black,
                      ),
                      fillColor: themeProvider.isNightMode
                          ? const Color.fromARGB(255, 95, 95, 95)
                          : Colors.grey[200],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(),
                      ),
                    ),
                    onChanged: (value) async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      prefs.setString('textField', value); // Save the text
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      AppsflyerService()
                          .appsflyerSdk
                          .logEvent('image_to_image_generate', {});
                      generateImage(context);
                    },
                    child: const Text('Generate Image'),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Image Strength: How much influence your img has on the new one. Values close to 1 creates images very similar to the original while values close to 0 will create a wildly different img.',
                            style: TextStyle(
                              color: themeProvider.isNightMode
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 12.0, // Set the font size to 16 pixels
                            ),
                          ),
                          Slider(
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            value: _imageStrength,
                            label: _imageStrength.toStringAsFixed(2),
                            onChanged: (double value) {
                              setState(() {
                                _imageStrength = value;
                              });
                            },
                          ),
                          Text(
                            'CFG Scale: How strictly the AI adheres to the prompt (higher values keep your image closer to your prompt).',
                            style: TextStyle(
                              color: themeProvider.isNightMode
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 12.0, // Set the font size to 12 pixels
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
                            'Negative Prompt: This helps the AI understand what you don\'t want in your image.',
                            style: TextStyle(
                              color: themeProvider.isNightMode
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 12.0, // Set the font size to 12 pixels
                            ),
                          ),
                          TextField(
                            controller: _negativePromptController,
                            onChanged: (value) {
                              _negativePrompt = value;
                            },
                            decoration: const InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                          ElevatedButton(
                            child: const Text('Apply Settings'),
                            onPressed: () {
                              Navigator.pop(context, {
                                'imageStrength': _imageStrength,
                                'cfgScaleValue': _cfgScaleValue,
                                'negativePrompt': _negativePrompt,
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
                  _imageStrength = result['imageStrength'];
                  _cfgScaleValue = result['cfgScaleValue'];
                  _negativePrompt = result['negativePrompt'];
                });
              }
            });
          },
          child: const Icon(Icons.settings),
        ),
      ),
    );
  }
}

class StyleSelector extends StatefulWidget {
  final List<String> stylePresetsList;
  final Function(String) onStyleSelected;

  const StyleSelector(
      {super.key,
      required this.stylePresetsList,
      required this.onStyleSelected});

  @override
  // ignore: library_private_types_in_public_api
  _StyleSelectorState createState() => _StyleSelectorState();
}

class _StyleSelectorState extends State<StyleSelector> {
  String _selectedStylePreset = '3d-model'; // default value

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, // adjust as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.stylePresetsList.length,
        itemBuilder: (context, index) {
          final styleName = widget.stylePresetsList[index];
          final imageUrl = 'assets/images/$styleName.jpg';
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                if (kDebugMode) {
                  print('Style selected: $styleName');
                }
                setState(() {
                  _selectedStylePreset = styleName;
                });
                widget.onStyleSelected(styleName);
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
                      builder: (context, themeProvider, child) {
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
                        width: 75, height: 70), // adjust as needed
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
