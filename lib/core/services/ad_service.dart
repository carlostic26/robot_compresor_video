import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static bool _initialized = false;
  static RewardedAd? _rewardedAd;
  static InterstitialAd? _interstitialAd;
  static AppOpenAd? _appOpenAd;

  static String get bannerUnitId {
    return _isProduction
        ? dotenv.env['banner_prod'] ?? ''
        : dotenv.env['banner_test'] ?? '';
  }

  static String get interstitialUnitId {
    return _isProduction
        ? dotenv.env['interstitial_prod'] ?? ''
        : dotenv.env['interstitial_test'] ?? '';
  }

  static String get rewardedUnitId {
    return _isProduction
        ? dotenv.env['rewarded_prod'] ?? ''
        : dotenv.env['rewarded_test'] ?? '';
  }

  static String get appOpenUnitId {
    return _isProduction
        ? dotenv.env['app_open_prod'] ?? ''
        : dotenv.env['app_open_test'] ?? '';
  }

  static bool get _isProduction {
    return const bool.fromEnvironment('dart.vm.product');
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await MobileAds.instance.initialize();

    _loadInterstitialAd();
    _loadRewardedAd();
    _loadAppOpenAd();
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

  static void _loadAppOpenAd() {
    final adUnitId = appOpenUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('AppOpenAd unit ID is empty. Skipping load.');
      return;
    }

    debugPrint('Loading AppOpenAd with unit ID: $adUnitId');
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd?.dispose();
          _appOpenAd = ad;
          debugPrint('AppOpenAd loaded successfully.');
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
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        debugPrint('InterstitialAd failed to show: $error');
      },
    );

    await ad.show();
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
    final ad = _appOpenAd;
    if (ad == null) {
      debugPrint('No AppOpenAd ready');
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
        debugPrint('AppOpenAd failed to show: $error');
      },
    );

    await ad.show();
  }
}
