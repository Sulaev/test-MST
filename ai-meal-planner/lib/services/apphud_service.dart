import 'package:apphud/apphud.dart';
import 'package:flutter/foundation.dart';
import 'package:apphud/models/apphud_models/android/android_purchase_wrapper.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_data.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_provider.dart';
import 'package:apphud/models/apphud_models/apphud_non_renewing_purchase.dart';
import 'package:apphud/models/apphud_models/apphud_placement.dart';
import 'package:apphud/models/apphud_models/apphud_placements.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/apphud_subscription.dart';
import 'package:apphud/models/apphud_models/apphud_user.dart';
import 'package:apphud/models/apphud_models/composite/apphud_product_composite.dart';
import 'package:apphud/models/apphud_models/composite/apphud_purchase_result.dart';

import '../config/app_config.dart';

class ApphudState {
  const ApphudState({
    required this.isInitialized,
    required this.hasActiveSubscription,
    required this.products,
    required this.isLoading,
    this.lastError,
  });

  const ApphudState.initial()
      : isInitialized = false,
        hasActiveSubscription = false,
        products = const <ApphudProduct>[],
        isLoading = false,
        lastError = null;

  final bool isInitialized;
  final bool hasActiveSubscription;
  final List<ApphudProduct> products;
  final bool isLoading;
  final String? lastError;

  ApphudState copyWith({
    bool? isInitialized,
    bool? hasActiveSubscription,
    List<ApphudProduct>? products,
    bool? isLoading,
    String? lastError,
  }) {
    return ApphudState(
      isInitialized: isInitialized ?? this.isInitialized,
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      lastError: lastError,
    );
  }
}

