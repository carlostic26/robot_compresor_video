import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  /// `true` para IDs de producción, o `false` para IDs de prueba.
  static bool isProd = true;

  static bool _initialized = false;
  static bool _isShowingFullScreenAd = false;
  static DateTime? _lastAdDismissedTime;
  static AppLifecycleListener? _appLifecycleListener;

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

  static Completer<InterstitialAd?>? _interstitialLoadCompleter;
  static Completer<AppOpenAd?>? _appOpenLoadCompleter;
  static Completer<RewardedAd?>? _rewardedLoadCompleter;

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

    // Habilitar anuncios de prueba en emuladores y dispositivo físico
    final configuration = RequestConfiguration(
      testDeviceIds: <String>['EMULATOR', '92C3D2A309B4B67DE67A5F10A13F1F43'],
    );
    await MobileAds.instance.updateRequestConfiguration(configuration);

    debugPrint(
      'AdService initialized. Mode: ${isProd ? "PRODUCCIÓN" : "TEST / PRUEBA"}',
    );

    _startAppLifecycleReactor();

    // Precargar anuncios en paralelo desde el arranque
    _loadInterstitialAd();
    _loadRewardedAd();
    _loadAppOpenAd();
  }

  static void _startAppLifecycleReactor() {
    _appLifecycleListener?.dispose();
    _appLifecycleListener = AppLifecycleListener(
      onResume: () {
        debugPrint('AdService: onResume -> intentando mostrar AppOpenAd');
        unawaited(showAppOpenAd());
      },
    );
  }

  static Future<void> initializeAndLoadAppOpenAd({
    bool showOnLoad = true,
  }) async {
    await initialize();
    if (showOnLoad) {
      await showAppOpenAd();
    }
  }

  static int _interstitialAttempts = 0;
  static const int _maxAttempts = 3;

  static void _loadInterstitialAd() {
    final adUnitId = interstitialUnitId;
    if (adUnitId.isEmpty) return;
    if (_interstitialAd != null) return;
    if (_interstitialLoadCompleter != null &&
        !_interstitialLoadCompleter!.isCompleted) {
      return;
    }

    _interstitialLoadCompleter = Completer<InterstitialAd?>();
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
          if (_interstitialLoadCompleter != null &&
              !_interstitialLoadCompleter!.isCompleted) {
            _interstitialLoadCompleter!.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAttempts++;
          _interstitialAd = null;
          if (_interstitialLoadCompleter != null &&
              !_interstitialLoadCompleter!.isCompleted) {
            _interstitialLoadCompleter!.complete(null);
          }
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
    if (_rewardedAd != null) return;
    if (_rewardedLoadCompleter != null &&
        !_rewardedLoadCompleter!.isCompleted) {
      return;
    }

    _rewardedLoadCompleter = Completer<RewardedAd?>();
    debugPrint('Loading RewardedAd ($adUnitId)...');
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          debugPrint('RewardedAd loaded successfully.');
          if (_rewardedLoadCompleter != null &&
              !_rewardedLoadCompleter!.isCompleted) {
            _rewardedLoadCompleter!.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load (code ${error.code}): $error');
          _rewardedAd = null;
          if (_rewardedLoadCompleter != null &&
              !_rewardedLoadCompleter!.isCompleted) {
            _rewardedLoadCompleter!.complete(null);
          }
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
    if (_appOpenAd != null) return;
    if (_appOpenLoadCompleter != null && !_appOpenLoadCompleter!.isCompleted) {
      return;
    }

    _appOpenLoadCompleter = Completer<AppOpenAd?>();
    debugPrint('Loading AppOpenAd ($adUnitId)...');
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd?.dispose();
          _appOpenAd = ad;
          debugPrint('AppOpenAd loaded successfully.');
          if (_appOpenLoadCompleter != null &&
              !_appOpenLoadCompleter!.isCompleted) {
            _appOpenLoadCompleter!.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load (code ${error.code}): $error');
          _appOpenAd = null;
          if (_appOpenLoadCompleter != null &&
              !_appOpenLoadCompleter!.isCompleted) {
            _appOpenLoadCompleter!.complete(null);
          }
        },
      ),
    );
  }

  static Future<void> showInterstitialAd({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_isShowingFullScreenAd) {
      debugPrint(
        'Another full screen ad is already showing. Skipping interstitial.',
      );
      return;
    }

    if (!shouldLoadAds) return;

    if (_interstitialAd == null) {
      if (_interstitialLoadCompleter != null &&
          !_interstitialLoadCompleter!.isCompleted) {
        debugPrint(
          'InterstitialAd is currently loading. Awaiting (timeout: ${timeout.inSeconds}s)...',
        );
        try {
          await _interstitialLoadCompleter!.future.timeout(
            timeout,
            onTimeout: () {
              debugPrint('Awaiting InterstitialAd load timed out.');
              return null;
            },
          );
        } catch (e) {
          debugPrint('Error awaiting InterstitialAd: $e');
        }
      } else {
        _loadInterstitialAd();
      }
    }

    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('InterstitialAd not available to show.');
      return;
    }

    if (_isShowingFullScreenAd) return;

    _isShowingFullScreenAd = true;
    _interstitialAd = null;

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (adInstance) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        _lastAdDismissedTime = DateTime.now();
        _loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        _lastAdDismissedTime = DateTime.now();
        _loadInterstitialAd();
        debugPrint('InterstitialAd failed to show: $error');
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      ad.show();
    } catch (error) {
      ad.dispose();
      _isShowingFullScreenAd = false;
      _lastAdDismissedTime = DateTime.now();
      _loadInterstitialAd();
      debugPrint('InterstitialAd show exception: $error');
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('InterstitialAd presentation timed out');
      },
    );
  }

  static Future<bool> showRewardedAd({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_isShowingFullScreenAd) return false;
    if (!shouldLoadAds) return false;

    if (_rewardedAd == null) {
      if (_rewardedLoadCompleter != null &&
          !_rewardedLoadCompleter!.isCompleted) {
        debugPrint(
          'RewardedAd is currently loading. Awaiting (timeout: ${timeout.inSeconds}s)...',
        );
        try {
          await _rewardedLoadCompleter!.future.timeout(
            timeout,
            onTimeout: () {
              debugPrint('Awaiting RewardedAd load timed out.');
              return null;
            },
          );
        } catch (e) {
          debugPrint('Error awaiting RewardedAd: $e');
        }
      } else {
        _loadRewardedAd();
      }
    }

    final ad = _rewardedAd;
    if (ad == null) {
      debugPrint('No rewarded ad ready');
      return false;
    }

    _isShowingFullScreenAd = true;
    _rewardedAd = null;

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (adInstance) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        _lastAdDismissedTime = DateTime.now();
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        _lastAdDismissedTime = DateTime.now();
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
        debugPrint('RewardedAd failed to show: $error');
      },
    );

    ad.show(
      onUserEarnedReward: (adInstance, reward) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _isShowingFullScreenAd = false;
        return false;
      },
    );
  }

  static Future<void> showAppOpenAd({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (_isShowingFullScreenAd) {
      debugPrint('A full screen ad is already showing. Skipping AppOpenAd.');
      return;
    }

    if (!shouldLoadAds) return;

    if (_lastAdDismissedTime != null) {
      final elapsed = DateTime.now().difference(_lastAdDismissedTime!);
      if (elapsed < const Duration(seconds: 5)) {
        debugPrint('AppOpenAd skipped due to cooldown ($elapsed elapsed).');
        return;
      }
    }

    if (_appOpenAd == null) {
      if (_appOpenLoadCompleter != null &&
          !_appOpenLoadCompleter!.isCompleted) {
        debugPrint(
          'AppOpenAd is loading. Awaiting (timeout: ${timeout.inSeconds}s)...',
        );
        try {
          await _appOpenLoadCompleter!.future.timeout(
            timeout,
            onTimeout: () {
              debugPrint('Awaiting AppOpenAd load timed out.');
              return null;
            },
          );
        } catch (e) {
          debugPrint('Error awaiting AppOpenAd: $e');
        }
      } else {
        _loadAppOpenAd();
      }
    }

    final ad = _appOpenAd;
    if (ad == null) {
      debugPrint('AppOpenAd not available to show.');
      return;
    }

    if (_isShowingFullScreenAd) return;

    _isShowingFullScreenAd = true;
    _appOpenAd = null;

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (adInstance) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        _lastAdDismissedTime = DateTime.now();
        _loadAppOpenAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        _lastAdDismissedTime = DateTime.now();
        _loadAppOpenAd();
        debugPrint('AppOpenAd failed to show: $error');
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      ad.show();
    } catch (error, stackTrace) {
      ad.dispose();
      _isShowingFullScreenAd = false;
      _lastAdDismissedTime = DateTime.now();
      _loadAppOpenAd();
      debugPrint('AppOpenAd show failed: $error');
      debugPrint('$stackTrace');
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('AppOpenAd presentation timed out');
      },
    );
  }
}
