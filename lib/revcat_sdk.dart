import 'package:purchases_flutter/purchases_flutter.dart';

const googleApiKey = 'goog_pQRqXyyklgZhIYHNxZglFIGHQZJ';

Future<void> configureSDK() async {
  try {
    // Enable debug logs before calling `configure`.
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration = PurchasesConfiguration(googleApiKey)
      ..appUserID = null
      ..observerMode = false;

    await Purchases.configure(configuration);

    // Check subscription status
    CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    print('ADLOG: Customer info fetched');
    print('ADLOG: All entitlements: ${customerInfo.entitlements.all}'); // Print all entitlements
    print('ADLOG: remove_ads entitlement exists: ${customerInfo.entitlements.all.containsKey('remove_ads')}');
    if (customerInfo.entitlements.all.containsKey('remove_ads')) {
      print('ADLOG: remove_ads entitlement is active: ${customerInfo.entitlements.all['remove_ads']!.isActive}');
    }
    // Check product purchase status
    print('ADLOG: All purchased product identifiers: ${customerInfo.allPurchasedProductIdentifiers}'); // Print all purchased product identifiers

    if (!customerInfo.entitlements.all.containsKey('remove_ads') || 
        !customerInfo.entitlements.all['remove_ads']!.isActive) { 

      print('ADLOG: User does not have an active subscription');
    }
  } catch (e) {
    print('ADLOG1: Error in _configureSDK: $e');
  }
}
