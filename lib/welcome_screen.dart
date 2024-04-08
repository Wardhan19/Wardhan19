import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'txt_to_image.dart';
import 'image_to_image_page.dart';
import 'image_upscaler_page.dart';
import 'tools_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'appsflyer_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late PageController _pageController;
  List<Widget> slideList = [];
  int initialPage = 0;
  late AppsflyerSdk _appsflyerSdk;
  late Map _deepLinkData;
  late Map _gcd;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: initialPage);
    _appsflyerSdk =
        AppsflyerService().appsflyerSdk; // Use the singleton instance

    _appsflyerSdk.onAppOpenAttribution((res) {
      if (kDebugMode) {
        print("onAppOpenAttribution res: $res");
      }
      setState(() {
        _deepLinkData = res;
      });
    });

    _appsflyerSdk.onInstallConversionData((res) {
      if (kDebugMode) {
        print("onInstallConversionData res: $res");
      }
      setState(() {
        _gcd = res;
      });
    });

    _appsflyerSdk.onDeepLinking((DeepLinkResult dp) {
      switch (dp.status) {
        case Status.FOUND:
          if (kDebugMode) {
            print(dp.deepLink?.toString());
          }
          if (kDebugMode) {
            print("deep link value: ${dp.deepLink?.deepLinkValue}");
          }
          break;
        case Status.NOT_FOUND:
          if (kDebugMode) {
            print("deep link not found");
          }
          break;
        case Status.ERROR:
          if (kDebugMode) {
            print("deep link error: ${dp.error}");
          }
          break;
        case Status.PARSE_ERROR:
          if (kDebugMode) {
            print("deep link status parsing error");
          }
          break;
      }
      if (kDebugMode) {
        print("onDeepLinking res: $dp");
      }
      setState(() {
        _deepLinkData = dp.toJson();
      });
    });
  }

  void _launchURL() async {
    const url =
        'https://play.google.com/store/apps/details?id=your_app_id'; // Replace <your_app_id> with your actual app id
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Theme(
        data: ThemeData(
          hintColor: GFColors.SUCCESS, // color of active dot
          unselectedWidgetColor: Colors.grey[200], // color of inactive dot
        ),
        child: GFIntroScreen(
          color: Colors.blueGrey,
          slides: slides(),
          pageController: _pageController,
          currentIndex: initialPage,
          pageCount: slideList.length,
          introScreenBottomNavigationBar: GFIntroScreenBottomNavigationBar(
            pageController: _pageController,
            pageCount: slideList.length,
            currentIndex: initialPage,
            onForwardButtonTap: () {
              _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.linear);
            },
            onBackButtonTap: () {
              _pageController.previousPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.linear);
            },
            onDoneTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const MyHomePage(title: 'Text To Image')),
              );
            },
            onSkipTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const MyHomePage(title: 'Text To Image')),
              );
            },
            navigationBarColor: Colors.white,
            showDivider: false,
          ),
        ),
      ),
    );
  }

  List<Widget> slides() {
    slideList = [
      Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/image2.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment
                  .end, // Align the children to the end of the column
              children: [
                Center(
                  child: Container(
                    width: 230, // Set the width of the Container
                    height:
                        75, // Increase the height of the Container to fit the text
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius:
                          BorderRadius.circular(10), // Set the border radius
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Review App <3',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Change the color of the text
                            decoration:
                                TextDecoration.none, // Remove the underline
                          ),
                        ),
                        RatingBar.builder(
                          initialRating: 0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding:
                              const EdgeInsets.symmetric(horizontal: 1.0),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            _launchURL(); // Open the app store listing when a star is clicked
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                'assets/images/image1.png',
                height: 100,
                width: MediaQuery.of(context).size.width - 20,
              ))
        ],
      ),
      Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/image2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
      ),
      Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/image2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const MyHomePage(title: 'Text To Image')),
                );

                // Log event with AppsFlyer
                _appsflyerSdk.logEvent('ws_text_to_image_clicked', {});
              },
              child: const Text('Text to Image'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ImageToImagePage()),
                );

                // Log event with AppsFlyer
                _appsflyerSdk.logEvent('ws_image_to_image_clicked', {});
              },
              child: const Text('Image to Image'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ImageUpscalerPage()),
                );

                // Log event with AppsFlyer
                _appsflyerSdk.logEvent('ws_image_upscale_clicked', {});
              },
              child: const Text('Image Upscale'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ToolsPage()),
                );

                // Log event with AppsFlyer
                _appsflyerSdk.logEvent('ws_image_to_animation_clicked', {});
              },
              child: const Text('Image to Animation'),
            ),

            const SizedBox(height: 10), // Add some spacing
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: 20.0), // Adjust as needed
                child: Text.rich(
                  TextSpan(
                    text: 'By using this app\nyou agree to our\n',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        decoration: TextDecoration.none),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                            decoration: TextDecoration.none),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launch('https://gocreate.art/privacy.html');
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center, // Add this
                ),
              ),
            ),
          ],
        ),
      ),
    ];
    return slideList;
  }

  Future<bool?> logEvent(String eventName, Map eventValues) {
    return _appsflyerSdk.logEvent(eventName, eventValues);
  }
}
