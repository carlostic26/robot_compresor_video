import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  // Cambiar a true para usar IDs de produccion en pruebas locales.
  static bool isProd = true;

  static bool _initialized = false;
  static bool _isShowingAppOpenAd = false;

  static bool get shouldLoadAds {
    final adsEnabled =
        (dotenv.env['ads_enabled'] ?? 'true').toLowerCase() != 'false';
    return adsEnabled && !const bool.fromEnvironment('flutter.test');
  }

  static RewardedAd? _rewardedAd;
  static InterstitialAd? _interstitialAd;
  static AppOpenAd? _appOpenAd;

  static String get bannerUnitId {
    if (!shouldLoadAds) return '';
    return _shouldUseProdAds
        ? dotenv.env['banner_prod'] ?? ''
        : dotenv.env['banner_test'] ?? '';
  }

  static String get interstitialUnitId {
    if (!shouldLoadAds) return '';
    return _shouldUseProdAds
        ? dotenv.env['interstitial_prod'] ?? ''
        : dotenv.env['interstitial_test'] ?? '';
  }

  static String get rewardedUnitId {
    if (!shouldLoadAds) return '';
    return _shouldUseProdAds
        ? dotenv.env['rewarded_prod'] ?? ''
        : dotenv.env['rewarded_test'] ?? '';
  }

  static String get appOpenUnitId {
    if (!shouldLoadAds) return '';
    return _shouldUseProdAds
        ? dotenv.env['app_open_prod'] ?? ''
        : dotenv.env['app_open_test'] ?? '';
  }

  static bool get _shouldUseProdAds {
    return _isProduction || isProd;
  }

  static bool get _isProduction {
    return const bool.fromEnvironment('dart.vm.product');
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!shouldLoadAds) return;

    await MobileAds.instance.initialize();

    _loadInterstitialAd();
    _loadRewardedAd();
    _loadAppOpenAd();
  }

  static Future<void> initializeAndLoadAppOpenAd({
    bool showOnLoad = true,
  }) async {
    await initialize();
    _loadAppOpenAd(showOnLoad: showOnLoad);
  }

  static void _loadInterstitialAd() {
    final adUnitId = interstitialUnitId;
    if (adUnitId.isEmpty) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  static void _loadRewardedAd() {
    final adUnitId = rewardedUnitId;
    if (adUnitId.isEmpty) return;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  static void _loadAppOpenAd({bool showOnLoad = false}) {
    final adUnitId = appOpenUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('AppOpenAd unit ID is empty. Skipping load.');
      return;
    }

    debugPrint('Loading AppOpenAd with unit ID: $adUnitId');
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      orientation: AppOpenAd.orientationPortrait,
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd?.dispose();
          _appOpenAd = ad;
          debugPrint('AppOpenAd loaded successfully.');
          if (showOnLoad) {
            unawaited(showAppOpenAd());
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  static Future<void> showInterstitialAd() async {
    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('No interstitial ad ready');
      _loadInterstitialAd();
      return;
    }

    final completer = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        debugPrint('InterstitialAd failed to show: $error');
        if (!completer.isCompleted) completer.complete();
      },
    );

    ad.show();

    await completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        return;
      },
    );
  }

  static Future<bool> showRewardedAd() async {
    final ad = _rewardedAd;
    if (ad == null) {
      debugPrint('No rewarded ad ready');
      return false;
    }

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
        debugPrint('RewardedAd failed to show: $error');
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) {
      if (!completer.isCompleted) completer.complete(true);
    });

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        return false;
      },
    );
  }

  static Future<void> showAppOpenAd() async {
    if (_isShowingAppOpenAd) return;

    final ad = _appOpenAd;
    if (ad == null) {
      debugPrint('No AppOpenAd ready');
      return;
    }

    _isShowingAppOpenAd = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _isShowingAppOpenAd = false;
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        _isShowingAppOpenAd = false;
        _loadAppOpenAd();
        debugPrint('AppOpenAd failed to show: $error');
      },
    );

    ad.show();
  }
}
