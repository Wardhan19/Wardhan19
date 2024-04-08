import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'welcome_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'theme_provider.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:user_messaging_platform/user_messaging_platform.dart' as cons;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:ai_imagez/revcat_sdk.dart';
import 'appsflyer_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Create an instance of FlutterSecureStorage
    const storage = FlutterSecureStorage();
    await storage.write(
        key: 'api_key',
        value: 'sk-oargDlbiUZ4Ygnqyar1vs8mZLcIAasWt0spn3sGqugyuTlzk');

    try {
      await configureSDK();
    } catch (e) {
      print('ADLOG: Error in _configureSDK: $e');
    }

    runApp(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

    AppsflyerService();

    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      print('ADLOG: Customer info fetched');
      print('ADLOG: All entitlements: ${customerInfo.entitlements.all}');
      print(
          'ADLOG: remove_ads entitlement exists: ${customerInfo.entitlements.all.containsKey('remove_ads')}');
      print(
          'ADLOG: All purchased product identifiers: ${customerInfo.allPurchasedProductIdentifiers}');
    } catch (e) {
      print('ADLOG: Error fetching customer info: $e');
    }
  }, (error, stackTrace) {
    print('Caught an exception: $error');
    print('Stack trace: $stackTrace');
  });
}

Future<void> showPaywall() async {
  print(
      'ADLOG: User does not have an active subscription. Presenting paywall.');
  final paywallResult = await RevenueCatUI.presentPaywallIfNeeded("remove_ads");
  print('Paywall result: $paywallResult');
}

void updateConsent() async {
  // Make sure to continue with the latest consent info.
  var info =
      await cons.UserMessagingPlatform.instance.requestConsentInfoUpdate();

  // Show the consent form if consent is required.
  if (info.consentStatus == cons.ConsentStatus.required) {
    // `showConsentForm` returns the latest consent info, after the consent from has been closed.
    info = await cons.UserMessagingPlatform.instance.showConsentForm();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BackButtonInterceptor.add(myInterceptor);
    // show paywall if user does not have an active subscription
    // showPaywall();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (Navigator.of(context).canPop()) {
      // Check if there's a route to pop
      Navigator.of(context).pop();
    } else {
      // Handle the case where there's no route to pop
      print('No route to pop');
    }
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      print('App is in the background');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      theme: themeProvider.isNightMode
          ? ThemeData.dark().copyWith(
              textTheme: GoogleFonts.montserratAlternatesTextTheme(
                Theme.of(context).textTheme,
              ).copyWith(
                labelLarge:
                    const TextStyle(color: Colors.white), // Button text color
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button background color
                  foregroundColor: Colors.white, // Button text color
                ),
              ),
            )
          : ThemeData(
              textTheme: GoogleFonts.montserratAlternatesTextTheme(
                Theme.of(context).textTheme,
              ).copyWith(
                labelLarge:
                    const TextStyle(color: Colors.white), // Button text color
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button background color
                  foregroundColor: Colors.white, // Button text color
                ),
              ),
            ),
      home: const WelcomeScreen(),
    );
  }
}
