// appsflyer_service.dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

class AppsflyerService {
  static final AppsflyerService _singleton = AppsflyerService._internal();

  late AppsflyerSdk _appsflyerSdk;
  late Map _deepLinkData;
  late Map _gcd;

  factory AppsflyerService() {
    return _singleton;
  }

  AppsflyerService._internal() {
    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: "your_dev_key_here",
      appId: "com.ai.wizardai",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 5,
    );

    _appsflyerSdk = AppsflyerSdk(options);
    _appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
  }

  AppsflyerSdk get appsflyerSdk => _appsflyerSdk;
  Map get deepLinkData => _deepLinkData;
  Map get gcd => _gcd;
}
