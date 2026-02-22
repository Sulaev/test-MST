import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/apphud_service.dart';
import '../services/appsflyer_service.dart';

class ProfileResult {
  const ProfileResult({
    required this.gender,
    required this.goal,
    required this.weight,
    required this.height,
    required this.languageCode,
  });

  final String gender;
  final String goal;
  final String weight;
  final String height;
  final String languageCode;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.initialGender,
    required this.initialGoal,
    required this.initialWeight,
    required this.initialHeight,
    required this.initialLanguageCode,
    required this.goalOptions,
    required this.goalLabel,
    required this.apphudStateListenable,
    required this.apphudHasConfig,
    required this.onPurchase,
    required this.onRestore,
    required this.appsflyerStateListenable,
    required this.attStatus,
    required this.achievements,
    this.onRefreshExternalServices,
  });

  final String initialGender;
  final String initialGoal;
  final String initialWeight;
  final String initialHeight;
  final String initialLanguageCode;

  final List<String> goalOptions;
  final String Function(String goal, AppLocalizations l10n) goalLabel;

  final ValueListenable<ApphudState> apphudStateListenable;
  final bool apphudHasConfig;
  final Future<void> Function(ApphudProduct product) onPurchase;
  final Future<void> Function() onRestore;

  final ValueListenable<AppsflyerState> appsflyerStateListenable;
  final String attStatus;

  final List<AchievementViewModel> achievements;
  final Future<void> Function()? onRefreshExternalServices;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _gender = widget.initialGender;
  late String _goal = widget.initialGoal;
  late String _language = widget.initialLanguageCode;

  late final TextEditingController _weightController =
      TextEditingController(text: widget.initialWeight);
  late final TextEditingController _heightController =
      TextEditingController(text: widget.initialHeight);

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    const String apphudKey = String.fromEnvironment('APPHUD_API_KEY', defaultValue: '');
    const String appsflyerKey = String.fromEnvironment('APPSFLYER_DEV_KEY', defaultValue: '');
    const bool enableExternalServices =
        bool.fromEnvironment('ENABLE_EXTERNAL_SERVICES', defaultValue: true);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: <Widget>[
          if (widget.onRefreshExternalServices != null)
            IconButton(
              tooltip: 'Refresh',
              onPressed: () async => widget.onRefreshExternalServices?.call(),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _SectionTitle(l10n.profileTitle),
            const SizedBox(height: 10),
            Text(l10n.profileGender, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'male', label: Text(l10n.profileGenderMale)),
                ButtonSegment<String>(value: 'female', label: Text(l10n.profileGenderFemale)),
                ButtonSegment<String>(value: 'other', label: Text(l10n.profileGenderOther)),
              ],
              selected: <String>{_gender},
              onSelectionChanged: (Set<String> selected) {
                setState(() {
                  _gender = selected.first;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.profileWeight,
                suffixText: l10n.profileKg,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.profileHeight,
                suffixText: l10n.profileCm,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _goal,
              decoration: InputDecoration(
                labelText: l10n.profileGoal,
                border: const OutlineInputBorder(),
              ),
              items: widget.goalOptions
                  .map(
                    (String g) => DropdownMenuItem<String>(
                      value: g,
                      child: Text(widget.goalLabel(g, l10n)),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _goal = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: InputDecoration(
                labelText: l10n.profileLanguage,
                border: const OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'system',
                  child: Text(l10n.profileLanguageSystem),
                ),
                DropdownMenuItem<String>(
                  value: 'en',
                  child: Text(l10n.languageEnglish),
                ),
                DropdownMenuItem<String>(
                  value: 'ru',
                  child: Text(l10n.languageRussian),
                ),
              ],
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _language = value;
                });
              },
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  ProfileResult(
                    gender: _gender,
                    goal: _goal,
                    weight: _weightController.text.trim(),
                    height: _heightController.text.trim(),
                    languageCode: _language,
                  ),
                );
              },
              child: Text(l10n.profileSave),
            ),
            const SizedBox(height: 18),
            _SectionTitle(l10n.achievementsTitle),
            const SizedBox(height: 8),
            ...widget.achievements.map(
              (AchievementViewModel item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AchievementCard(item: item),
              ),
            ),
            const SizedBox(height: 18),
            _SectionTitle(l10n.subscriptionTitle),
            const SizedBox(height: 8),
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'debug: ENABLE_EXTERNAL_SERVICES=$enableExternalServices, '
                  'APPHUD_API_KEY len=${apphudKey.length}, '
                  'APPSFLYER_DEV_KEY len=${appsflyerKey.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ValueListenableBuilder<ApphudState>(
              valueListenable: widget.apphudStateListenable,
              builder: (BuildContext context, ApphudState apphudState, Widget? child) {
                return _SubscriptionCard(
                  l10n: l10n,
                  hasConfig: apphudKey.trim().isNotEmpty,
                  state: apphudState,
                  onPurchase: widget.onPurchase,
                  onRestore: widget.onRestore,
                );
              },
            ),
            const SizedBox(height: 14),
            _SectionTitle(l10n.trackingTitle),
            const SizedBox(height: 8),
            ValueListenableBuilder<AppsflyerState>(
              valueListenable: widget.appsflyerStateListenable,
              builder: (BuildContext context, AppsflyerState appsflyerState, Widget? child) {
                return _TrackingCard(
                  l10n: l10n,
                  attStatus: widget.attStatus,
                  state: appsflyerState,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}

class AchievementViewModel {
  const AchievementViewModel({
    required this.title,
    required this.subtitle,
    required this.isUnlocked,
  });

  final String title;
  final String subtitle;
  final bool isUnlocked;
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});

  final AchievementViewModel item;

  @override
  Widget build(BuildContext context) {
    final Color bg = item.isUnlocked ? const Color(0xFFEAF7EE) : const Color(0xFFF2F4F6);
    final Color fg = item.isUnlocked ? const Color(0xFF2AA845) : const Color(0xFF9AA6A1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.isUnlocked ? const Color(0xFFBFE6C9) : const Color(0xFFE2E7E5)),
      ),
      child: Row(
        children: <Widget>[
          _TrophyBadge(color: fg, isUnlocked: item.isUnlocked),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Icon(
            item.isUnlocked ? Icons.check_circle : Icons.lock_outline,
            color: fg,
          ),
        ],
      ),
    );
  }

}

