import 'dart:io';
import 'package:ai_imagez/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_compare_slider/image_compare_slider.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'appsflyer_service.dart';
import 'main_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';


class ImageUpscalerPage extends StatefulWidget {
  const ImageUpscalerPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ImageUpscalerPageState createState() => _ImageUpscalerPageState();
  
}

class _ImageUpscalerPageState extends State<ImageUpscalerPage> {
  File? _image;
  File? _upscaledImage;
  bool _isLoading = false;
  bool isAd1Loaded = false;
  CustomerInfo? customerInfo; 
  late BannerAd bannerAd1;

    @override
  void initState() {
    super.initState();
    initAds();
  }
 

  Future<void> initAds() async {
  CustomerInfo info = await Purchases.getCustomerInfo(); // Fetch the customerInfo
  setState(() {
    customerInfo = info; // Update customerInfo inside setState
  });
    print('ADLOG: Customer info fetched');
    print('ADLOG: All entitlements: ${customerInfo!.entitlements.all}'); // Print all entitlements
    print('ADLOG: remove_ads entitlement exists: ${customerInfo!.entitlements.all.containsKey('remove_ads')}');
    if (customerInfo!.entitlements.all.containsKey('remove_ads')) {
      print('ADLOG: remove_ads entitlement is active: ${customerInfo!.entitlements.all['remove_ads']!.isActive}');
    }

    if (!customerInfo!.entitlements.all.containsKey('remove_ads') || 
        !customerInfo!.entitlements.all['remove_ads']!.isActive) { 

      print('ADLOG: User does not have an active subscription, loading ad');

      // Load the ads
      bannerAd1 = BannerAd(
        adUnitId: 'ca-app-pub-5226927121793431/8806921080', // Replace with your Ad Unit ID
        size: AdSize.largeBanner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() {
              isAd1Loaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            print('Ad failed to load: $error');
            print('ADLOG2: Error code: ${error.code}');
            print('ADLOG2: Error domain: ${error.domain}');
            print('ADLOG2: Error message: ${error.message}');
          },
        ),
      )..load();
    }
  }

  bool hasActiveSubscription() {
  if (customerInfo != null) {
    if (customerInfo!.entitlements.all.containsKey('remove_ads')) {
      return customerInfo!.entitlements.all['remove_ads']!.isActive;
    }
  }
  return false;
}


  
  Future getImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
 

      var image = img.decodeImage(await pickedFile.readAsBytes());
      if (image != null && (image.width > 1024 || image.height > 1024)) {
        Fluttertoast.showToast(
          msg: "Image size should not exceed 1024x1024",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
        );
        return;
      }

      setState(() {
        _image = File(pickedFile.path);
      });
    } else {
      if (kDebugMode) {
        print('No image selected.');
      }
    }
  }

Future upscaleImage() async {
  setState(() {
    _isLoading = true;
  });

  // Create an instance of FlutterSecureStorage
  const storage = FlutterSecureStorage();

  // Read the API key from secure storage
  String? apiKey = await storage.read(key: 'api_key');

  var request = http.MultipartRequest('POST', Uri.parse('https://api.stability.ai/v1/generation/esrgan-v1-x2plus/image-to-image/upscale'));
  request.headers.addAll({
    'Accept': 'image/png',
    'Authorization': 'Bearer $apiKey',
  });
  if (_image != null) {
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
  }

    var response = await http.Response.fromStream(await request.send());
    print (response.body);

    if (response.statusCode == 200) {
      var imageData = response.bodyBytes;
      var tempDir = await getTemporaryDirectory();
      var file = File('${tempDir.path}/image.png');
      await file.writeAsBytes(imageData);

      setState(() {
        _upscaledImage = file;
        _isLoading = false;
      });

      final result = await ImageGallerySaver.saveFile(file.path);
      if (result['isSuccess']) {
        Fluttertoast.showToast(
          msg: "Image saved successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0
        );
      } else {
        if (kDebugMode) {
          print("Failed to save the image!");
        }
      }
    } else {
      if (kDebugMode) {
        print('Failed to upscale the image. Status code: ${response.statusCode}, Message: ${response.body}');
      }
    }
  }

  void reset() {
  setState(() {
    _image = null;
    _upscaledImage = null;
  });
  imageCache.clear();
}

@override
Widget build(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  return MainScreen(
    body: InteractiveViewer(
      minScale: 1.0,
      maxScale: 2.5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Image Upscaler'),
          backgroundColor: themeProvider.isNightMode ? Colors.grey[850] : Colors.white,
        ),
        body: Container(
          color: themeProvider.isNightMode ? Colors.black : Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _isLoading
                  ? const SpinKitPulse(
                color: Colors.deepPurple,
                size: 200.0,
                   )
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 0.0), // add padding to the bottom of the image
                      child: Container(
                        height: 300, // specify the height of the image here
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          // boxShadow removed
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: _upscaledImage != null
                              ? ImageCompareSlider(
                                  itemOne: Image.file(_image!),
                                  itemTwo: Image.file(_upscaledImage!),
                                  fillHandle: true,
                                  dividerColor: const Color.fromARGB(255, 145, 7, 195),
                                  dividerWidth: 6,
                                )
                              : GestureDetector(
                                  onTap: getImage,
                                  child: _image == null
                                      ? Image.asset('assets/placeholder.png')
                                      : Image.file(_image!),
                                ),
                        ),
                      ),
                    ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0), // add padding to the bottom of the text
                child: Text(
                  "Use AI to increase your image details.\nMax Input 1024x1024\nMax Output 2048x2048",
                  style: TextStyle(
                    color: themeProvider.isNightMode ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0), // add padding to the bottom of the button
                child: ElevatedButton.icon(
                  onPressed: () {
                    AppsflyerService().appsflyerSdk.logEvent('image_upscale_generate', {});
                    upscaleImage();
                  },
                  label: const Text('Upscale Image x2'),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ),
              if (!hasActiveSubscription() && isAd1Loaded) 
                Container(
                  child: AdWidget(ad: bannerAd1),
                  width: bannerAd1.size.width.toDouble(),
                  height: bannerAd1.size.height.toDouble(),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}