import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  /// `true` para IDs de producción, o `false` para IDs de prueba.
  static bool isProd = false;

  static bool _initialized = false;
  static bool _isShowingAppOpenAd = false;
  static bool _isLoadingAppOpenAd = false;

  // IDs de prueba de ads para Android
  static const String _defaultTestBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _defaultTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _defaultTestRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _defaultTestAppOpenId =
      'ca-app-pub-3940256099942544/9257395921';

  static bool get shouldLoadAds {
    final adsEnabled =
        (dotenv.isInitialized ? (dotenv.env['ads_enabled'] ?? 'true') : 'true')
            .toLowerCase() !=
        'false';
    final isTest =
        const bool.fromEnvironment('flutter.test') ||
        Platform.environment.containsKey('FLUTTER_TEST');
    return adsEnabled && !isTest;
  }

  static RewardedAd? _rewardedAd;
  static InterstitialAd? _interstitialAd;
  static AppOpenAd? _appOpenAd;

  static String get bannerUnitId {
    if (!shouldLoadAds) return '';
    if (_shouldUseProdAds) {
      return (dotenv.isInitialized ? dotenv.env['banner_prod'] : null) ?? '';
    }
    final testId = dotenv.isInitialized ? dotenv.env['banner_test'] : null;
    return (testId != null && testId.isNotEmpty)
        ? testId
        : _defaultTestBannerId;
  }

  static String get interstitialUnitId {
    if (!shouldLoadAds) return '';
    if (_shouldUseProdAds) {
      return (dotenv.isInitialized ? dotenv.env['interstitial_prod'] : null) ??
          '';
    }
    final testId = dotenv.isInitialized
        ? dotenv.env['interstitial_test']
        : null;
    return (testId != null && testId.isNotEmpty)
        ? testId
        : _defaultTestInterstitialId;
  }

  static String get rewardedUnitId {
    if (!shouldLoadAds) return '';
    if (_shouldUseProdAds) {
      return (dotenv.isInitialized ? dotenv.env['rewarded_prod'] : null) ?? '';
    }
    final testId = dotenv.isInitialized ? dotenv.env['rewarded_test'] : null;
    return (testId != null && testId.isNotEmpty)
        ? testId
        : _defaultTestRewardedId;
  }

  static String get appOpenUnitId {
    if (!shouldLoadAds) return '';
    if (_shouldUseProdAds) {
      return (dotenv.isInitialized ? dotenv.env['app_open_prod'] : null) ?? '';
    }
    final testId = dotenv.isInitialized ? dotenv.env['app_open_test'] : null;
    return (testId != null && testId.isNotEmpty)
        ? testId
        : _defaultTestAppOpenId;
  }

  static bool get _shouldUseProdAds {
    return isProd;
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!shouldLoadAds) return;

    await MobileAds.instance.initialize();

    // Habilitar anuncios de prueba en emuladores
    // Habilitar anuncios de prueba en emuladores y dispositivo físico
    final configuration = RequestConfiguration(
      testDeviceIds: <String>['EMULATOR', '92C3D2A309B4B67DE67A5F10A13F1F43'],
    );
    await MobileAds.instance.updateRequestConfiguration(configuration);

    debugPrint(
      'AdService initialized. Mode: ${isProd ? "PRODUCCIÓN" : "TEST / PRUEBA"}',
    );

    _loadInterstitialAd();
    _loadRewardedAd();
  }

  static Future<void> initializeAndLoadAppOpenAd({
    bool showOnLoad = true,
  }) async {
    await initialize();
    _loadAppOpenAd(showOnLoad: showOnLoad);
  }

  static int _interstitialAttempts = 0;
  static const int _maxAttempts = 3;

  static void _loadInterstitialAd() {
    final adUnitId = interstitialUnitId;
    if (adUnitId.isEmpty) return;

    debugPrint('Loading InterstitialAd ($adUnitId)...');
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          _interstitialAttempts = 0;
          debugPrint('InterstitialAd loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAttempts++;
          _interstitialAd = null;
          if (_interstitialAttempts <= _maxAttempts) {
            _loadInterstitialAd();
          }
        },
      ),
    );
  }

  static void _loadRewardedAd() {
    final adUnitId = rewardedUnitId;
    if (adUnitId.isEmpty) return;

    debugPrint('Loading RewardedAd ($adUnitId)...');
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          debugPrint('RewardedAd loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load (code ${error.code}): $error');
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
    if (_isLoadingAppOpenAd || _appOpenAd != null) return;

    _isLoadingAppOpenAd = true;

    debugPrint('Loading AppOpenAd ($adUnitId)...');
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingAppOpenAd = false;
          _appOpenAd?.dispose();
          _appOpenAd = ad;
          debugPrint('AppOpenAd loaded successfully.');
          if (showOnLoad) {
            unawaited(showAppOpenAd());
          }
        },
        onAdFailedToLoad: (error) {
          _isLoadingAppOpenAd = false;
          debugPrint('AppOpenAd failed to load (code ${error.code}): $error');
        },
      ),
    );
  }

  static Future<void> showInterstitialAd() async {
    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('Interstitial ad not ready, requesting load for next time.');
      _loadInterstitialAd();
      return;
    }

    final completer = Completer<void>();
    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (adInstance) {
        adInstance.dispose();
        _loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        _loadInterstitialAd();
        debugPrint('InterstitialAd failed to show: $error');
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      ad.show();
    } catch (error) {
      ad.dispose();
      _loadInterstitialAd();
      debugPrint('InterstitialAd show exception: $error');
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('InterstitialAd timed out');
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

    ad.show(
      onUserEarnedReward: (ad, reward) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );

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
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        _isShowingAppOpenAd = false;
        debugPrint('AppOpenAd failed to show: $error');
      },
    );

    try {
      await ad.show();
    } catch (error, stackTrace) {
      ad.dispose();
      if (identical(_appOpenAd, ad)) {
        _appOpenAd = null;
      }
      _isShowingAppOpenAd = false;
      debugPrint('AppOpenAd show failed: $error');
      debugPrint('$stackTrace');
    }
  }
}
