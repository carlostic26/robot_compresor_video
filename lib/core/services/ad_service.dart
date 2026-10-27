import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  /// `true` para IDs de producción, o `false` para IDs de prueba.
  static bool isProd = true;

  /// Tiempo de animación de LoadingScreen (y ventana principal de espera del AppOpenAd).
  static const Duration loadingScreenDuration = Duration(seconds: 7);

  /// Tiempo límite máximo (30s) desde que corre la app para mostrar el AppOpenAd.
  /// Si transcurren 30s sin mostrarse, se descarta el AppOpenAd y se habilitan los banners.
  static const Duration appOpenMaxWaitDuration = Duration(seconds: 30);

  /// Notificador global que indica si los banners tienen permitido cargarse y mostrarse.
  /// Permanece en `false` mientras el AppOpenAd esté pendiente de cargarse/mostrarse
  /// dentro de los primeros 30 segundos, evitando cualquier superposición de anuncios.
  static final ValueNotifier<bool> canShowBanners = ValueNotifier<bool>(false);

  static bool _initialized = false;
  static bool _isShowingFullScreenAd = false;
  static bool _appOpenSessionCompleted = false;
  static bool _appOpenAdShownInSession = false;
  static Timer? _appOpenMaxWaitTimer;
  static Timer? _appOpenRetryTimer;
  static Timer? _secondaryAdsPreloadTimer;

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

    if (!shouldLoadAds) {
      canShowBanners.value = true;
      return;
    }

    await MobileAds.instance.initialize();

    // Habilitar anuncios de prueba en emuladores y dispositivo físico
    final configuration = RequestConfiguration(
      testDeviceIds: <String>['EMULATOR', '92C3D2A309B4B67DE67A5F10A13F1F43'],
    );
    await MobileAds.instance.updateRequestConfiguration(configuration);

    debugPrint(
      'AdService initialized. Mode: ${isProd ? "PRODUCCIÓN" : "TEST / PRUEBA"}',
    );
  }

  /// Inicia el flujo de AppOpenAd desde LoadingScreen dando prioridad absoluta
  /// a la carga y visualización del anuncio de apertura.
  /// - Mientras no se haya mostrado y cerrado el AppOpenAd, `canShowBanners` es `false`.
  /// - Si pasan 30 segundos sin haberse mostrado, se cancela el AppOpenAd y se
  ///   habilitan los banners en toda la app.
  static Future<void> startAppOpenSession() async {
    _appOpenMaxWaitTimer?.cancel();
    _appOpenRetryTimer?.cancel();
    _secondaryAdsPreloadTimer?.cancel();

    if (!shouldLoadAds) {
      _appOpenSessionCompleted = true;
      canShowBanners.value = true;
      return;
    }

    _appOpenSessionCompleted = false;
    _appOpenAdShownInSession = false;
    canShowBanners.value = false;

    await initialize();

    if (appOpenUnitId.isEmpty) {
      _finishAppOpenSessionAndEnableBanners();
      return;
    }

    // Regla de 30 segundos máximos desde que corre la app desde LoadingScreen
    _appOpenMaxWaitTimer = Timer(appOpenMaxWaitDuration, () {
      if (!_appOpenAdShownInSession && !_appOpenSessionCompleted) {
        debugPrint(
          'AdService: 30s alcanzados sin mostrar AppOpenAd. '
          'Se cancela AppOpenAd y se habilitan los banners.',
        );
        _finishAppOpenSessionAndEnableBanners();
      }
    });

    // Dar prioridad de red al AppOpenAd durante el tiempo del LoadingScreen (7s),
    // y tras ese tiempo (o cuando cargue AppOpenAd) precargar Interstitial y Rewarded.
    _secondaryAdsPreloadTimer = Timer(loadingScreenDuration, () {
      _preloadSecondaryAds();
    });

    // Cargar AppOpenAd con prioridad inmediata
    _loadAppOpenAd();
  }

  static void _preloadSecondaryAds() {
    _secondaryAdsPreloadTimer?.cancel();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  static void _finishAppOpenSessionAndEnableBanners() {
    _appOpenMaxWaitTimer?.cancel();
    _appOpenRetryTimer?.cancel();
    _appOpenSessionCompleted = true;

    _appOpenAd?.dispose();
    _appOpenAd = null;

    if (_appOpenLoadCompleter != null &&
        !_appOpenLoadCompleter!.isCompleted) {
      _appOpenLoadCompleter!.complete(null);
    }

    if (!canShowBanners.value) {
      canShowBanners.value = true;
      debugPrint('AdService: Banners habilitados.');
    }

    _preloadSecondaryAds();
  }

  static Future<void> initializeAndLoadAppOpenAd({
    bool showOnLoad = true,
  }) async {
    await startAppOpenSession();
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
    if (_appOpenSessionCompleted || _appOpenAdShownInSession) {
      return;
    }

    final adUnitId = appOpenUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('AppOpenAd unit ID is empty. Skipping load.');
      _finishAppOpenSessionAndEnableBanners();
      return;
    }
    if (_appOpenAd != null) {
      unawaited(showAppOpenAd());
      return;
    }
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
          if (_appOpenSessionCompleted || _appOpenAdShownInSession) {
            ad.dispose();
            if (_appOpenLoadCompleter != null &&
                !_appOpenLoadCompleter!.isCompleted) {
              _appOpenLoadCompleter!.complete(null);
            }
            return;
          }

          _appOpenAd?.dispose();
          _appOpenAd = ad;
          debugPrint('AppOpenAd loaded successfully.');
          if (_appOpenLoadCompleter != null &&
              !_appOpenLoadCompleter!.isCompleted) {
            _appOpenLoadCompleter!.complete(ad);
          }

          // Una vez cargado AppOpenAd, iniciar precarga de anuncios secundarios
          // y mostrar inmediatamente el AppOpenAd (los banners siguen bloqueados).
          _preloadSecondaryAds();
          unawaited(showAppOpenAd());
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load (code ${error.code}): $error');
          _appOpenAd = null;
          if (_appOpenLoadCompleter != null &&
              !_appOpenLoadCompleter!.isCompleted) {
            _appOpenLoadCompleter!.complete(null);
          }

          // Reintentar mientras sigamos dentro de la ventana de 30 segundos
          if (!_appOpenSessionCompleted && !_appOpenAdShownInSession) {
            _appOpenRetryTimer?.cancel();
            _appOpenRetryTimer = Timer(const Duration(seconds: 3), () {
              if (!_appOpenSessionCompleted && !_appOpenAdShownInSession) {
                _loadAppOpenAd();
              }
            });
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
      if (_interstitialLoadCompleter == null ||
          _interstitialLoadCompleter!.isCompleted) {
        _loadInterstitialAd();
      }
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
        _loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
        // Si el AppOpenAd terminó de cargar mientras se veía el intersticial y aún estamos en <30s
        if (_appOpenAd != null &&
            !_appOpenSessionCompleted &&
            !_appOpenAdShownInSession) {
          unawaited(showAppOpenAd());
        }
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
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
      _loadInterstitialAd();
      debugPrint('InterstitialAd show exception: $error');
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _isShowingFullScreenAd = false;
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
      if (_rewardedLoadCompleter == null ||
          _rewardedLoadCompleter!.isCompleted) {
        _loadRewardedAd();
      }
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
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
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
    Duration timeout = loadingScreenDuration,
  }) async {
    if (_appOpenSessionCompleted || _appOpenAdShownInSession) {
      return;
    }

    if (_isShowingFullScreenAd) {
      debugPrint('A full screen ad is already showing. Delaying AppOpenAd.');
      return;
    }

    if (!shouldLoadAds) {
      _finishAppOpenSessionAndEnableBanners();
      return;
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
              debugPrint(
                'AppOpenAd did not finish loading within ${timeout.inSeconds}s; '
                'will continue waiting in background up to 30s before enabling banners.',
              );
              return null;
            },
          );
        } catch (e) {
          debugPrint('Error awaiting AppOpenAd: $e');
        }
      } else {
        _loadAppOpenAd();
        return;
      }
    }

    if (_appOpenSessionCompleted || _appOpenAdShownInSession) {
      return;
    }

    final ad = _appOpenAd;
    if (ad == null) {
      debugPrint('AppOpenAd not ready yet.');
      return;
    }

    if (_isShowingFullScreenAd) return;

    _isShowingFullScreenAd = true;
    _appOpenAdShownInSession = true;
    _appOpenAd = null;
    _appOpenMaxWaitTimer?.cancel();
    _appOpenRetryTimer?.cancel();

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (adInstance) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        _finishAppOpenSessionAndEnableBanners();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        debugPrint('AppOpenAd failed to show: $error');
        _finishAppOpenSessionAndEnableBanners();
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      ad.show();
    } catch (error, stackTrace) {
      ad.dispose();
      _isShowingFullScreenAd = false;
      debugPrint('AppOpenAd show failed: $error');
      debugPrint('$stackTrace');
      _finishAppOpenSessionAndEnableBanners();
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _isShowingFullScreenAd = false;
        _finishAppOpenSessionAndEnableBanners();
        debugPrint('AppOpenAd presentation timed out');
      },
    );
  }
}
