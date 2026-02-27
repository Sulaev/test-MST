import 'dart:ui';

import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ui/app_colors.dart';
import '../../services/apphud_service.dart';

/// Матовое белое стекло как на главном экране (BackdropFilter + белая подложка).
class _PaywallGlass extends StatelessWidget {
  const _PaywallGlass({
    required this.radius,
    required this.child,
    this.blurSigma = 18,
    this.tintOpacity = 0.75,
    this.borderOpacity = 0.22,
  });

  final double radius;
  final Widget child;
  final double blurSigma;
  final double tintOpacity;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(tintOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

final paywallProductsProvider =
    FutureProvider.autoDispose<List<ApphudProduct>>((ref) async {
  return ApphudService.instance.getMainPaywallProducts();
});

/// Тип плана для отображения (Weekly / Monthly / Yearly).
enum _PlanType { weekly, monthly, yearly }

extension _PlanTypeX on _PlanType {
  Color get color {
    switch (this) {
      case _PlanType.weekly:
        return AppColors.subscriptionWeekly;
      case _PlanType.monthly:
        return AppColors.subscriptionMonthly;
      case _PlanType.yearly:
        return AppColors.subscriptionYearly;
    }
  }

  String get badge {
    switch (this) {
      case _PlanType.weekly:
        return '3-day trial';
      case _PlanType.monthly:
        return '';
      case _PlanType.yearly:
        return 'Save 75%';
    }
  }

  String get label {
    switch (this) {
      case _PlanType.weekly:
        return 'Weekly';
      case _PlanType.monthly:
        return 'Monthly';
      case _PlanType.yearly:
        return 'Yearly';
    }
  }

  String formatPrice(String? price, String? currencyCode) {
    if (price == null || price.isEmpty) return '...';
    switch (this) {
      case _PlanType.weekly:
        return '\$$price / week';
      case _PlanType.monthly:
        return '\$$price / month';
      case _PlanType.yearly:
        return '\$$price / year';
    }
  }
}

/// Сопоставляет продукты Apphud с типами планов по productId (week/month/year) или по порядку.
List<({_PlanType type, ApphudProduct product})> _mapProducts(
    List<ApphudProduct> products) {
  final result = <({_PlanType type, ApphudProduct product})>[];
  final idLower = products.map((e) => e.productId.toLowerCase()).toList();
  for (var i = 0; i < products.length; i++) {
    final id = idLower[i];
    _PlanType type;
    if (id.contains('week')) {
      type = _PlanType.weekly;
    } else if (id.contains('month')) {
      type = _PlanType.monthly;
    } else if (id.contains('year')) {
      type = _PlanType.yearly;
    } else {
      type = i == 0
          ? _PlanType.weekly
          : i == 1
              ? _PlanType.monthly
              : _PlanType.yearly;
    }
    result.add((type: type, product: products[i]));
  }
  // Сортируем: weekly, monthly, yearly
  result.sort((a, b) => a.type.index.compareTo(b.type.index));
  return result;
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedIndex = 1; // по умолчанию Monthly

  static const _features = [
    'Personalized Sessions',
    'Sleep & Relaxation',
    'Focus & Energy',
    'Mindfulness Tracking',
    'Nature & Music Sounds',
  ];

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(paywallProductsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientMid,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildAppIcon(),
                          const SizedBox(height: 16),
                          Text(
                            'Unlock Full',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF111111),
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'AI Meditation Power',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111111),
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Unlimited guided sessions, personalized AI meditations, track your mindfulness.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF4A4A4A),
                              height: 24 / 16,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFeatures(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: productsAsync.when(
                          data: (products) {
                            if (products.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('No products configured'),
                              );
                            }
                            final mapped = _mapProducts(products);
                            return _PaywallGlass(
                              radius: 44,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  12,
                                  24,
                                  16,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...List.generate(mapped.length, (i) {
                                      final item = mapped[i];
                                      final sk = item.product.skProduct;
                                      final price = sk?.price?.toString();
                                      final currency =
                                          sk?.priceLocale.currencyCode;
                                      final priceText = item.type
                                          .formatPrice(price, currency);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        child: _PlanCard(
                                          planType: item.type,
                                          label: item.type.label,
                                          priceText: priceText,
                                          badge: item.type.badge,
                                          isSelected: _selectedIndex == i,
                                          onTap: () => setState(
                                              () => _selectedIndex = i),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 16),
                                    _NextButton(
                                      enabled: true,
                                      label: 'NEXT',
                                      onTap: () =>
                                          _onNext(context, ref, products),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          loading: () => const Center(
                              child: CircularProgressIndicator()),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('Error: $e'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/Image.png',
        height: 80,
        width: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: AppColors.subscriptionMonthly.withOpacity(0.3),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.spa, size: 40, color: Color(0xFF111111)),
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return _PaywallGlass(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _features.map((text) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF111111),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111111),
                        height: 24 / 16,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _onNext(
    BuildContext context,
    WidgetRef ref,
    List<ApphudProduct> products,
  ) async {
    if (products.isEmpty) return;
    final mapped = _mapProducts(products);
    if (_selectedIndex < 0 || _selectedIndex >= mapped.length) return;
    final product = mapped[_selectedIndex].product;

    try {
      final result =
          await ApphudService.instance.purchaseProduct(product);
      if (!context.mounted) return;
      if (result.error == null) {
        Navigator.of(context).pop(true);
      } else {
        final message = result.error!.message ?? 'Purchase failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.planType,
    required this.label,
    required this.priceText,
    required this.badge,
    required this.isSelected,
    required this.onTap,
  });

  final _PlanType planType;
  final String label;
  final String priceText;
  final String badge;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = planType.color;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.only(
            top: 6,
            bottom: 6,
            left: 20,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(color: color, width: 3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          priceText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4A4A4A),
                          ),
                        ),
                        if (badge.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF111111)
                        : const Color(0xFFB9BCC4),
                    width: 2,
                  ),
                  color: isSelected ? const Color(0xFF111111) : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
    final fg = enabled ? Colors.white : const Color(0xFFB9BCC4);
    final arrowBg = enabled
        ? const Color(0xFFF6F7FA).withOpacity(0.08)
        : const Color(0xFFF6F7FA);
    final arrowFg = enabled ? Colors.white : const Color(0xFFB9BCC4);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
          border: enabled
              ? null
              : Border.all(color: const Color(0xFF111111).withOpacity(0.06)),
        ),
        padding: const EdgeInsets.only(left: 10, right: 4),
        child: Row(
          children: [
            const SizedBox(width: 56),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: -1,
                ),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: arrowBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward,
                color: arrowFg,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