class _TrophyBadge extends StatelessWidget {
  const _TrophyBadge({required this.color, required this.isUnlocked});

  final Color color;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isUnlocked
              ? <Color>[const Color(0xFF2AA845), const Color(0xFF62BFA8)]
              : <Color>[const Color(0xFFB9C4BF), const Color(0xFF9AA6A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Icon(Icons.emoji_events, color: Colors.white, size: 22),
          Positioned(
            bottom: 8,
            right: 10,
            child: Icon(Icons.local_fire_department, color: Colors.white.withValues(alpha: 0.95), size: 12),
          ),
        ],
      ),
    );
  }

}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16));
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.l10n,
    required this.hasConfig,
    required this.state,
    required this.onPurchase,
    required this.onRestore,
  });

  final AppLocalizations l10n;
  final bool hasConfig;
  final ApphudState state;
  final Future<void> Function(ApphudProduct product) onPurchase;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!hasConfig)
          Text(
            l10n.subscriptionApiKeyMissing,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else ...<Widget>[
          Row(
            children: <Widget>[
              Icon(
                state.hasActiveSubscription ? Icons.verified : Icons.lock_open_outlined,
                color: state.hasActiveSubscription ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                state.hasActiveSubscription ? l10n.subscriptionActive : l10n.subscriptionInactive,
              ),
              const Spacer(),
              TextButton(
                onPressed: state.isLoading ? null : onRestore,
                child: Text(l10n.restorePurchases),
              ),
            ],
          ),
          if (state.lastError != null && state.lastError!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                state.lastError!,
                style: const TextStyle(color: Color(0xFFC24D5A)),
              ),
            ),
          if (state.products.isEmpty)
            Text(l10n.subscriptionNoProducts)
          else
            ...state.products.map(
              (ApphudProduct product) {
                final String? priceLabel = _priceLabel(product);
                final String subtitle = priceLabel == null
                    ? product.productId
                    : '${product.productId} • $priceLabel';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    product.name?.trim().isNotEmpty == true ? product.name! : product.productId,
                  ),
                  subtitle: Text(subtitle),
                  trailing: FilledButton(
                    onPressed: state.isLoading ? null : () => onPurchase(product),
                    child: Text(l10n.buy),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
  String? _priceLabel(ApphudProduct product) {
    final skProduct = product.skProduct;
    if (skProduct != null) {
      final String currencyCode = skProduct.priceLocale.currencyCode ?? '';
      final String price = skProduct.price.toStringAsFixed(2);
      return currencyCode.isEmpty ? price : '$price $currencyCode';
    }
    final details = product.productDetails;
    final oneTime = details?.oneTimePurchaseOfferDetails;
    if (oneTime != null) {
      return oneTime.formattedPrice;
    }
    final offers = details?.subscriptionOfferDetails;
    if (offers != null && offers.isNotEmpty && offers.first.pricingPhases.isNotEmpty) {
      return offers.first.pricingPhases.first.formattedPrice;
    }
    return null;
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.l10n,
    required this.attStatus,
    required this.state,
  });

  final AppLocalizations l10n;
  final String attStatus;
  final AppsflyerState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('${l10n.attStatus}: $attStatus'),
        const SizedBox(height: 4),
        Text(state.isStarted ? l10n.appsflyerStarted : l10n.appsflyerNotStarted),
        if (state.appsFlyerUid != null && state.appsFlyerUid!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text('${l10n.appsflyerUid}: ${state.appsFlyerUid}'),
        ],
        if (state.lastConversionData != null && state.lastConversionData!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            l10n.conversionDataReceived,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            state.lastConversionData!.entries
                .take(3)
                .map((MapEntry<String, dynamic> e) => '${e.key}: ${e.value}')
                .join(' | '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (state.lastError != null && state.lastError!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            state.lastError!,
            style: const TextStyle(color: Color(0xFFC24D5A)),
          ),
        ],
      ],
    );
  }
}

