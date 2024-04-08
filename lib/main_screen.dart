import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'appsflyer_service.dart';
import 'txt_to_image.dart';
import 'image_to_image_page.dart';
import 'image_upscaler_page.dart';
import 'tools_page.dart';
import 'insperation.dart';
import 'theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shimmer/shimmer.dart';

class MainScreen extends StatefulWidget {
  final Widget body;

  const MainScreen({super.key, required this.body});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late BannerAd bannerAd1;
  late BannerAd bannerAd2;
  bool isAd1Loaded = false;
  bool isAd2Loaded = false;
  CustomerInfo? customerInfo;

  @override
  void initState() {
    super.initState();
    initAds();
  }

  Future<void> initAds() async {
    CustomerInfo info =
        await Purchases.getCustomerInfo(); // Fetch the customerInfo
    setState(() {
      customerInfo = info; // Update customerInfo inside setState
    });
    if (kDebugMode) {
      print('ADLOG: Customer info fetched');
    }
    if (kDebugMode) {
      print('ADLOG: All entitlements: ${customerInfo!.entitlements.all}');
    } // Print all entitlements
    if (kDebugMode) {
      print(
          'ADLOG: remove_ads entitlement exists: ${customerInfo!.entitlements.all.containsKey('remove_ads')}');
    }
    if (customerInfo!.entitlements.all.containsKey('remove_ads')) {
      if (kDebugMode) {
        print(
            'ADLOG: remove_ads entitlement is active: ${customerInfo!.entitlements.all['remove_ads']!.isActive}');
      }
    }

    if (!customerInfo!.entitlements.all.containsKey('remove_ads') ||
        !customerInfo!.entitlements.all['remove_ads']!.isActive) {
      if (kDebugMode) {
        print('ADLOG: User does not have an active subscription, loading ad');
      }

      // Load the ads
      bannerAd1 = BannerAd(
        adUnitId: 'ca-app-pub-your/ad_unit_id', // Replace with your Ad Unit ID
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() {
              // isAd1Loaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (kDebugMode) {
              print('Ad failed to load: $error');
            }
            if (kDebugMode) {
              print('ADLOG2: Error code: ${error.code}');
            }
            if (kDebugMode) {
              print('ADLOG2: Error domain: ${error.domain}');
            }
            if (kDebugMode) {
              print('ADLOG2: Error message: ${error.message}');
            }
          },
        ),
      )..load();

      bannerAd2 = BannerAd(
        adUnitId: 'ca-app-pub-your/ad_unit_id', // Replace with your Ad Unit ID
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() {
              isAd2Loaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (kDebugMode) {
              print('Ad failed to load: $error');
            }
          },
        ),
      )..load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('WizardAI'),
            const Spacer(),
            isAd1Loaded
                ? SizedBox(
                    width: bannerAd1.size.width.toDouble(),
                    height: bannerAd1.size.height.toDouble(),
                    child: AdWidget(ad: bannerAd1),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              DrawerHeader(
                decoration: const BoxDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Image.asset('assets/welcome_image.png'),
                    ),
                    if (isAd2Loaded)
                      SizedBox(
                        width: bannerAd2.size.width.toDouble(),
                        height: bannerAd2.size.height.toDouble(),
                        child: AdWidget(ad: bannerAd2),
                      ),
                  ],
                ),
              ),
              if (customerInfo == null ||
                  !customerInfo!.entitlements.all.containsKey('remove_ads') ||
                  !customerInfo!.entitlements.all['remove_ads']!.isActive)
                ListTile(
                  leading: const Icon(Icons.verified),
                  title: Shimmer.fromColors(
                    baseColor:
                        Colors.grey[700]!, // Change base color to desired color
                    highlightColor: Colors
                        .grey[300]!, // Change highlight color to desired color
                    child: const Text('WizardAI PRO'),
                  ),
                  onTap: () async {
                    AppsflyerService()
                        .appsflyerSdk
                        .logEvent('mm_pixelcraft_pro_clicked', {});
                    final paywallResult =
                        await RevenueCatUI.presentPaywallIfNeeded("remove_ads");
                    if (kDebugMode) {
                      print('Paywall result: $paywallResult');
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Text To Image'),
                onTap: () {
                  AppsflyerService()
                      .appsflyerSdk
                      .logEvent('mm_text_img_clicked', {});
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const MyHomePage(title: 'Text To Image')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Image To Image'),
                onTap: () {
                  AppsflyerService()
                      .appsflyerSdk
                      .logEvent('mm_img_img_clicked', {});
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ImageToImagePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                    Icons.play_circle), // You can change the icon as needed
                title: const Text('Image To Animation'),
                onTap: () {
                  AppsflyerService()
                      .appsflyerSdk
                      .logEvent('mm_img_ani_clicked', {});
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ToolsPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_aspect_ratio),
                title: const Text('Image Upscaler'),
                onTap: () {
                  AppsflyerService()
                      .appsflyerSdk
                      .logEvent('mm_img_upscale_clicked', {});
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ImageUpscalerPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                    Icons.collections), // You can change the icon as needed
                title: const Text('Get Inspired'),
                onTap: () {
                  AppsflyerService()
                      .appsflyerSdk
                      .logEvent('mm_get_inspired_clicked', {});
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PortfolioPage()),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.star), // You can change the icon as needed
                title: const Text('Rate App'),
                onTap: () async {
                  AppsflyerService()
                      .appsflyerSdk
                      .logEvent('mm_rate_app_clicked', {});
                  final Uri url = Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.ai.wizardai');
                  if (await canLaunch(url.toString())) {
                    await launch(url.toString());
                  } else {
                    throw 'Could not launch $url';
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                    Icons.contact_mail), // You can change the icon as needed
                title: const Text('Contact Us'),
                onTap: () async {
                  AppsflyerService()
                      .appsflyerSdk
                      .logEvent('mm_contprivacy loact_clicked', {});
                  final Uri url = Uri.parse('mailto:mailus@lifinancetech.com');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Night Mode'),
                secondary: const Icon(Icons.nights_stay),
                value: context.watch<ThemeProvider>().isNightMode,
                onChanged: (bool value) {
                  context.read<ThemeProvider>().toggleNightMode();
                },
              )
            ],
          ),
        ),
      ),
      body: widget.body,
    );
  }
}
