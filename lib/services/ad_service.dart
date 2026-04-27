import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// ─── IDs publicitaires ────────────────────────────────────────────────────────
/// Remplacer les XXXXXXXXXX par les vraies IDs créées sur admob.google.com
/// après avoir ajouté l'app My Trélazé dans ta console AdMob.
///
/// Format App ID   : ca-app-pub-7019794645844062~XXXXXXXXXX
/// Format Unit ID  : ca-app-pub-7019794645844062/XXXXXXXXXX
///
/// En attendant les vraies IDs, on utilise les IDs de TEST Google officiels.
class AdIds {
  // ── App IDs (à mettre aussi dans AndroidManifest.xml et Info.plist) ─────────
  static const String appIdAndroid = 'ca-app-pub-7019794645844062~7304265828';
  static const String appIdIos     = 'ca-app-pub-7019794645844062~XXXXXXXXXX'; // à remplir si iOS

  // ── Bannière ─────────────────────────────────────────────────────────────────
  // TEST → remplacer par ca-app-pub-7019794645844062/XXXXXXXXXX
  static String get bannerHome => Platform.isAndroid
      ? 'ca-app-pub-7019794645844062/7981781031'
      : 'ca-app-pub-3940256099942544/2934735716';  // ← TEST iOS (à remplacer si iOS)

  static String get bannerNews => Platform.isAndroid
      ? 'ca-app-pub-7019794645844062/8771072346'
      : 'ca-app-pub-3940256099942544/2934735716';  // ← TEST iOS (à remplacer si iOS)

  // ── Interstitiel (plein écran entre articles) ────────────────────────────────
  // TEST → remplacer par ca-app-pub-7019794645844062/XXXXXXXXXX
  static String get interstitial => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'   // ← TEST
      : 'ca-app-pub-3940256099942544/4411468910';  // ← TEST iOS
}

/// ─── Service AdMob ────────────────────────────────────────────────────────────
class AdService {
  static bool _initialized = false;
  static bool _adsEnabled = false;

  // AdBanner doit vérifier ce flag avant d'appeler BannerAd.load()
  // En debug/émulateur, false → AdMob ne se lance jamais → pas d'ANR WebView
  static bool get adsEnabled => _adsEnabled;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (kDebugMode) {
      // Skip AdMob in debug/emulator — WebView init (~145 MB) causes ANR on emulator
      return; // _adsEnabled reste false → AdBanner ne charge rien
    }
    await MobileAds.instance.initialize();
    _adsEnabled = true;
  }

  // ── Bannière ──────────────────────────────────────────────────────────────────
  static BannerAd createBanner({
    required String adUnitId,
    required void Function(Ad, LoadAdError) onFailed,
    required void Function(Ad) onLoaded,
  }) {
    return BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
    );
  }

  // ── Interstitiel ──────────────────────────────────────────────────────────────
  static Future<InterstitialAd?> loadInterstitial() async {
    InterstitialAd? ad;
    await InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (a) => ad = a,
        onAdFailedToLoad: (_) {},
      ),
    );
    return ad;
  }
}