class ApphudService implements ApphudListener {
  final ValueNotifier<ApphudState> state = ValueNotifier<ApphudState>(
    const ApphudState.initial(),
  );

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AppHud] $message');
    }
  }

  Future<void> initialize(AppConfig config) async {
    _log(
      'initialize: apiKeyLen=${config.apphudApiKey.trim().length}, '
      'placementId=${config.apphudPlacementId.trim().isEmpty ? '<empty>' : config.apphudPlacementId.trim()}, '
      'paywallId=${config.apphudPaywallId.trim().isEmpty ? '<empty>' : config.apphudPaywallId.trim()}',
    );
    if (config.apphudApiKey.trim().isEmpty) {
      state.value = state.value.copyWith(
        lastError: 'AppHud API key is not configured',
      );
      _log('initialize: api key missing');
      return;
    }
    state.value = state.value.copyWith(isLoading: true, lastError: null);
    try {
      await Apphud.start(apiKey: config.apphudApiKey.trim());
      _log('start: ok');
      await Apphud.setListener(listener: this);
      _log('listener: attached');
      state.value = state.value.copyWith(
        isInitialized: true,
      );
      await refresh(config);
      state.value = state.value.copyWith(
        isLoading: false,
        lastError: state.value.lastError,
      );
      _log(
        'initialize done: isInitialized=${state.value.isInitialized}, '
        'products=${state.value.products.length}, active=${state.value.hasActiveSubscription}, '
        'lastError=${state.value.lastError ?? '<none>'}',
      );
    } catch (error) {
      final String errorMsg = error.toString();
      String userFriendlyError = errorMsg;
      if (errorMsg.contains('403') || errorMsg.contains('Access forbidden') || errorMsg.contains('authorization')) {
        userFriendlyError = 'AppHud API key is invalid or inactive. Please check your API key in AppHud dashboard.';
      } else if (errorMsg.contains('timeout')) {
        userFriendlyError = 'AppHud connection timeout. Please check your internet connection.';
      }
      state.value = state.value.copyWith(
        isInitialized: false,
        isLoading: false,
        lastError: userFriendlyError,
      );
      _log('initialize failed: $errorMsg');
    }
  }

  Future<void> refresh(AppConfig config) async {
    try {
      final List<ApphudPlacement> placements = await Apphud.placements();
      _log('refresh: placements=${placements.length}');
      if (kDebugMode && placements.isNotEmpty) {
        final String ids = placements
            .map((ApphudPlacement p) => '${p.identifier}|${p.paywall?.identifier ?? '-'}')
            .join(', ');
        _log('refresh: placement|paywall ids => $ids');
      }
      ApphudPlacement? placement = _pickPlacement(placements, config);
      _log(
        'refresh: selected placement=${placement?.identifier ?? '<none>'}, '
        'paywall=${placement?.paywall?.identifier ?? '<none>'}',
      );
      List<ApphudProduct> products = placement?.paywall?.products ?? <ApphudProduct>[];
      if (products.isEmpty) {
        final ApphudPlacements refreshed = await Apphud.fetchPlacements(forceRefresh: true);
        _log('refresh: forceRefresh placements=${refreshed.placements.length}');
        placement = _pickPlacement(refreshed.placements, config);
        products = placement?.paywall?.products ?? <ApphudProduct>[];
      }
      if (kDebugMode && products.isNotEmpty) {
        _log('refresh: products=${products.map((ApphudProduct p) => p.productId).join(', ')}');
      } else {
        _log('refresh: products=0');
      }
      final bool hasActiveSubscription = await Apphud.hasActiveSubscription();
      state.value = state.value.copyWith(
        products: products,
        hasActiveSubscription: hasActiveSubscription,
        lastError: null,
      );
    } catch (error) {
      final String errorMsg = error.toString();
      String userFriendlyError = errorMsg;
      if (errorMsg.contains('403') || errorMsg.contains('Access forbidden') || errorMsg.contains('authorization')) {
        userFriendlyError = 'AppHud authorization failed. Please check your API key.';
      }
      state.value = state.value.copyWith(lastError: userFriendlyError);
      _log('refresh failed: $errorMsg');
    }
  }

  Future<String?> purchase(ApphudProduct product, AppConfig config) async {
    try {
      state.value = state.value.copyWith(isLoading: true);
      final ApphudPurchaseResult result = await Apphud.purchase(product: product);
      await refresh(config);
      state.value = state.value.copyWith(isLoading: false);
      return result.error?.message;
    } catch (error) {
      state.value = state.value.copyWith(
        isLoading: false,
        lastError: error.toString(),
      );
      return error.toString();
    }
  }

  Future<String?> restore(AppConfig config) async {
    try {
      state.value = state.value.copyWith(isLoading: true);
      await Apphud.restorePurchases();
      await refresh(config);
      state.value = state.value.copyWith(isLoading: false);
      return null;
    } catch (error) {
      state.value = state.value.copyWith(
        isLoading: false,
        lastError: error.toString(),
      );
      return error.toString();
    }
  }

  Future<void> submitAppsFlyerAttribution({
    required Map<String, dynamic> conversionData,
    String? appsFlyerUid,
  }) async {
    if (conversionData.isEmpty) {
      return;
    }
    try {
      await Apphud.setAttribution(
        provider: ApphudAttributionProvider.appsFlyer,
        data: ApphudAttributionData(rawData: conversionData),
        identifier: appsFlyerUid,
      );
    } catch (_) {
      // Attribution forwarding is best-effort.
    }
  }

  Future<void> submitFirebaseAttribution(Map<String, dynamic> firebaseData) async {
    if (firebaseData.isEmpty) {
      return;
    }
    try {
      await Apphud.setAttribution(
        provider: ApphudAttributionProvider.firebase,
        data: ApphudAttributionData(rawData: firebaseData),
      );
    } catch (_) {
      // Attribution forwarding is best-effort.
    }
  }

  Future<void> submitAppleSearchAdsAttribution() async {
    try {
      final Map<String, dynamic>? data = await Apphud.collectSearchAdsAttribution();
      if (data == null || data.isEmpty) {
        return;
      }
      await Apphud.setAttribution(
        provider: ApphudAttributionProvider.appleAdsAttribution,
        data: ApphudAttributionData(rawData: data),
      );
    } catch (_) {
      // Attribution forwarding is best-effort.
    }
  }

  ApphudPlacement? _pickPlacement(List<ApphudPlacement> placements, AppConfig config) {
    if (placements.isEmpty) {
      return null;
    }
    if (config.apphudPlacementId.trim().isNotEmpty) {
      for (final ApphudPlacement placement in placements) {
        if (placement.identifier == config.apphudPlacementId.trim()) {
          return placement;
        }
      }
    }
    if (config.apphudPaywallId.trim().isNotEmpty) {
      for (final ApphudPlacement placement in placements) {
        if (placement.paywall?.identifier == config.apphudPaywallId.trim()) {
          return placement;
        }
      }
    }
    return placements.first;
  }

  Future<void> dispose() async {
    await Apphud.setListener();
    state.dispose();
  }

  @override
  Future<void> apphudDidChangeUserID(String userId) async {}

  @override
  Future<void> apphudDidFecthProducts(List<ApphudProductComposite> products) async {}

  @override
  Future<void> apphudDidReceivePurchase(AndroidPurchaseWrapper purchase) async {}

  @override
  Future<void> apphudNonRenewingPurchasesUpdated(
    List<ApphudNonRenewingPurchase> purchases,
  ) async {}

  @override
  Future<void> apphudSubscriptionsUpdated(
    List<ApphudSubscriptionWrapper> subscriptions,
  ) async {
    try {
      final bool active = await Apphud.hasActiveSubscription();
      state.value = state.value.copyWith(hasActiveSubscription: active);
    } catch (_) {
      // Ignore callback failures; next refresh will recover state.
    }
  }

  @override
  Future<void> paywallsDidFullyLoad(ApphudPaywalls paywalls) async {}

  @override
  Future<void> placementsDidFullyLoad(List<ApphudPlacement> placements) async {
    if (placements.isEmpty) {
      return;
    }
    state.value = state.value.copyWith(
      products: placements.first.paywall?.products ?? <ApphudProduct>[],
    );
  }

  @override
  Future<void> userDidLoad(ApphudUser user) async {}
}
