import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/apphud_models/composite/apphud_purchase_result.dart';

class ApphudService {
  ApphudService._();

  static final ApphudService instance = ApphudService._();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await Apphud.start(apiKey: 'app_Z44sHCCXqhP5FCBDa8SxKBLB7VLpga');
    _isInitialized = true;
  }

  Future<bool> hasActiveSubscription() async {
    await init();
    return Apphud.hasActiveSubscription();
  }

  Future<List<ApphudProduct>> getMainPaywallProducts() async {
    await init();
    final ApphudPaywalls wrapper = await Apphud.paywallsDidLoadCallback();
    final paywalls = wrapper.paywalls;
    if (paywalls.isEmpty) {
      return <ApphudProduct>[];
    }
    final main = paywalls.firstWhere(
      (w) => w.identifier == 'main_paywall',
      orElse: () => paywalls.first,
    );
    return main.products ?? <ApphudProduct>[];
  }

  Future<ApphudPurchaseResult> purchaseProduct(ApphudProduct product) async {
    await init();
    final result = await Apphud.purchase(product: product);
    return result;
  }

  Future<void> restorePurchases() async {
    await init();
    await Apphud.restorePurchases();
  }
}

