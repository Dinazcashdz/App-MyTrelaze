import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Bannière AdMob 320×50 — s'affiche seulement quand le chargement réussit.
class AdBanner extends StatefulWidget {
  final String adUnitId;
  const AdBanner({super.key, required this.adUnitId});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!AdService.adsEnabled) return; // bloque le chargement en debug/émulateur
    _ad = AdService.createBanner(
      adUnitId: widget.adUnitId,
      onLoaded: (ad) {
        if (mounted) setState(() => _loaded = true);
      },
      onFailed: (ad, error) {
        ad.dispose();
        if (mounted) setState(() => _loaded = false);
      },
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
